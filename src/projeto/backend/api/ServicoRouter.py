from fastapi import APIRouter, Depends, status, Body
from core.database import get_db
from core.dependencies import get_usuario_logado
from services.ServicoService import ServicoService
from sqlalchemy.orm import Session
from repositories.ServicoRepository import ServicoRepository
from repositories.CategoriaRepository import CategoriaRepository
from schemas.ServicoSchema import (
    ServicoAtualizarRequest,
    ServicoRequest,
    ServicoResponse,
    ServicoAtualizarCompletoRequest
)


router = APIRouter(prefix= "/servicos", tags=["Serviços"])


def get_service(db: Session = Depends(get_db)) -> ServicoService:
    return ServicoService(ServicoRepository(db), CategoriaRepository(db))


@router.get("", response_model=list[ServicoResponse],
            dependencies=[Depends(get_usuario_logado)])
def listar(service: ServicoService = Depends(get_service)):
    return service.listar()

@router.get("/ativos", response_model=list[ServicoResponse])
def listar_ativos(service: ServicoService = Depends(get_service)):
    return service.listar_ativos()

@router.get("/categoria", response_model=list[ServicoResponse])
def listar_por_categoria(categoria_id: int, service: ServicoService = Depends(get_service)):
    return service.listar_por_categoria(categoria_id)

@router.get("/nome/{servico_nome}", response_model=ServicoResponse)
def buscar_por_nome(servico_nome: str, service : ServicoService = Depends(get_service)):
    return service.buscar_por_nome(servico_nome)

@router.get("/{servico_id}", response_model=ServicoResponse)
def buscar_por_id(servico_id: int, service: ServicoService = Depends(get_service)):
    return service.buscar_por_id(servico_id)


@router.post("", response_model=ServicoResponse, status_code=status.HTTP_201_CREATED,
             dependencies=[Depends(get_usuario_logado)])
def criar(dados: ServicoRequest, service: ServicoService = Depends(get_service)):
    return service.criar(dados)

@router.patch("/{servico_id}", response_model=ServicoResponse,
              dependencies=[Depends(get_usuario_logado)])
def atualizar(servico_id: int, dados: ServicoAtualizarRequest = Body(
    openapi_examples={
        "so_categoria":{
            "summary": "Atualizar Categoria",
            "value": {"categoria": 2}
        },
        "so_nome":{
            "summary": "Atualizar Nome",
            "value": {"nome": "Alisamento de cabelo"}
        },
        "so_descricao":{
            "summary": "Atualizar Descrição",
            "value": {"descricao": "Propõe novos fios capilares"}
        },
        "so_preco":{
            "summary": "Atualizar Preço",
            "value": {"preco": 20.00}
        },
        "so_duracao":{
            "summary": "Atualizar duração",
            "value":{"duracao_minutos": 40}
        },
        "so_ativo":{
            "summary":"Ativar/desativar",
            "value":{"ativo": False}
        }
    }
), service: ServicoService = Depends(get_service)):
    return service.atualizar(servico_id, dados)


@router.put("/{servico_id}", response_model=ServicoResponse, dependencies=[Depends(get_usuario_logado)])
def atualizar_completo(servico_id: int, dados: ServicoAtualizarCompletoRequest, service: ServicoService = Depends(get_service)):
    return service.atualizar_completo(servico_id, dados)

@router.delete("/{servico_id}", status_code=status.HTTP_204_NO_CONTENT,
               dependencies=[Depends(get_usuario_logado)])
def deletar(servico_id: int, service: ServicoService = Depends(get_service)):
    return service.deletar(servico_id)
