from sqlalchemy import select 
from sqlalchemy.orm import Session 

from models.Lembrete import Lembrete

class LembreteRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Lembrete).order_by(Lembrete.id)).all()

    def buscar(self, lembrete_id : Lembrete):
        return self.db.scalar(select(Lembrete).where(Lembrete.id == lembrete_id))

    def salvar(self, lembrete: Lembrete):
        self.db.add(lembrete)
        self.db.commit()
        self.db.refresh()
        return lembrete

    def deletar(self, lembrete: Lembrete):
        self.db.delete(lembrete)
        self.db.commit()