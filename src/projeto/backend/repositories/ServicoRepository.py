from sqlalchemy import select 
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from models.Servico import Servico
from models.Categoria import Categoria

class ServicoRepository:

    def __init__(self, db: Session):
        self.db = db 

    def listar(self):
        return self.db.scalars(select(Servico).order_by(Servico.id)).all()

    def listar_ativos(self):
        return self.db.scalars(select(Servico).join(Servico.categoria).where(
            Servico.ativo.is_(True), Categoria.ativo.is_(True)
        ).order_by(Servico.nome)).all()

    def listar_por_categoria(self, categoria_id: int):
        return self.db.scalars(select(Servico).where(Servico.categoria_id == categoria_id, Servico.ativo.is_(True)).order_by(Servico.nome)).all()

    def buscar_por_id(self, servico_id : int):
        return self.db.get(Servico, servico_id)

    def buscar_por_nome(self, servico_nome : str):
        return self.db.scalar(select(Servico).where(Servico.nome == servico_nome))

    def salvar(self, servico: Servico):
        self.db.add(servico)
        self.db.commit()
        self.db.refresh(servico)
        return servico

    def deletar(self, servico: Servico):
        try:
            self.db.delete(servico)
            self.db.commit()
        except IntegrityError:
            self.db.rollback()
            raise

    