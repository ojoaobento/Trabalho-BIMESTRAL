from fastapi import HTTPException, status 
from sqlalchemy.exc import IntegrityError
from models.Lembrete import Lembrete
from models.Agendamento import Agendamento, StatusAgendamento
from schemas.LembreteSchema import (
    LembreteAtualizarRequest,
    LembreteRequest,
    TipoLembrete
)
from repositories.AgendamentoRepository import AgendamentoRepository
from repositories.LembreteRepository import LembreteRepository
from datetime import datetime, timedelta, timezone


STATUS_ENCERRADOS = (
    StatusAgendamento.CANCELADO,
    StatusAgendamento.CONCLUIDO,
    StatusAgendamento.FALTOU,
)

class LembreteService:

    def __init__(self, repository: LembreteRepository, agendamento_repository: AgendamentoRepository):
        self.repository = repository
        self.agendamento_repository = agendamento_repository


    def listar(self):
        return self.repository.listar()

    def listar_pendetes(self):
        return self.repository.listar_pendentes(datetime.now(timezone.utc))

    def buscar_por_id(self, lembrete_id: int) -> Lembrete:
        lembrete = self.repository.buscar_por_id(lembrete_id)

        if lembrete is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lembrete {lembrete_id} não encontrado."
            )

        return lembrete

    def criar(self, dados: LembreteRequest) -> Lembrete:

        agendamento = self.agendamento_repository.buscar_por_id(dados.agendamento_id)

        if agendamento is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Agendamento {dados.agendamento_id} não encontrado.",
            )

        if agendamento.status in STATUS_ENCERRADOS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este agendamento já foi encerrado e não precisa de lembrete.",
            )
        
        lembrete = Lembrete(**dados.model_dump())

        return self.repository.salvar(lembrete)

    def atualizar(self, lembrete_id: int, dados: LembreteAtualizarRequest) -> Lembrete:

        lembrete = self.repository.buscar_por_id(lembrete_id)

        campos = dados.model_dump(exclude_unset=True)

        for campo in ["enviar_em", "tipo", "enviado"]:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="O campo {campo} não pode ser nulo...."
                )            

        estava_enviado = lembrete.enviado

        for campo, valor in campos.items():
            setattr(lembrete, campo, valor)

        if "enviado" in campos and lembrete.enviado != estava_enviado:
            lembrete.enviado_em = datetime.now(timezone.utc) if lembrete.enviado else None

        return self.repository.salvar(lembrete)

    def deletar(self, lembrete_id: int) -> None:
        lembrete = self.repository.buscar_por_id(lembrete_id)

        self.repository.deletar(lembrete)


    def marcar_como_enviado(self, lembrete_id: int) -> Lembrete:
        lembrete = self.repository.buscar_por_id(lembrete_id)
        if lembrete.enviado:
            return lembrete 
        
        lembrete.enviado = True
        lembrete.enviado_em = datetime.now(timezone.utc)
        return self.repository.salvar(lembrete)

    def criar_para_agendamento(self, agendamento: Agendamento) -> Lembrete | None:
        enviar_em = agendamento.dt_inicio - timedelta(hours=24)
        if enviar_em <= datetime.now(timezone.utc):
            return None
        lembrete = Lembrete(
            agendamento_id=agendamento.id,
            tipo=TipoLembrete.LEMBRETE_24H,
            enviar_em=enviar_em,
        )
        return self.repository.salvar(lembrete)
    
    def cancelar_pendentes(self, agendamento_id: int) -> None:
        for lembrete in self.repository.listar_por_agendamento(agendamento_id):
            if not lembrete.enviado:
                self.repository.deletar(lembrete)

    