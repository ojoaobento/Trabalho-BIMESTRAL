from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timezone
from models.Cliente import Cliente
from repositories.ClienteRepository import ClienteRepository
from schemas.ClienteSchema import (
    ClienteAtualizarRequest,
    ClienteRequest,
    ClienteResponse
)

class ClienteService:
    def __init__(self, repository: ClienteRepository):
        self.repository = repository

    def listar(self):
        return self.repository.listar()

    def buscar_por_id(self, cliente_id: int) -> Cliente:
        cliente = self.repository.buscar_por_id(cliente_id)
        if cliente is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"O Id {cliente_id} do cliente não foi encontrada...")
            )

        return cliente

    def buscar_por_telefone(self, cliente_telefone: str) -> Cliente:
        cliente = self.repository.buscar_por_telefone(cliente_telefone)
        if cliente is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"O telefone {cliente_telefone} do cliente não foi encontrado...")
            )

        return cliente


    def criar(self, dados: ClienteRequest) -> Cliente:
        if self.repository.buscar_por_telefone(dados.telefone):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(f"O cliente que está tentando inserir já possui um cadastro")
            )

        campos = dados.model_dump(exclude={"consentimento"})
        cliente = Cliente(**campos, consentimento_em=datetime.now(timezone.utc))
        return self.repository.salvar(cliente)

    def atualizar(self, cliente_id: int, dados: ClienteAtualizarRequest) -> Cliente:
        cliente = self.repository.buscar_por_id(cliente_id)

        campos = dados.model_dump(exclude_unset=True)

        for campo in ["nome", "telefone", "aceita_lembretes"]:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(f"O campo {campo} não pode ser nulo")
                )
        
        novo_telefone = campos.get("telefone")
        if novo_telefone is not None and novo_telefone != cliente.telefone:
            if self.repository.buscar_por_telefone(novo_telefone):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Este telefone já pertence a outro cliente.",
                )

        for campo, valor in campos.items():
            setattr(cliente, campo, valor)

        return self.repository.salvar(cliente)

    def deletar(self, cliente_id : int):
        cliente = self.repository.buscar_por_id(cliente_id)

        try:
            self.repository.deletar(cliente)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=("Não é possivel excluir esse cliente, por conta que ele possui integrações em outras telas")
            )




    
