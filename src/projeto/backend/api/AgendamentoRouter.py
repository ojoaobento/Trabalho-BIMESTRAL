from datetime import datetime
 
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
 
from core.database import get_db
from repositories.AgendamentoRepository import AgendamentoRepository
from repositories.ClienteRepository import ClienteRepository
from repositories.DisponibilidadeRepository import DisponibilidadeRepository
from repositories.LembreteRepository import LembreteRepository
from repositories.ServicoRepository import ServicoRepository
from schemas.AgendamentoSchema import (
    AgendamentoAtualizarRequest,
    AgendamentoRequest,
    AgendamentoResponse,
    AgendamentoStatusRequest,
)
from services.AgendamentoService import AgendamentoService
from services.ClienteService import ClienteService
from services.LembreteService import LembreteService

router = APIRouter(prefix="/agendamentos", tags=["Agendamentos"])


def get_service(db: Session = Depends(get_db)) -> AgendamentoService:
    agendamento_repository = AgendamentoRepository(db)
    return AgendamentoService(
        agendamento_repository,
        ClienteService(ClienteRepository(db)),
        ServicoRepository(db),
        DisponibilidadeRepository(db),
        LembreteService(LembreteRepository(db), agendamento_repository),
    )



@router.post("", response_model=AgendamentoResponse, status_code=status.HTTP_201_CREATED)
def criar(dados: AgendamentoRequest, service: AgendamentoService = Depends(get_service)):
    return service.criar(dados)
 
 
@router.get("", response_model=list[AgendamentoResponse])
def listar(
    cliente_id: int | None = None,
    inicio: datetime | None = None,
    fim: datetime | None = None,
    service: AgendamentoService = Depends(get_service),
):
    if cliente_id is not None:
        return service.listar_por_cliente(cliente_id)
    if inicio is not None and fim is not None:
        return service.listar_por_periodo(inicio, fim)
    return service.listar()
 
 
@router.get("/{agendamento_id}", response_model=AgendamentoResponse)
def buscar(agendamento_id: int, service: AgendamentoService = Depends(get_service)):
    return service.buscar_por_id(agendamento_id)
 
 
@router.patch("/{agendamento_id}", response_model=AgendamentoResponse)
def atualizar(
    agendamento_id: int,
    dados: AgendamentoAtualizarRequest,
    service: AgendamentoService = Depends(get_service),
):
    return service.atualizar(agendamento_id, dados)
 
 
@router.patch("/{agendamento_id}/status", response_model=AgendamentoResponse)
def alterar_status(
    agendamento_id: int,
    dados: AgendamentoStatusRequest,
    service: AgendamentoService = Depends(get_service),
):
    return service.alterar_status(agendamento_id, dados.status, usuario_id=None)
 
 
@router.delete("/{agendamento_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(agendamento_id: int, service: AgendamentoService = Depends(get_service)):
    service.deletar(agendamento_id)