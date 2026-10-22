from sqlalchemy import select 
from sqlalchemy.orm import Session

from models.Servico import Servico

class ServicoRepository:

    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Servico).order_by(Servico.id)).all()

    def buscar(self, servico_id : Servico):
        return self.db.scalar(select(Servico).where(Servico.id == servico_id))

    def buscar_por_nome(self, nome : str):
        return self.db.scalar(select(Servico).where(Servico.nome == nome))

    def salvar(self, servico: Servico):
        self.db.add(servico)
        self.db.commit()
        self.db.refresh()
        return servico

    def deletar(self, servico: Servico):
        self.db.delete(servico)
        self.db.commit()

    