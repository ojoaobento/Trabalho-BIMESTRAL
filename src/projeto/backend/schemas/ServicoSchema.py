from pydantic import BaseModel, ConfigDict, Field
from decimal import Decimal
from typing import Optional

class ServicoRequest(BaseModel):

    categoria_id: int
    nome: str = Field(min_length=2, max_length=100)
    descricao: str = Field(min_length=2, max_length=100)
    preco: Decimal = Field(gt=0)
    duracao_minutos: int 
    ativo: bool = True 

class ServicoAtualizarRequest(BaseModel):
    categoria_id: Optional[int] = None
    nome: Optional[str] = Field(default=None, min_length=2, max_length=100)
    descricao: Optional[str] = Field(default=None, min_length=2, max_length=100)
    preco: Optional[Decimal] = Field(default=None, gt=0)
    duracao_minutos: Optional[int] = None
    ativo: Optional[bool] = None

class ServicoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    categoria_id: int 
    nome: str 
    descricao: str | None 
    preco: Decimal 
    duracao_minutos: int 
    ativo: bool 
