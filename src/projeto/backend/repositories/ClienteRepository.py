from sqlalchemy import select
from sqlalchemy.orm import Session

from models.Cliente import Cliente

class ClienteRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Cliente).order_by(Cliente.id)).all()

    def buscar_por_id(self, cliente_id : int):
        return self.db.get(Cliente, cliente_id)

    def buscar_por_telefone(self, telefone: str):
        return self.db.scalar(select(Cliente).where(Cliente.telefone == telefone))

    def salvar(self, cliente : Cliente):
        self.db.add(cliente)
        self.db.commit()
        self.db.refresh(cliente)
        return cliente

    def deletar(self, cliente : Cliente):
        self.db.delete(cliente)
        self.db.commit()