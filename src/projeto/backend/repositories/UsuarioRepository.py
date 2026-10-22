from sqlalchemy import select
from sqlalchemy.orm import Session

from models.Usuario import Usuario
class UsuarioRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Usuario).order_by(Usuario.id)).all()

    def buscar(self, usuario_id: Usuario):
        return self.db.get(usuario_id)

    def buscar_por_nome(self, usuario_nome: str):
        return self.db.scalar(select(Usuario).where(Usuario.nome == usuario_nome))

    def salvar(self, usuario: Usuario):
        self.db.add(usuario)
        self.db.commit()
        self.db.refresh()
        return usuario

    def deletar(self, usuario: Usuario):
        self.db.delete(usuario)
        self.db.commit()