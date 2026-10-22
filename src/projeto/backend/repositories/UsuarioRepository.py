from sqlalchemy import select
from sqlalchemy.orm import Session

from models.Usuario import Usuario
class UsuarioRepository:
    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Usuario).order_by(Usuario.id)).all()

    def buscar_por_id(self, usuario_id: int):
        return self.db.get(Usuario, usuario_id)

    def buscar_por_email(self, usuario_email: str):
        return self.db.scalar(select(Usuario).where(Usuario.email == usuario_email))

    def salvar(self, usuario: Usuario):
        self.db.add(usuario)
        self.db.commit()
        self.db.refresh(usuario)
        return usuario

    def deletar(self, usuario: Usuario):
        self.db.delete(usuario)
        self.db.commit()