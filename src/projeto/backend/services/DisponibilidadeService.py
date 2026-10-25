from fastapi import HTTPException, status 
from repositories.DisponibilidadeRepository import DisponibilidadeRepository
from models.Disponibilidade import Disponibilidade
from schemas.DisponibilidadeSchema import (
    DisponibilidadeAtualizarRequest,
    DisponibilidadeRequest
)

from datetime import time 


class DisponibilidadeService:

    def __init__(self, repository: DisponibilidadeRepository):
        self.repository = repository 

    def listar(self):
        disponibilidade = self.repository.listar()

        if not disponibilidade:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Não foi encontrada nenhuma disponibilidade."
            )

        return disponibilidade

    def listar_por_dia_semana(self, dia_semana: int):
        servico = self.repository.listar_por_dia_semana(dia_semana)

        if not servico:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Não foi encontrado disponibilidades nesse dia {dia_semana}")
            )
        return servico
    
    def buscar_por_id(self, disponibilidade_id: int) -> Disponibilidade:
        disponibilidade = self.repository.buscar_por_id(disponibilidade_id)
        if disponibilidade is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"A Disponibilidade não foi encontrada...")
            )
        return disponibilidade

    def _conferir_sobreposicao(self, dia_semana: int, inicio: time, fim: time, ignorar_id: int | None = None) -> None:
       
        for bloco in self.repository.listar_por_dia_semana(dia_semana):

            if not bloco.ativo:
                continue

            if ignorar_id is not None and bloco.id == ignorar_id:
                continue 

            if inicio < bloco.hora_fim and fim > bloco.hora_inicio:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=(
                        f"Este horário se sobrepõe a outro bloco do mesmo dia "
                        f"({bloco.hora_inicio:%H:%M} às {bloco.hora_fim:%H:%M})."
                    )
                )
            
    def criar(self, dados: DisponibilidadeRequest) -> Disponibilidade:        


        if dados.hora_fim <= dados.hora_inicio:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O horário de fim deve ser posterior ao horário de início."
            )

        if dados.ativo:
            self._conferir_sobreposicao(dados.dia_semana, dados.hora_inicio, dados.hora_fim)
        
        disponibilidade = Disponibilidade(**dados.model_dump())

        return self.repository.salvar(disponibilidade)


    def atualizar(self, disponibilidade_id: int, dados: DisponibilidadeAtualizarRequest) -> Disponibilidade:

        disponibilidade = self.buscar_por_id(disponibilidade_id)

        campos = dados.model_dump(exclude_unset=True)

        for campo in ["dia_semana", "hora_inicio", "hora_fim", "ativo"]:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(f"O campo {campo} não pode ser nulo....")
                )

        dia = campos.get("dia_semana", disponibilidade.dia_semana)
        inicio = campos.get("hora_inicio", disponibilidade.hora_inicio)
        fim = campos.get("hora_fim", disponibilidade.hora_fim)
        ativo = campos.get("ativo", disponibilidade.ativo)

        if fim <= inicio:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O horário do fim deve ser depois do horário de ínicio"
            )

        if ativo:
            self._conferir_sobreposicao(dia, inicio, fim, ignorar_id=disponibilidade.id)


        for campo, valor in campos.items():
            setattr(disponibilidade, campo, valor)

        return self.repository.salvar(disponibilidade)

    def deletar(self, disponibilidade_id: int) -> None:
        disponibilidade = self.repository.buscar_por_id(disponibilidade_id)

        if not disponibilidade:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"A disponibilidade {disponibilidade_id} não foi encontrada.")
            )

        self.repository.deletar(disponibilidade)


