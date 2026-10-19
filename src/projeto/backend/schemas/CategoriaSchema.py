from pydantic import BaseModel, ConfigDict, Field 


class CategoriaRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nome: str = Field(min_length=1, max_length=100)


class CategoriaAtualizarRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nome: str = Field(min_length=1, max_length=100)
    ativo: bool | None = None

class CategoriaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)


    id: int
    nome: str
    ativo: bool