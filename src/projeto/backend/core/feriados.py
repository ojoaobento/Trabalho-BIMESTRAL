import holidays
from datetime import date

# Instância base com feriados públicos e facultativos para Brasil / Paraná
_FERIADOS_BASE = holidays.Brazil(
    subdiv="PR",
    categories=(holidays.PUBLIC, holidays.OPTIONAL),
)

def eh_feriado(dia: date) -> bool:
    """Retorna True se a data for feriado ou ponto facultativo reconhecido."""
    return dia in _FERIADOS_BASE

def nome_feriado(dia: date) -> str | None:
    """Retorna o nome do feriado ou None."""
    return _FERIADOS_BASE.get(dia)

def listar_feriados_ano(ano: int) -> dict[str, str]:
    """Retorna dicionário {data_iso: nome_feriado} para o ano informado."""
    f = holidays.Brazil(
        subdiv="PR",
        years=ano,
        categories=(holidays.PUBLIC, holidays.OPTIONAL),
    )
    return {d.isoformat(): nome for d, nome in sorted(f.items())}
