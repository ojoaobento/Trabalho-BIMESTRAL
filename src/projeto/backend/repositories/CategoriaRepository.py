from sqlalchemy import select
from sqlalchemy.orm import Session

from models.Categoria import Categoria

class CategoriaRepository:
    def __init__(self, db: Session):
        self.db = db

    def listar(self):
        return self.db.scalars(select(Categoria).order_by(Categoria.id)).all()

    def buscar_por_id(self, categoria_id: int):
        return self.db.get(Categoria, categoria_id)

    def salvar(self, categoria: Categoria):
        self.db.add(categoria)
        self.db.commit()
        self.db.refresh(categoria)
        return categoria

    def deletar(self, categoria: Categoria):
        self.db.delete(categoria)
        self.db.commit()