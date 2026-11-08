from datetime import datetime

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from core.dependencies import get_usuario_logado
from core.database import get_db
from repositories.AgendamentoRepository import AgendamentoRepository
from repositories.ClienteRepository import ClienteRepository
from repositories.DisponibilidadeRepository import DisponibilidadeRepository
from repositories.BloqueioHorarioRepository import BloqueioHorarioRepository
from repositories.LembreteRepository import LembreteRepository
from repositories.ServicoRepository import ServicoRepository
from schemas.AgendamentoSchema import (
    AgendamentoAtualizarRequest,
    AgendamentoRequest,
    AgendamentoResponse,
    AgendamentoStatusRequest,
    AgendamentoPublicoResponse,
    HorarioLivreResponse
)
from services.AgendamentoService import AgendamentoService
from services.ClienteService import ClienteService
from services.LembreteService import LembreteService
from models.Usuario import Usuario
from datetime import date, time
from core.feriados import listar_feriados_ano
from api.MeusAgendamentos import cliente_ja_cadastrado, token_de_sessao

router = APIRouter(prefix="/agendamentos", tags=["Agendamentos"])


def get_service(db: Session = Depends(get_db)) -> AgendamentoService:
    agendamento_repository = AgendamentoRepository(db)
    servico_repository = ServicoRepository(db)
    return AgendamentoService(
        agendamento_repository,
        ClienteService(ClienteRepository(db)),
        servico_repository,
        DisponibilidadeRepository(db),
        LembreteService(LembreteRepository(db), agendamento_repository, servico_repository),
        BloqueioHorarioRepository(db),
    )



@router.post("", response_model=AgendamentoPublicoResponse, status_code=status.HTTP_201_CREATED)
def criar(
    dados: AgendamentoRequest,
    db: Session = Depends(get_db),
    service: AgendamentoService = Depends(get_service),
):
    # Tem que vir ANTES de criar: depois, a cliente já existe no banco.
    ja_existia = cliente_ja_cadastrado(db, dados.cliente.email, dados.cliente.telefone)

    agendamento = service.criar(dados)

    # Pydantic v1: use AgendamentoPublicoResponse.from_orm(agendamento).
    # Se service.criar já devolver dict/schema pronto, remova esta linha
    # e só atribua o token_acesso abaixo.
    resposta = AgendamentoPublicoResponse.model_validate(agendamento)

    # Só cliente nova ganha token automático (e-mail não é verificado aqui).
    if not ja_existia:
        cliente = ClienteRepository(db).buscar_por_id(agendamento.cliente_id)
        if cliente is not None:
            resposta.token_acesso = token_de_sessao(cliente)

    return resposta


@router.get("", response_model=list[AgendamentoResponse], dependencies=[Depends(get_usuario_logado)])
def listar(
    cliente_id: int | None = None,
    inicio: datetime | None = None,
    fim: datetime | None = None,
    service: AgendamentoService = Depends(get_service),
):
    if cliente_id is not None:
        return service.listar_por_cliente(cliente_id)
    if inicio is not None and fim is not None:
        return service.listar_por_periodo(inicio, fim)
    return service.listar()

@router.get("/feriados", response_model=dict[str, str])
def feriados(ano: int = date.today().year):
    return listar_feriados_ano(ano)

@router.get("/horarios-livres", response_model=list[HorarioLivreResponse])
def horarios_livres(data: date, service: AgendamentoService = Depends(get_service)):
    return service.horarios_livres(data)

@router.get("/{agendamento_id}", response_model=AgendamentoResponse, dependencies=[Depends(get_usuario_logado)])
def buscar(agendamento_id: int, service: AgendamentoService = Depends(get_service)):
    return service.buscar_por_id(agendamento_id)


@router.patch("/{agendamento_id}", response_model=AgendamentoResponse, dependencies=[Depends(get_usuario_logado)])
def atualizar(
    agendamento_id: int,
    dados: AgendamentoAtualizarRequest,
    service: AgendamentoService = Depends(get_service),
):
    return service.atualizar(agendamento_id, dados)


@router.patch("/{agendamento_id}/status", response_model=AgendamentoResponse, dependencies=[Depends(get_usuario_logado)])
def alterar_status(
    agendamento_id: int,
    dados: AgendamentoStatusRequest,
    service: AgendamentoService = Depends(get_service),
    usuario: Usuario = Depends(get_usuario_logado),
):
    return service.alterar_status(agendamento_id, dados.status, usuario_id=usuario.id)


@router.delete("/{agendamento_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(get_usuario_logado)])
def deletar(agendamento_id: int, service: AgendamentoService = Depends(get_service)):
    service.deletar(agendamento_id)