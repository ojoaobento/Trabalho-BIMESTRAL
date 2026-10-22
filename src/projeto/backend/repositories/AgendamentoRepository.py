from sqlalchemy import select 
from sqlalchemy.orm import Session

from models.Agendamento import Agendamento


class AgendamentoRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Agendamento).order_by(Agendamento.id)).all()

    def buscar(self, agendamento_id : Agendamento):
        return self.db.scalars(select(Agendamento).where(Agendamento.id == agendamento_id))

    def buscar_por_cliente(self, cliente: str):
        return self.db.scalar(select(Agendamento).where(Agendamento.cliente == cliente))

    def salvar(self, agendamento: Agendamento):
        self.db.add(agendamento)
        self.db.commit()
        self.db.refresh()
        return agendamento

    def deletar(self, agendamento: Agendamento):
        self.db.delete(agendamento)
        self.db.commit()