from sqlalchemy import select
from sqlalchemy.orm import Session
from datetime import datetime
from models.BloqueioHorario import BloqueioHorario

class BloqueioHorarioRepository:
    def __init__(self, db: Session):
        self.db = db

    def listar(self):
        return self.db.scalars(select(BloqueioHorario).order_by(BloqueioHorario.dt_inicio.desc())).all()

    def buscar_por_id(self, bloqueio_id: int):
        return self.db.get(BloqueioHorario, bloqueio_id)

    def buscar_conflitos(self, inicio: datetime, fim: datetime):
        return self.db.scalars(
            select(BloqueioHorario).where(
                BloqueioHorario.dt_inicio < fim,
                BloqueioHorario.dt_fim > inicio,
            )
        ).all()

    def salvar(self, bloqueio: BloqueioHorario):
        self.db.add(bloqueio)
        self.db.commit()
        self.db.refresh(bloqueio)
        return bloqueio

    def deletar(self, bloqueio: BloqueioHorario):
        self.db.delete(bloqueio)
        self.db.commit()

