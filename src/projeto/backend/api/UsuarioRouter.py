from fastapi import APIRouter, Depends, status
from core.database import get_db
from services.UsuarioService import UsuarioService
from sqlalchemy.orm import Session
from repositories.UsuarioRepository import UsuarioRepository
from schemas.UsuarioSchema import (
    UsuarioAtualizarRequest,
    UsuarioRequest,
    UsuarioResponse
)

router = APIRouter(prefix="/usuarios", tags=["Usuários"])

def get_service(db: Session = Depends(get_db)):
    return UsuarioService(UsuarioRepository(db))

@router.get("", response_model=list[UsuarioResponse])
def listar(service: UsuarioService = Depends(get_service)):
    return service.listar()

@router.get("/{usuario.id}", response_model=UsuarioResponse)
def buscar_por_id(usuario_id: int, service: UsuarioService = Depends(get_service)):
    return service.buscar_por_id(usuario_id)

@router.get("/{usuario.email}", response_model=UsuarioResponse)
def buscar_por_email(email: str, service: UsuarioService = Depends(get_service)):
    return service.buscar_por_email(email)

@router.post("", response_model=UsuarioRequest, status_code=status.HTTP_201_CREATED)
def criar(dados: UsuarioRequest, service: UsuarioService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{usuario.id}", response_model=UsuarioAtualizarRequest)
def atualizar(usuario_id: int, dados: UsuarioAtualizarRequest, service: UsuarioService = Depends(get_service)):
    return service.atualizar(usuario_id, dados)

@router.delete("/{usuario.id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(usuario_id: int, service: UsuarioService = Depends(get_service)):
    return service.deletar(usuario_id)