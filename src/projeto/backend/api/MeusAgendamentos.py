"""
backend/api/MeusAgendamentos.py  (v4 - sessão persistente + esqueci o telefone)

  POST  /agendamentos/acesso/codigo -> envia código de 6 dígitos por e-mail
                                       (com telefone, ou só com e-mail se a
                                       cliente esqueceu o telefone)
  POST  /agendamentos/minhas        -> entra com (e-mail + código [+ telefone])
                                       OU com (token de sessão)
                                       Resposta: {"token": "...", "agendamentos": [...]}
  PATCH /agendamentos/minhas/telefone -> troca o telefone da cliente (por token)

O token é assinado (HMAC) e NÃO fica no banco. Vale VALIDADE_SESSAO_DIAS dias e
deixa de valer sozinho se o e-mail ou o telefone da cliente mudarem, ou se
ACESSO_CLIENTE_SECRET for trocado.
"""
import hashlib
import hmac
import os
import re
import secrets
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import Column, DateTime, Integer, String, func
from sqlalchemy.orm import Session

from core.database import Base, get_db

from models.Agendamento import StatusAgendamento
from models.Cliente import Cliente  # ajuste ao caminho real do seu model
from repositories.AgendamentoRepository import AgendamentoRepository
from repositories.ClienteRepository import ClienteRepository
from repositories.DisponibilidadeRepository import DisponibilidadeRepository
from repositories.LembreteRepository import LembreteRepository
from repositories.ServicoRepository import ServicoRepository
from schemas.ClienteSchema import ClienteAtualizarRequest
from services.AgendamentoService import AgendamentoService
from services.ClienteService import ClienteService
from services.LembreteService import LembreteService

# Mantém o que funcionar no seu core/email_codigo.py (função com um dos dois nomes)
try:
    from core.email_codigo import enviar_email_simples as enviar_email
except ImportError:
    from core.email_codigo import enviar_email

FUSO = ZoneInfo("America/Sao_Paulo")
VALIDADE_MINUTOS = 10
INTERVALO_REENVIO_SEGUNDOS = 60
MAX_TENTATIVAS = 5
VALIDADE_SESSAO_DIAS = 30
HORAS_MIN_CANCELAMENTO = int(os.getenv("CANCELAMENTO_ANTECEDENCIA_HORAS", "2"))

SEGREDO = os.getenv("ACESSO_CLIENTE_SECRET")
if not SEGREDO:
    # Sem segredo próprio, qualquer pessoa conseguiria forjar tokens.
    raise RuntimeError("Defina ACESSO_CLIENTE_SECRET no backend/.env")


class CodigoAcesso(Base):
    __tablename__ = "codigos_acesso"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), nullable=False, index=True)
    # Vazio ("") quando o código foi pedido pelo "esqueci meu telefone".
    telefone = Column(String(11), nullable=False)
    codigo_hash = Column(String(64), nullable=False)
    tentativas = Column(Integer, nullable=False, default=0)
    criado_em = Column(DateTime(timezone=True), nullable=False)
    expira_em = Column(DateTime(timezone=True), nullable=False)


class SolicitarCodigoRequest(BaseModel):
    email: EmailStr
    # Opcional: sem telefone = "esqueci meu telefone" (só e-mail + código).
    telefone: str | None = None


class CancelarRequest(BaseModel):
    token: str


class AlterarTelefoneRequest(BaseModel):
    token: str
    telefone: str = Field(pattern=r"^[1-9]{2}9\d{8}$")


class MeusAgendamentosRequest(BaseModel):
    # Informe (email + codigo, com telefone opcional) OU (token)
    email: EmailStr | None = None
    telefone: str | None = None
    codigo: str | None = Field(default=None, min_length=6, max_length=6)
    token: str | None = None


# ---------- auxiliares ----------

def _agora() -> datetime:
    return datetime.now(timezone.utc)


def _com_fuso(dt: datetime) -> datetime:
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _digitos(texto: str) -> str:
    return re.sub(r"\D", "", texto or "")


def _hmac(texto: str) -> str:
    return hmac.new(SEGREDO.encode(), texto.encode(), hashlib.sha256).hexdigest()


def _hash_codigo(email: str, telefone: str, codigo: str) -> str:
    return _hmac(f"codigo:{email}:{telefone}:{codigo}")


def _cliente_por_email(db: Session, email: str):
    """Só vale se houver exatamente uma cliente com esse e-mail; com mais de
    uma não dá para saber de quem é a lista, e ela precisa usar o telefone."""
    achadas = (
        db.query(Cliente)
        .filter(func.lower(func.trim(Cliente.email)) == email)
        .all()
    )
    return achadas[0] if len(achadas) == 1 else None


def _cliente_valido(db: Session, email: str, telefone: str):
    """Com telefone: e-mail e telefone precisam bater.
    Sem telefone ("esqueci meu telefone"): vale só pelo e-mail."""
    if not telefone:
        return _cliente_por_email(db, email)

    cliente = ClienteRepository(db).buscar_por_telefone(telefone)
    if cliente is None or not cliente.email:
        return None
    if cliente.email.strip().lower() != email:
        return None
    return cliente


