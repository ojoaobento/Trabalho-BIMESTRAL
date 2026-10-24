from fastapi import HTTPException, status 
from models.Servico import Servico
from schemas.ServicoSchema import (
    ServicoAtualizarRequest,
    ServicoRequest
)
from models.Categoria import Categoria
from repositories.CategoriaRepository import CategoriaRepository
from repositories.ServicoRepository import ServicoRepository
from sqlalchemy.exc import IntegrityError

class ServicoService:
    def __init__(self, repository: ServicoRepository, categoria_repository: CategoriaRepository):
        self.repository = repository
        self.categoria_repository = categoria_repository


    def _categoria_existente(self, categoria_id: int) -> Categoria:
        categoria = self.categoria_repository.buscar_por_id(categoria_id)
        if categoria is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Categoria {categoria_id} não foi encontrada.",
            )
        return categoria
 
    def _categoria_ativa(self, categoria_id: int) -> Categoria:
        categoria = self._categoria_existente(categoria_id)
        if not categoria.ativo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"A categoria '{categoria.nome}' está desativada.",
            )
        return categoria


    def listar(self):
        return self.repository.listar()

    def listar_ativos(self):
        return self.repository.listar_ativos()

    def listar_por_categoria(self, categoria_id: int):
        self._categoria_existente(categoria_id)  
        return self.repository.listar_por_categoria(categoria_id)  
 

    def buscar_por_id(self, servico_id: int) -> Servico:
        servico = self.repository.buscar_por_id(servico_id)

        if servico is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Servico {servico_id} não foi encontrado")
            )

        return servico 

    def buscar_por_nome(self, nome:str) -> Servico:
        servico = self.repository.buscar_por_nome(nome)

        if servico is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Servico {nome} não foi encontrado")
            )

        return servico

    def criar(self, dados: ServicoRequest) -> Servico:

        if self.repository.buscar_por_nome(dados.nome):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(f"Já existe um servico com este nome.")
            )

        servico = Servico(**dados.model_dump())

        return self.repository.salvar(servico)

    def atualizar(self, servico_id: int, dados: ServicoAtualizarRequest) -> Servico:
        servico = self.repository.buscar_por_id(servico_id)

        campos = dados.model_dump(exclude_unset=True)

        for campo in ["categoria_id", "nome", "preco", "duracao_minutos", "ativo"]:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(f"O campo {campo} não pode ser nulo")
                )

        nova_categoria = campos.get("categoria_id")
        if nova_categoria is not None and nova_categoria != servico.categoria_id:
            self._categoria_ativa(nova_categoria)
 
        novo_nome = campos.get("nome")
        if novo_nome is not None and novo_nome != servico.nome:
            if self.repository.buscar_por_nome(novo_nome):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Já existe um serviço com este nome.",
                )
 
        for campo, valor in campos.items():
            setattr(servico, campo, valor)
        return self.repository.salvar(servico)

    def deletar(self, servico_id: int):
        servico = self.repository.buscar_por_id(servico_id)

        try:
            self.repository.deletar(servico)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Não é possível excluir: existem agendamentos com este serviço. "
                       "Desative o serviço em vez de excluir.",
            )

    

