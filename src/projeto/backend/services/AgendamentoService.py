from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from models.Agendamento import Agendamento
from repositories.AgendamentoRepository import AgendamentoRepository
from schemas.AgendamentoSchema import (
    AgendamentoAtualizarRequest,
    AgendamentoRequest
)
from repositories.ClienteRepository import ClienteRepository
from repositories.ServicoRepository import ServicoRepository
from datetime import datetime

campos_obrigatorios = [
    "cliente_id", "servico_id", "confirmado_por", 
    "dt_inicio", "dt_fim", "reserva_expira_em", 
    "status", "valor_cobrado"
]

class AgendamentoService:

    def __init__(self, repository: AgendamentoRepository, cliente_repository: ClienteRepository, servico_repository: ServicoRepository):
        self.repository = repository
        self.cliente_repository = cliente_repository
        self.servico_repository = servico_repository

    def listar(self):
        return self.repository.listar()

    def listar_por_cliente(self, cliente_id: int):

        cliente = self.cliente_repository.buscar_por_id(cliente_id)

        if cliente is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Cliente {cliente_id} não foi encontrado.")
            )

        return self.repository.listar_por_cliente(cliente_id)

    def buscar_por_id(self, agendamento_id: int):

        agendamento = self.repository.buscar_por_id(agendamento_id)

        if agendamento is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Agendamento {agendamento_id} não encontrado.")
            )

        return agendamento

    
    def buscar_por_período(self, inicio: datetime, fim: datetime):
        if fim <= inicio:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O fim do período deve ser depois do início.",
            )
        return self.repository.buscar_por_periodo(inicio, fim)
    
    def criar(self, dados: AgendamentoRequest) -> Agendamento:

        if not self.cliente_repository.buscar_por_id(dados.cliente_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cliente {dados.cliente_id} não encontrado."
            )

        if not self.servico_repository.buscar_por_id(dados.servico_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Serviço {dados.servico_id} não encontrado."
            )

        conflitos = self.repository.buscar_conflitos(dados.dt_inicio, dados.dt_fim)
        if conflitos:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Já existe um agendamento nesse intervalo de horário."
            )

        agendamento = Agendamento(**dados.model_dump())
        return self.repository.salvar(agendamento)

    def atualizar(self, agendamento_id: int, dados: AgendamentoAtualizarRequest) -> Agendamento:
        
        agendamento = self.repository.buscar_por_id(agendamento_id)

        if not agendamento:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Agendamento {agendamento_id} não encontrado."
            )

        campos = dados.model_dump(exclude_unset=True)

        for campo in campos_obrigatorios:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"O campo {campo} não pode ser nulo"
                )

        novo_inicio = campos.get("dt_inicio", agendamento.dt_inicio)
        novo_fim = campos.get("dt_fim", agendamento.dt_fim)
        
        if "dt_inicio" in campos or "dt_fim" in campos:
            conflitos = self.repository.buscar_conflitos(novo_inicio, novo_fim)
            for outro in conflitos:
                if outro.id != agendamento_id:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail="O novo horário conflita com outro agendamento existente."
                    )

        for campo, valor in campos.items():
            setattr(agendamento, campo, valor)

        return self.repository.salvar(agendamento)

    def deletar(self, agendamento_id: int) -> None:
        agendamento = self.repository.buscar_por_id(agendamento_id)

        try:
            self.repository.deletar(agendamento)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Não é possível excluir: existem registros dependentes. Desative o agendamento em vez de excluir.",
            )

        