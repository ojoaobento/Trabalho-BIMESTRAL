from pydantic import BaseModel, ConfigDict, Field
from datetime import time
from typing import Optional

class DisponibilidadeRequest(BaseModel):

    dia_semana: int = Field(ge=0, le=6, description="0=Segunda-Feira, 6-Domingo")
    hora_inicio: time 
    hora_fim: time 
    ativo: bool = Field(default=True)

class DisponibilidadeAtualizarRequest(BaseModel):

    dia_semana: Optional[int] = Field(ge=0, le=6, description="0=Segunda-Feira, 6-Domingo")
    hora_inicio: Optional[time] 
    hora_fim: Optional[time] 
    ativo: Optional[bool] = Field(default=True)

class DisponibilidadeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    dia_semana: int
    hora_inicio: time 
    hora_fim: time 
    ativo: bool