# ---------- token de sessão ----------

def _impressao(cliente) -> str:
    """Muda se o e-mail ou o telefone mudarem -> token antigo deixa de valer."""
    base = f"{(cliente.email or '').strip().lower()}|{_digitos(cliente.telefone)}"
    return _hmac(f"fp:{base}")[:16]


def _criar_token(cliente) -> str:
    exp = int((_agora() + timedelta(days=VALIDADE_SESSAO_DIAS)).timestamp())
    corpo = f"cliente.{cliente.id}.{exp}.{_impressao(cliente)}"
    return f"{corpo}.{_hmac(corpo)}"


def _cliente_do_token(db: Session, token: str):
    try:
        prefixo, cid, exp, imp, assinatura = token.split(".")
        corpo = f"{prefixo}.{cid}.{exp}.{imp}"
        if prefixo != "cliente" or not hmac.compare_digest(_hmac(corpo), assinatura):
            return None
        if int(exp) < _agora().timestamp():
            return None
        cliente = ClienteRepository(db).buscar_por_id(int(cid))
    except (ValueError, TypeError):
        return None

    if cliente is None or not hmac.compare_digest(_impressao(cliente), imp):
        return None
    return cliente


# ---------- e-mail ----------

def _enviar_codigo(email: str, codigo: str):
    texto = (
        f"Seu código de acesso ao Studio Cleusa é: {codigo}\n\n"
        f"Ele vale por {VALIDADE_MINUTOS} minutos. "
        "Se você não solicitou, ignore esta mensagem."
    )
    html = f"""<div style="font-family:Arial,sans-serif;max-width:420px;margin:0 auto;padding:24px;
        border:1px solid #e8e4e1;border-radius:12px;color:#222">
      <h2 style="color:#8E2348;margin:0 0 12px">Studio Cleusa</h2>
      <p>Use o código abaixo para acessar seus agendamentos:</p>
      <p style="font-size:32px;letter-spacing:8px;font-weight:bold;color:#8E2348;
         text-align:center;margin:20px 0">{codigo}</p>
      <p style="font-size:13px;color:#666">Ele vale por {VALIDADE_MINUTOS} minutos.
      Se você não solicitou, ignore esta mensagem.</p></div>"""
    enviar_email(
        destino=email,
        assunto="Seu código de acesso - Studio Cleusa",
        corpo_texto=texto,
        corpo_html=html,
    )


# ---------- listagem ----------

STATUS_CANCELAVEIS = (StatusAgendamento.PENDENTE, StatusAgendamento.CONFIRMADO)


def _local(dt: datetime) -> str:
    # horário do studio, sem offset: o Flutter exibe exatamente essa hora
    return _com_fuso(dt).astimezone(FUSO).strftime("%Y-%m-%dT%H:%M:%S")


def _antecedencia_ok(agendamento) -> bool:
    faltam = _com_fuso(agendamento.dt_inicio) - _agora()
    return faltam >= timedelta(hours=HORAS_MIN_CANCELAMENTO)


def _item(a) -> dict:
    return {
        "id": a.id,
        "servico": {"nome": a.servico.nome},
        "dt_inicio": _local(a.dt_inicio),
        "dt_fim": _local(a.dt_fim),
        "status": a.status.value.lower(),
        "pode_cancelar": a.status in STATUS_CANCELAVEIS and _antecedencia_ok(a),
    }


def _listar(db: Session, cliente) -> list[dict]:
    agendamentos = AgendamentoRepository(db).listar_por_cliente(cliente.id)
    return [
        _item(a)
        for a in sorted(agendamentos, key=lambda x: x.dt_inicio, reverse=True)
        if a.status != StatusAgendamento.RESERVADO   # reserva temporária: não mostrar
    ]


def _dados_cliente(cliente) -> dict:
    """Dados usados pelo app para pré-preencher um novo agendamento."""
    return {
        "nome": cliente.nome,
        "email": cliente.email,
        "telefone": _digitos(cliente.telefone),
    }


# ---------- rotas ----------

router = APIRouter(prefix="/agendamentos", tags=["Meus agendamentos (cliente)"])


