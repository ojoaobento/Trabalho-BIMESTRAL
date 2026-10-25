from fastapi import APIRouter, Depends, status, HTTPException
from core.database import get_db
from core.dependencies import get_usuario_logado
from services.ServicoService import ServicoService
from sqlalchemy.orm import Session
from core.dependencies import get_usuario_logado
from repositories.ServicoRepository import ServicoRepository
from repositories.CategoriaRepository import CategoriaRepository
from schemas.ServicoSchema import (
    ServicoAtualizarRequest,
    ServicoRequest,
    ServicoResponse
)


router = APIRouter(prefix= "/servicos", tags=["Serviços"], dependencies=[Depends(get_usuario_logado)])


def get_service(db: Session = Depends(get_db)) -> ServicoService:
    return ServicoService(ServicoRepository(db), CategoriaRepository(db))


@router.get("", response_model=list[ServicoResponse])
def listar(service: ServicoService = Depends(get_service)):
    return service.listar()

@router.get("/ativos", response_model=list[ServicoResponse])
def listar_ativos(service: ServicoService = Depends(get_service)):
    return service.listar_ativos()

@router.get("/categoria", response_model=list[ServicoResponse])
def listar_por_categoria(categoria_id: int, service: ServicoService = Depends(get_service)):
    return service.listar_por_categoria(categoria_id)

@router.get("/{servico_id}", response_model=ServicoResponse)
def buscar_por_id(servico_id: int, service: ServicoService = Depends(get_service)):
    return service.buscar_por_id(servico_id)

@router.get("/nome/{servico_nome}", response_model=ServicoResponse)
def buscar_por_nome(servico_nome: str, service : ServicoService = Depends(get_service)):
    return service.buscar_por_nome(servico_nome)

@router.post("", response_model=ServicoResponse, status_code=status.HTTP_201_CREATED)
def criar(dados: ServicoRequest, service: ServicoService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{servico_id}", response_model=ServicoResponse)
def atualizar(servico_id: int, dados: ServicoAtualizarRequest, service: ServicoService = Depends(get_service)):
    return service.atualizar(servico_id, dados)

@router.delete("/{servico_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(servico_id: int, service: ServicoService = Depends(get_service)):
    return service.deletar(servico_id)



