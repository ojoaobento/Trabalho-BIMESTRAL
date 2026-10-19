from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from datetime import datetime
import enum

class TipoLembrete(str, enum.Enum):
    CONFIRMACAO = "confirmacao"
    LEMBRETE_24H = "lembrete_24h"


class LembreteRequest(BaseModel):

    agendamento_id: int
    enviar_em: datetime
    tipo: TipoLembrete
    enviado: bool = False
    enviado_em: Optional[datetime] = None

class LembreteAtualizarRequest(BaseModel):

    enviar_em: Optional[datetime] = None
    tipo: Optional[TipoLembrete] = None

class LembreteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)


    id: int
    agendamento_id: int
    enviar_em: datetime
    tipo: TipoLembrete
    enviado: bool
    enviado_em: Optional[datetime] = None