@router.post("/acesso/codigo", status_code=status.HTTP_202_ACCEPTED)
def solicitar_codigo(
    dados: SolicitarCodigoRequest,
    tarefas: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """Resposta sempre igual, exista a cliente ou não."""
    email = dados.email.lower().strip()
    telefone = _digitos(dados.telefone or "")   # "" = esqueci meu telefone
    resposta = {"mensagem": "Se os dados estiverem corretos, enviamos um código por e-mail."}

    if telefone and not re.fullmatch(r"[1-9]{2}9\d{8}", telefone):
        return resposta

    if _cliente_valido(db, email, telefone) is None:
        return resposta

    ultimo = (
        db.query(CodigoAcesso)
        .filter(CodigoAcesso.email == email, CodigoAcesso.telefone == telefone)
        .order_by(CodigoAcesso.criado_em.desc())
        .first()
    )
    if ultimo and (_agora() - _com_fuso(ultimo.criado_em)).total_seconds() < INTERVALO_REENVIO_SEGUNDOS:
        return resposta

    db.query(CodigoAcesso).filter(
        CodigoAcesso.email == email, CodigoAcesso.telefone == telefone
    ).delete()

    codigo = f"{secrets.randbelow(1_000_000):06d}"
    agora = _agora()
    db.add(CodigoAcesso(
        email=email,
        telefone=telefone,
        codigo_hash=_hash_codigo(email, telefone, codigo),
        criado_em=agora,
        expira_em=agora + timedelta(minutes=VALIDADE_MINUTOS),
    ))
    db.commit()

    tarefas.add_task(_enviar_codigo, email, codigo)
    return resposta


@router.post("/minhas")
def meus_agendamentos(dados: MeusAgendamentosRequest, db: Session = Depends(get_db)):
    # --- entrada por token de sessão ---
    if dados.token:
        cliente = _cliente_do_token(db, dados.token)
        if cliente is None:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Sessão expirada. Entre novamente.")
        return {
            "token": dados.token,
            "cliente": _dados_cliente(cliente),
            "agendamentos": _listar(db, cliente),
        }

    # --- entrada por e-mail + código (+ telefone, se ela lembrar) ---
    if not (dados.email and dados.codigo):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Informe e-mail e código.")

    email = dados.email.lower().strip()
    telefone = _digitos(dados.telefone or "")   # "" = esqueci meu telefone
    erro = HTTPException(status.HTTP_403_FORBIDDEN, "Código inválido ou expirado.")

    registro = (
        db.query(CodigoAcesso)
        .filter(CodigoAcesso.email == email, CodigoAcesso.telefone == telefone)
        .order_by(CodigoAcesso.criado_em.desc())
        .first()
    )
    if registro is None or _com_fuso(registro.expira_em) < _agora():
        raise erro

    if registro.tentativas >= MAX_TENTATIVAS:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Muitas tentativas. Solicite um novo código.")

    if not hmac.compare_digest(_hash_codigo(email, telefone, dados.codigo), registro.codigo_hash):
        registro.tentativas += 1
        db.commit()
        raise erro

    cliente = _cliente_valido(db, email, telefone)
    if cliente is None:
        raise erro

    return {
        "token": _criar_token(cliente),
        "cliente": _dados_cliente(cliente),
        "agendamentos": _listar(db, cliente),
    }


def _montar_service(db: Session) -> AgendamentoService:
    """Mesma composição usada pelo router de agendamentos do painel."""
    agendamento_repository = AgendamentoRepository(db)
    servico_repository = ServicoRepository(db)
    return AgendamentoService(
        agendamento_repository,
        ClienteService(ClienteRepository(db)),
        servico_repository,
        DisponibilidadeRepository(db),
        LembreteService(LembreteRepository(db), agendamento_repository, servico_repository),
    )


@router.post("/minhas/{agendamento_id}/cancelar")
def cancelar_meu_agendamento(
    agendamento_id: int,
    dados: CancelarRequest,
    db: Session = Depends(get_db),
):
    """A cliente (identificada pelo token) cancela um horário dela."""
    cliente = _cliente_do_token(db, dados.token)
    if cliente is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Sessão expirada. Entre novamente.")

    service = _montar_service(db)
    agendamento = service.buscar_por_id(agendamento_id)   # 404 se não existir

    # Agendamento de outra pessoa: responde como se não existisse.
    if agendamento.cliente_id != cliente.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Agendamento não encontrado.")

    if agendamento.status not in STATUS_CANCELAVEIS:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Este agendamento não pode mais ser cancelado.",
        )

    if not _antecedencia_ok(agendamento):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"O cancelamento pelo app é possível até {HORAS_MIN_CANCELAMENTO}h antes "
            "do horário. Entre em contato com o studio.",
        )

    # Cancela e apaga os lembretes ainda não enviados (regra já existente).
    atualizado = service.alterar_status(agendamento_id, StatusAgendamento.CANCELADO)
    return _item(atualizado)


@router.patch("/minhas/telefone")
def atualizar_meu_telefone(dados: AlterarTelefoneRequest, db: Session = Depends(get_db)):
    """A cliente (identificada pelo token) troca o telefone cadastrado."""
    cliente = _cliente_do_token(db, dados.token)
    if cliente is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Sessão expirada. Entre novamente.")

    novo = _digitos(dados.telefone)
    if novo == _digitos(cliente.telefone):
        return {"token": dados.token, "telefone": novo}

    repo = ClienteRepository(db)
    existente = repo.buscar_por_telefone(novo)
    if existente is not None and existente.id != cliente.id:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Não foi possível usar este telefone.",
        )

    # reaproveita o PATCH que já existe no service (nome, e-mail etc. ficam intactos)
    ClienteService(repo).atualizar(cliente.id, ClienteAtualizarRequest(telefone=novo))
    db.refresh(cliente)

    # a impressão do token inclui o telefone: gera um token novo
    return {"token": _criar_token(cliente), "telefone": novo}