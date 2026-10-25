from fastapi import APIRouter, Depends, status

from sqlalchemy.orm import Session
from core.dependencies import get_usuario_logado
from core.database import get_db
from repositories.CategoriaRepository import CategoriaRepository
from services.CategoriaService import CategoriaService
from schemas.CategoriaSchema import (
    CategoriaRequest,
    CategoriaAtualizarRequest,
    CategoriaResponse
)

router = APIRouter(prefix="/categorias", tags=["Categorias"], dependencies=[Depends(get_usuario_logado)])

def get_service(db : Session = Depends(get_db)) -> CategoriaService:
    return CategoriaService(CategoriaRepository(db))

@router.get("", response_model=list[CategoriaResponse])
def listar(service: CategoriaService = Depends(get_service)):
    return service.listar()

@router.get("/{categoria_id}", response_model=CategoriaResponse)
def buscar(categoria_id: int, service: CategoriaService =Depends(get_service)):
    return service.buscar(categoria_id)

@router.post("", response_model=CategoriaResponse, status_code=status.HTTP_201_CREATED)
def criar(dados: CategoriaRequest, service: CategoriaService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{categoria_id}", response_model=CategoriaResponse)
def atualizar(categoria_id: int, dados: CategoriaAtualizarRequest ,service: CategoriaService = Depends(get_service)):
    return service.atualizar(categoria_id, dados)

@router.delete("/{categoria_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(categoria_id: int, service: CategoriaService = Depends(get_service)):
    service.deletar(categoria_id)
