from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
 
from core.database import get_db
from core.dependencies import get_usuario_logado
from repositories.AgendamentoRepository import AgendamentoRepository
from repositories.LembreteRepository import LembreteRepository
from schemas.LembreteSchema import (
    LembreteAtualizarRequest,
    LembreteRequest,
    LembreteResponse,
)
from services.LembreteService import LembreteService

router = APIRouter(
    prefix="/lembretes",
    tags=["Lembretes"],
    dependencies=[Depends(get_usuario_logado)],
)


def get_service(db: Session = Depends(get_db)) -> LembreteService:
    return LembreteService(LembreteRepository(db), AgendamentoRepository(db))


@router.get("", response_model=list[LembreteResponse])
def listar(service: LembreteService = Depends(get_service)):
    return service.listar()

@router.get("/pendentes", response_model=list[LembreteResponse])
def listar_pendentes(service: LembreteService = Depends(get_service)):
    return service.listar_pendetes()

@router.get("/{lembrete_id}", response_model=LembreteResponse)
def buscar_por_id(lembrete_id : int, service: LembreteService = Depends(get_service)):
    return service.buscar_por_id(lembrete_id)

@router.post("", response_model=LembreteResponse, status_code=status.HTTP_201_CREATED)
def criar(dados: LembreteRequest, service: LembreteService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{lembrete_id}", response_model=LembreteResponse)
def atualizar(lembrete_id : int, dados: LembreteAtualizarRequest, service: LembreteService = Depends(get_service)):
    return service.atualizar(lembrete_id, dados)

@router.patch("/{lembrete_id}/enviado", response_model=LembreteResponse)
def marcar_como_enviado(lembrete_id: int, service: LembreteService = Depends(get_service)):
    return service.marcar_como_enviado(lembrete_id)

@router.delete("/{lembrete_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(lembrete_id : int, service: LembreteService = Depends(get_service)):
    return service.deletar(lembrete_id)

