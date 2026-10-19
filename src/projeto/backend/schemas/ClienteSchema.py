from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import Literal

class ClienteRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nome: str = Field(min_length= 2, max_length=100)
    telefone: str = Field(pattern=r"^\d{11}$")
    email: str | None = Field(default=None, min_length=2, max_length=100)
    aceita_lembretes: bool = True
    consentimento: Literal[True]


class ClienteAtualizarRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nome: str = Field(min_length= 2, max_length=100)
    telefone: str = Field(pattern=r"^\d{11}$")
    email: str | None = Field(default=None, min_length=2, max_length=100)

class ClienteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    telefone: str
    email: str | None
    aceita_lembretes: bool
    consentimento_em: datetime | None
    dt_cadastro: datetime

