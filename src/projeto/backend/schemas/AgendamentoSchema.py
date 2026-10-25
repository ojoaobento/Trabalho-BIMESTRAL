from datetime import datetime
from decimal import Decimal
from typing import Annotated
 
from pydantic import AfterValidator, BaseModel, ConfigDict, Field
 
from models.Agendamento import StatusAgendamento
from schemas.ClienteSchema import ClienteRequest, ClienteResponse
from schemas.ServicoSchema import ServicoResponse


def _exigir_fuso(valor: datetime) -> datetime:
    if valor.tzinfo is None:
        raise ValueError(
            "O horário deve incluir o fuso, por exemplo 2026-10-16T14:30:00-03:00."
        )
    return valor
 
 
DataHoraComFuso = Annotated[datetime, AfterValidator(_exigir_fuso)]


class AgendamentoRequest(BaseModel):

    model_config = ConfigDict(str_strip_whitespace=True)
 
    cliente: ClienteRequest
    servico_id: int
    dt_inicio: DataHoraComFuso
    observacoes: str | None = Field(default=None, max_length=500)
class AgendamentoAtualizarRequest(BaseModel):

    model_config = ConfigDict(str_strip_whitespace=True)
 
    dt_inicio: DataHoraComFuso | None = None
    observacoes: str | None = Field(default=None, max_length=500)

class AgendamentoStatusRequest(BaseModel):
    status: StatusAgendamento

class AgendamentoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
 
    id: int
    dt_inicio: datetime
    dt_fim: datetime
    status: StatusAgendamento
    valor_cobrado: Decimal
    observacoes: str | None
    reserva_expira_em: datetime | None
    dt_cadastro: datetime
    cliente: ClienteResponse
    servico: ServicoResponse