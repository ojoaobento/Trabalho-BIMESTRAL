from sqlalchemy import select 
from sqlalchemy.orm import Session 
from datetime import datetime
from models.Lembrete import Lembrete

class LembreteRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Lembrete).order_by(Lembrete.id)).all()

    def listar_pendentes(self, agora: datetime):
        return self.db.scalars(select(Lembrete).where(
            Lembrete.enviado.is_(False), Lembrete.enviar_em <= agora
        ).order_by(Lembrete.enviar_em)).all()

    def listar_por_agendamento(self, agendamento_id: int):
        return self.db.scalars(select(Lembrete).where(Lembrete.agendamento_id == agendamento_id)).all()

    def buscar_por_id(self, lembrete_id : int):
        return self.db.get(Lembrete, lembrete_id)

    def salvar(self, lembrete: Lembrete):
        self.db.add(lembrete)
        self.db.commit()
        self.db.refresh(lembrete)
        return lembrete

    def deletar(self, lembrete: Lembrete):
        self.db.delete(lembrete)
        self.db.commit()