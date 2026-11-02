from datetime import datetime, date, time
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field
 
from models.Agendamento import StatusAgendamento
from schemas.ClienteSchema import ClienteRequest, ClienteResponse
from schemas.ServicoSchema import ServicoResponse


class AgendamentoRequest(BaseModel):

    model_config = ConfigDict(str_strip_whitespace=True)
 
    cliente: ClienteRequest
    servico_id: int
    data: date = Field(examples=["2026-11-09"], description="Formato: AAAA-MM-DD")
    hora: time = Field(examples=["09:00"], description="Formato: HH:MM")
    observacoes: str | None = Field(default=None, max_length=500)

class AgendamentoAtualizarRequest(BaseModel):

    model_config = ConfigDict(str_strip_whitespace=True)
 
    data: date | None = None
    hora: time | None = None
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

class AgendamentoPublicoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    dt_inicio: datetime
    dt_fim: datetime
    status: StatusAgendamento
    servico: ServicoResponse