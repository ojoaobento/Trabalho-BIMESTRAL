from pydantic import BaseModel, ConfigDict, Field, EmailStr
from datetime import datetime
from typing import Literal, Optional

class ClienteRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nome: str = Field(min_length= 2, max_length=100)
    telefone: str = Field(pattern=r"^\d{11}$")
    email: EmailStr
    aceita_lembretes: bool = True
    consentimento: Literal[True]


class ClienteAtualizarRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nome: Optional[str] = Field(default=None, min_length=2, max_length=100)
    telefone: Optional[str] = Field(default=None, pattern=r"^\d{11}$")
    email: Optional[EmailStr] = None
    aceita_lembretes: Optional[bool] = None

class ClienteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    telefone: str
    email: str | None
    aceita_lembretes: bool
    consentimento_em: datetime | None
    dt_cadastro: datetime

