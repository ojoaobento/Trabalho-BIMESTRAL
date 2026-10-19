from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from datetime import datetime
from decimal import Decimal

class StatusAgendamento(str, enum.Enum):
    RESERVADO = "reservado"
    PENDENTE = "pendente"
    CONFIRMADO = "confirmado"
    CANCELADO = "cancelado"
    CONCLUIDO = "concluido"
    FALTOU = "faltou"

class AgendamentoRequest(BaseModel):

    cliente_id: int
    servico_id: int
    confirmado_por: Optional[int] = None
    dt_inicio: datetime
    dt_fim: datetime
    reserva_expira_em: Optional[datetime] = None
    status: StatusAgendamento = StatusAgendamento.PENDENTE
    valor_cobrado: Decimal = Field(gt=0)

class AgendamentoAtualizarRequest(BaseModel):

    cliente_id: Optional[int] = None
    servico_id: Optional[int] = None
    confirmado_por: Optional[int] = None
    dt_inicio: Optional[datetime] = None
    dt_fim: Optional[datetime] = None
    reserva_expira_em: Optional[datetime] = None
    status: Optional[StatusAgendamento] = None
    valor_cobrado: Optional[Decimal] = Field(default=None, gt=0)

class AgendamentoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id:int
    cliente_id: int
    servico_id: int
    confirmado_por: int
    dt_inicio: datetime
    dt_fim: datetime
    reserva_expira_em: datetime | None
    status: StatusAgendamento
    valor_cobrado: Decimal
    dt_cadastro: datetime
