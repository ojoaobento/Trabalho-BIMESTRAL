from fastapi import APIRouter, Depends, status, HTTPException
from core.database import get_db
from services.UsuarioService import UsuarioService
from sqlalchemy.orm import Session
from core.dependencies import get_usuario_logado
from repositories.UsuarioRepository import UsuarioRepository
from schemas.UsuarioSchema import (
    UsuarioAtualizarRequest,
    UsuarioRequest,
    UsuarioResponse
)
from models.Usuario import Usuario

router = APIRouter(
    prefix="/usuarios",
    tags=["Usuários"],
    dependencies=[Depends(get_usuario_logado)],
)


def get_service(db: Session = Depends(get_db)) -> UsuarioService:
    return UsuarioService(UsuarioRepository(db))

@router.get("", response_model=list[UsuarioResponse])
def listar(service: UsuarioService = Depends(get_service)):
    return service.listar()

@router.get("/{usuario_id}", response_model=UsuarioResponse)
def buscar_por_id(usuario_id: int, service: UsuarioService = Depends(get_service)):
    return service.buscar_por_id(usuario_id)

@router.get("/{usuario_email}", response_model=UsuarioResponse)
def buscar_por_email(email: str, service: UsuarioService = Depends(get_service)):
    return service.buscar_por_email(email)

@router.post("", response_model=UsuarioRequest, status_code=status.HTTP_201_CREATED)
def criar(dados: UsuarioRequest, service: UsuarioService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{usuario_id}", response_model=UsuarioResponse)
def atualizar(usuario_id: int, dados: UsuarioAtualizarRequest, service: UsuarioService = Depends(get_service)):
    return service.atualizar(usuario_id, dados)

@router.delete("/{usuario_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(
    usuario_id: int,
    service: UsuarioService = Depends(get_service),
    logado: Usuario = Depends(get_usuario_logado),
):
    if usuario_id == logado.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Você não pode excluir o seu próprio usuário.",
        )
    service.deletar(usuario_id)