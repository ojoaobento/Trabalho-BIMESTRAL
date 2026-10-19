from pydantic import BaseModel, ConfigDict, Field, EmailStr
from datetime import datetime
from typing import Optional

class UsuarioRequest(BaseModel):

    nome: str = Field(min_length=2, max_length=100)
    email: str = EmailStr
    senha: str = Field(min_length=2, max_length=265)
    ativo: bool

class UsuarioAtualizarRequest(BaseModel):

    nome: Optional[str] = Field(default=None, min_length=2, max_length=100)
    email: Optional[str] = Field(default=None, min_length=2, max_length=100)
    senha: Optional[str] = Field(default=None, min_length=2, max_length=265)
    ativo: Optional[bool] = None

class UsuarioResponse(BaseModel):

    id: int
    nome: str
    email: str
    ativo: bool
    dt_cadastro: datetime 
