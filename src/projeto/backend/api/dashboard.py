from datetime import datetime, time, timedelta
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from core.database import get_db
from core.dependencies import get_usuario_logado

from models.Agendamento import Agendamento
from models.Cliente import Cliente
from models.Servico import Servico


router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"],
    dependencies=[Depends(get_usuario_logado)]
)

FUSO_HORARIO = ZoneInfo("America/Sao_Paulo")


# --------------------------------------------------
# FUNÇÕES AUXILIARES
# --------------------------------------------------

def obter_status(agendamento):
    """
    Retorna o status como string, compatível
    com Enum ou String.
    """
    status = agendamento.status

    valor = status.value if hasattr(status, "value") else status

    return str(valor).upper().split(".")[-1]


def obter_data_local(data):
    """
    Converte a data para o horário de São Paulo.

    Se a data não possuir fuso, considera que
    ela já está no horário local.
    """
    if data.tzinfo is None:
        return data.replace(tzinfo=FUSO_HORARIO)

    return data.astimezone(FUSO_HORARIO)


def ajustar_data_para_banco(data):
    """
    Adapta os limites de consulta ao tipo da coluna dt_inicio.

    timezone=True: mantém o fuso horário.
    timezone=False: utiliza horário local sem tzinfo.
    """
    coluna = Agendamento.__table__.c.dt_inicio
    possui_fuso = getattr(coluna.type, "timezone", False)

    if possui_fuso:
        return data

    return data.replace(tzinfo=None)


def contar_status(agendamentos, status):
    return sum(
        1
        for agendamento in agendamentos
        if obter_status(agendamento) == status
    )


# --------------------------------------------------
# DASHBOARD
# --------------------------------------------------

@router.get("/resumo")
def obter_resumo_dashboard(
    db: Session = Depends(get_db)
):

    agora = datetime.now(FUSO_HORARIO)
    hoje = agora.date()

    # --------------------------------------------------
    # 1. DEFINIÇÃO DOS PERÍODOS
    # --------------------------------------------------

    inicio_hoje = datetime.combine(
        hoje,
        time.min,
        tzinfo=FUSO_HORARIO
    )

    fim_hoje = inicio_hoje + timedelta(days=1)

    inicio_mes = datetime(
        hoje.year,
        hoje.month,
        1,
        tzinfo=FUSO_HORARIO
    )

    if hoje.month == 12:
        inicio_proximo_mes = datetime(
            hoje.year + 1,
            1,
            1,
            tzinfo=FUSO_HORARIO
        )
    else:
        inicio_proximo_mes = datetime(
            hoje.year,
            hoje.month + 1,
            1,
            tzinfo=FUSO_HORARIO
        )

    inicio_semana = datetime.combine(
        hoje - timedelta(days=hoje.weekday()),
        time.min,
        tzinfo=FUSO_HORARIO
    )

    fim_semana = inicio_semana + timedelta(days=7)

    # Ajusta os limites de acordo com o tipo da coluna
    inicio_hoje_db = ajustar_data_para_banco(inicio_hoje)
    fim_hoje_db = ajustar_data_para_banco(fim_hoje)

    inicio_mes_db = ajustar_data_para_banco(inicio_mes)
    inicio_proximo_mes_db = ajustar_data_para_banco(
        inicio_proximo_mes
    )

    inicio_semana_db = ajustar_data_para_banco(inicio_semana)
    fim_semana_db = ajustar_data_para_banco(fim_semana)

    # --------------------------------------------------
    # 2. AGENDAMENTOS DO MÊS
    # --------------------------------------------------

    agendamentos_mes = (
        db.query(Agendamento)
        .filter(
            Agendamento.dt_inicio >= inicio_mes_db,
            Agendamento.dt_inicio < inicio_proximo_mes_db
        )
        .all()
    )

    # --------------------------------------------------
    # 3. AGENDAMENTOS DA SEMANA
    # --------------------------------------------------

    agendamentos_semana = (
        db.query(Agendamento)
        .filter(
            Agendamento.dt_inicio >= inicio_semana_db,
            Agendamento.dt_inicio < fim_semana_db
        )
        .all()
    )

    # --------------------------------------------------
    # 4. AGENDAMENTOS DE HOJE
    # --------------------------------------------------

    agendamentos_hoje = (
        db.query(Agendamento)
        .filter(
            Agendamento.dt_inicio >= inicio_hoje_db,
            Agendamento.dt_inicio < fim_hoje_db
        )
        .all()
    )

    total_agendamentos_hoje = sum(
        1
        for agendamento in agendamentos_hoje
        if obter_status(agendamento) != "CANCELADO"
    )

    # --------------------------------------------------
    # 5. INDICADORES DO MÊS
    # --------------------------------------------------

    agendamentos_pendentes = contar_status(
        agendamentos_mes,
        "PENDENTE"
    )

    agendamentos_confirmados = contar_status(
        agendamentos_mes,
        "CONFIRMADO"
    )

    agendamentos_concluidos = contar_status(
        agendamentos_mes,
        "CONCLUIDO"
    )

    agendamentos_cancelados = contar_status(
        agendamentos_mes,
        "CANCELADO"
    )

    agendamentos_faltas = contar_status(
        agendamentos_mes,
        "FALTOU"
    )

    # --------------------------------------------------
    # 6. TOTAL DE CLIENTES
    # --------------------------------------------------

    total_clientes = (
        db.query(func.count(Cliente.id))
        .scalar() or 0
    )

    # --------------------------------------------------
    # 7. TOTAL DE SERVIÇOS ATIVOS
    # --------------------------------------------------

    total_servicos_ativos = (
        db.query(func.count(Servico.id))
        .filter(Servico.ativo.is_(True))
        .scalar() or 0
    )

    # --------------------------------------------------
    # 8. DESEMPENHO SEMANAL
    # --------------------------------------------------

    # Índices:
    # 0 = Segunda
    # 1 = Terça
    # 2 = Quarta
    # 3 = Quinta
    # 4 = Sexta
    # 5 = Sábado
    # 6 = Domingo

    desempenho_semanal = [0] * 7

    for agendamento in agendamentos_semana:

        if obter_status(agendamento) == "CANCELADO":
            continue

        data_agendamento = obter_data_local(
            agendamento.dt_inicio
        )

        indice_dia = data_agendamento.weekday()

        desempenho_semanal[indice_dia] += 1

    # --------------------------------------------------
    # 9. DISTRIBUIÇÃO POR STATUS
    # --------------------------------------------------

    distribuicao_status = {
        "pendente": agendamentos_pendentes,
        "confirmado": agendamentos_confirmados,
        "concluido": agendamentos_concluidos,
        "cancelado": agendamentos_cancelados,
        "faltou": agendamentos_faltas
    }

    # --------------------------------------------------
    # 10. RESPOSTA
    # --------------------------------------------------

    return {
        "agendamentos_hoje": total_agendamentos_hoje,

        "desempenho_semanal": desempenho_semanal,

        "total_clientes": total_clientes,

        "total_servicos_ativos": total_servicos_ativos,

        "agendamentos_pendentes": agendamentos_pendentes,

        "agendamentos_confirmados": agendamentos_confirmados,

        "agendamentos_concluidos": agendamentos_concluidos,

        "agendamentos_cancelados": agendamentos_cancelados,

        "agendamentos_faltas": agendamentos_faltas,

        "distribuicao_status": distribuicao_status
    }