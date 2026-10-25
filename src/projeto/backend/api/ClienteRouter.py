from fastapi import APIRouter, Depends, status
from core.dependencies import get_usuario_logado
from sqlalchemy.orm import Session
from core.database import get_db
from schemas.ClienteSchema import (
    ClienteAtualizarRequest,
    ClienteRequest,
    ClienteResponse
)
from repositories.ClienteRepository import ClienteRepository
from services.ClienteService import ClienteService

router = APIRouter(prefix="/clientes", tags=["Clientes"], dependencies=[Depends(get_usuario_logado)])

def get_service(db: Session = Depends(get_db)) -> ClienteService:
    return ClienteService(ClienteRepository(db))

@router.get("", response_model=list[ClienteResponse])
def listar(service: ClienteService = Depends(get_service)):
    return service.listar()


@router.get("/telefone/{telefone}", response_model=ClienteResponse)
def buscar_por_telefone(telefone: str, service: ClienteService = Depends(get_service)):
    return service.buscar_por_telefone(telefone)

@router.get("/{cliente_id}", response_model=ClienteResponse)
def buscar_por_id(cliente_id: int, service: ClienteService = Depends(get_service)):
    return service.buscar_por_id(cliente_id)

@router.post("", response_model=ClienteResponse, status_code=status.HTTP_201_CREATED)
def criar(dados: ClienteRequest, service: ClienteService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{cliente_id}", response_model=ClienteResponse)
def atualizar(cliente_id: int, dados: ClienteAtualizarRequest, service: ClienteService = Depends(get_service)):
    return service.atualizar(cliente_id, dados)

@router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(cliente_id: int, service: ClienteService = Depends(get_service)):
    return service.deletar(cliente_id)