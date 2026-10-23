from fastapi import HTTPException, status 
from sqlalchemy.exc import IntegrityError
from repositories.DisponibilidadeRepository import DisponibilidadeRepository
from models.Disponibilidade import Disponibilidade
from schemas.DisponibilidadeSchema import (
    DisponibilidadeAtualizarRequest,
    DisponibilidadeRequest
)

from datetime import datetime, time 

class DisponibilidadeService:

    def __init__(self, repository: DisponibilidadeRepository):
        self.repository = repository 

    def listar(self):
        return self.repository.listar()

    def listar_por_dia_semana(self, dia_semana: int):
        return self.repository.listar_por_dia_semana(dia_semana)

    def buscar_por_id(self, disponibilidade_id: int) -> Disponibilidade:
        disponibilidade = self.repository.buscar_por_id(disponibilidade_id)
        if disponibilidade is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"A Disponibilidade não foi encontrada...")
            )
        return disponibilidade

    def criar(self, dados: DisponibilidadeRequest) -> Disponibilidade:        
        
        disponibilidade = Disponibilidade(nome=dados)

        return self.repository.salvar(disponibilidade)


    def atualizar(self, disponibilidade_id: int, dados: DisponibilidadeAtualizarRequest) -> Disponibilidade:

        disponibilidade = self.repository.buscar_por_id(disponibilidade_id)

        campos = dados.model_dump(exclude_unset=True)

        for campo in ["dia_semana", "hora_inicio", "hora_fim", "ativo"]:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="O campo {campo} não pode ser nulo...."
                )

        for campo, valor in campos.items():
            setattr(disponibilidade, campo, valor)

        return self.repository.salvar(disponibilidade)

    def deletar(self, disponibilidade_id: int) -> None:
        disponibilidade = self.repository.buscar_por_id(disponibilidade_id)

        try:
            self.repository.deletar(disponibilidade)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Não foi possivel realizar a exclusão dessa DISPONIBILIDADE, ela está integrada em outras telas"
            )


