from fastapi import APIRouter, Depends, status, Body

from sqlalchemy.orm import Session
from core.dependencies import get_usuario_logado
from core.database import get_db
from repositories.CategoriaRepository import CategoriaRepository
from services.CategoriaService import CategoriaService
from schemas.CategoriaSchema import (
    CategoriaRequest,
    CategoriaAtualizarRequest,
    CategoriaResponse,
    CategoriaAtualizarCompletoRequest
)

router = APIRouter(prefix="/categorias", tags=["Categorias"])

def get_service(db : Session = Depends(get_db)) -> CategoriaService:
    return CategoriaService(CategoriaRepository(db))

@router.get("", response_model=list[CategoriaResponse])
def listar(service: CategoriaService = Depends(get_service)):
    return service.listar()

@router.get("/{categoria_id}", response_model=CategoriaResponse)
def buscar(categoria_id: int, service: CategoriaService =Depends(get_service)):
    return service.buscar(categoria_id)

@router.post("", response_model=CategoriaResponse, status_code=status.HTTP_201_CREATED,
             dependencies=[Depends(get_usuario_logado)])
def criar(dados: CategoriaRequest, service: CategoriaService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{categoria_id}", response_model=CategoriaResponse,
              dependencies=[Depends(get_usuario_logado)])
def atualizar(categoria_id: int, dados: CategoriaAtualizarRequest = Body(
    openapi_examples={
        "so_nome":{
            "summary":"Atualizar Nome",
            "value":{"nome": "Cabelo"}
        },
        "so_status":{
            "summary":"Atualizar Status",
            "value":{"status": False}
        }
    }
),service: CategoriaService = Depends(get_service)):
    return service.atualizar(categoria_id, dados)

@router.put("/{categoria_id}", response_model=CategoriaResponse, dependencies=[Depends(get_usuario_logado)])
def atualizar_completo(categoria_id: int, dados: CategoriaAtualizarCompletoRequest, service: CategoriaService = Depends(get_service)):
    return service.atualizar_completo(categoria_id, dados)

@router.delete("/{categoria_id}", status_code=status.HTTP_204_NO_CONTENT,
               dependencies=[Depends(get_usuario_logado)])
def deletar(categoria_id: int, service: CategoriaService = Depends(get_service)):
    service.deletar(categoria_id)
