from sqlalchemy import select 
from sqlalchemy.orm import Session

from models.Disponibilidade import Disponibilidade

class DisponibilidadeRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Disponibilidade).order_by(Disponibilidade.id)).all()

    def listar_por_dia_semana(self, dia_semana: int):
        return self.db.scalars(select(Disponibilidade).
                              where(Disponibilidade.dia_semana == dia_semana, Disponibilidade.ativo.is_(True)).order_by(Disponibilidade.hora_inicio)).all()

    def buscar_por_id(self, disponibilidade_id: int):
        return self.db.get(Disponibilidade, disponibilidade_id)

    def salvar(self, disponibilidade: Disponibilidade):
        self.db.add(disponibilidade)
        self.db.commit()
        self.db.refresh(disponibilidade)
        return disponibilidade

    def deletar(self, disponibilidade: Disponibilidade):
       self.db.delete(disponibilidade)
       self.db.commit() 