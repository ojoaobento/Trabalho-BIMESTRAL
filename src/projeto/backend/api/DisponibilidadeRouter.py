from fastapi import APIRouter, Depends, status, Query, Body
from sqlalchemy.orm import Session
 
from core.database import get_db
from core.dependencies import get_usuario_logado
from repositories.DisponibilidadeRepository import DisponibilidadeRepository
from schemas.DisponibilidadeSchema import (
    DisponibilidadeAtualizarRequest,
    DisponibilidadeRequest,
    DisponibilidadeResponse,
    DisponibilidadeAtualizarCompletoRequest
)
from services.DisponibilidadeService import DisponibilidadeService

router = APIRouter(prefix="/disponibilidades", tags=["Disponibilidades"], dependencies=[Depends(get_usuario_logado)])

def get_service(db: Session = Depends(get_db)) -> DisponibilidadeService:
    return DisponibilidadeService(DisponibilidadeRepository(db))

@router.get("", response_model=list[DisponibilidadeResponse])
def listar(service: DisponibilidadeService = Depends(get_service)):
    return service.listar()
 
@router.get("/dia_semana", response_model=list[DisponibilidadeResponse])
def listar_por_dia_semana(
    dia_semana: int = Query(ge=0, le=6, description="0 = segunda ... 6 = domingo"),
    service: DisponibilidadeService = Depends(get_service),
):
    return service.listar_por_dia_semana(dia_semana)

@router.get("/{disponibilidade_id}", response_model=DisponibilidadeResponse)
def buscar_por_id(disponibilidade_id: int, service: DisponibilidadeService = Depends(get_service)):
    return service.buscar_por_id(disponibilidade_id)

@router.post("", response_model=DisponibilidadeResponse, status_code=status.HTTP_201_CREATED)
def criar(dados: DisponibilidadeRequest, service: DisponibilidadeService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{disponibilidade_id}", response_model=DisponibilidadeResponse)
def atualizar(
    disponibilidade_id: int,
    dados: DisponibilidadeAtualizarRequest = Body(
        openapi_examples={
            "so_dia": {
                "summary": "Alterar Dia da Semana",
                "value": {"dia_semana": 3},
            },
            "so_horario": {
                "summary": "Alterar Horários",
                "value": {"hora_inicio": "09:00:00", "hora_fim": "17:00:00"},
            },
            "so_ativo": {
                "summary": "Alterar Status",
                "value": {"ativo": False},
            },
        }
    ),
    service: DisponibilidadeService = Depends(get_service),
):
    return service.atualizar(disponibilidade_id, dados)

@router.put("/{disponibilidade_id}", response_model=DisponibilidadeResponse)
def atualizar_completo(disponibilidade_id: int, dados: DisponibilidadeAtualizarCompletoRequest, service: DisponibilidadeService = Depends(get_service)):
    return service.atualizar_completo(disponibilidade_id, dados)

@router.delete("/{disponibilidade_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(disponibilidade_id: int, service: DisponibilidadeService = Depends(get_service)):
    return service.deletar(disponibilidade_id)

