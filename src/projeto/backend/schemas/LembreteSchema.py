from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from datetime import datetime
import enum

class TipoLembrete(str, enum.Enum):
    CONFIRMACAO = "confirmacao"
    LEMBRETE_24H = "lembrete_24h"


class LembreteRequest(BaseModel):

    agendamento_id: int
    servico_id: Optional[int] = None
    enviar_em: datetime
    tipo: TipoLembrete

class LembreteAtualizarRequest(BaseModel):

    servico_id: Optional[int] = None
    enviar_em: Optional[datetime] = None
    tipo: Optional[TipoLembrete] = None

class LembreteAtualizarCompletoRequest(BaseModel):

    servico_id: int
    enviar_em: datetime
    tipo: TipoLembrete

class LembreteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)


    id: int
    agendamento_id: int
    servico_id: Optional[int] = None
    enviar_em: datetime
    tipo: TipoLembrete
    enviado: bool
    enviado_em: Optional[datetime] = None
