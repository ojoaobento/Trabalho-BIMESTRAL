from pydantic import BaseModel, ConfigDict, Field
from datetime import time
from typing import Optional

class DisponibilidadeRequest(BaseModel):
    dia_semana: int = Field(ge=0, le=6, description="0=Segunda-Feira, 6=Domingo")
    hora_inicio: time = Field(examples=["08:00:00"], description="Formato: HH:MM:SS")
    hora_fim: time = Field(examples=["18:00:00"], description="Formato: HH:MM:SS")
    ativo: bool = Field(default=True)

class DisponibilidadeAtualizarRequest(BaseModel):
    dia_semana: Optional[int] = Field(default=None, ge=0, le=6)
    hora_inicio: Optional[time] = None
    hora_fim: Optional[time] = None
    ativo: Optional[bool] = None


class DisponibilidadeAtualizarCompletoRequest(BaseModel):
    dia_semana: int = Field(ge=0, le=6)
    hora_inicio: time
    hora_fim: time 
    ativo: bool 

class DisponibilidadeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    dia_semana: int
    hora_inicio: time 
    hora_fim: time 
    ativo: bool