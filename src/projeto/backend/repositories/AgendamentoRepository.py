from sqlalchemy import select 
from sqlalchemy.orm import Session
from datetime import datetime

from models.Agendamento import Agendamento, StatusAgendamento


class AgendamentoRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Agendamento).order_by(Agendamento.id)).all()

    def listar_por_cliente(self, cliente_id: int):
        return self.db.scalars(select(Agendamento).where(Agendamento.cliente_id == cliente_id).order_by(Agendamento.dt_inicio.desc())).all()

    def buscar_por_id(self, agendamento_id : int):
        return self.db.get(Agendamento, agendamento_id)

    def buscar_por_periodo(self, inicio: datetime, fim: datetime):
        return self.db.scalars(select(Agendamento).where(
            Agendamento.dt_inicio >= inicio, Agendamento.dt_inicio < fim
        ).order_by(Agendamento.dt_inicio)).all()

    def buscar_conflitos(self, inicio: datetime, fim: datetime):
        return self.db.scalars(select(Agendamento).where(
            Agendamento.dt_inicio < fim, Agendamento.dt_fim > inicio,
            Agendamento.status.in_([
                StatusAgendamento.PENDENTE,
                StatusAgendamento.RESERVADO,
                StatusAgendamento.CONFIRMADO
            ])
        )).all()

    def salvar(self, agendamento: Agendamento):
        self.db.add(agendamento)
        self.db.commit()
        self.db.refresh(agendamento)
        return agendamento

    def deletar(self, agendamento: Agendamento):
        self.db.delete(agendamento)
        self.db.commit()