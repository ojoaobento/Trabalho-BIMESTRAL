from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime, date, time

class BloqueioHorarioRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    data: date = Field(examples=["2026-11-09"], description="Data do bloqueio (AAAA-MM-DD)")
    hora_inicio: time = Field(examples=["14:00"], description="Início (HH:MM)")
    hora_fim: time = Field(examples=["15:00"], description="Fim (HH:MM)")
    motivo: str | None = Field(default="Bloqueio administrativo", max_length=255)

class BloqueioHorarioResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    dt_inicio: datetime
    dt_fim: datetime
    motivo: str | None
    criado_por: int | None
    criado_em: datetime

