from decimal import Decimal
from sqlalchemy import String, ForeignKey, Numeric, Integer, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from core.database import Base

class Servico(Base):

    __tablename__ = "servico"

    id: Mapped[int] = mapped_column(primary_key=True)
    categoria_id: Mapped[int] = mapped_column(ForeignKey("categoria.id"))
    nome: Mapped[str] = mapped_column(String(100))
    descricao: Mapped[str | None] = mapped_column(String(100))
    preco: Mapped[Decimal] = mapped_column(Numeric(10,2))
    duracao_minutos: Mapped[int] = mapped_column(Integer)
    ativo: Mapped[bool] = mapped_column(Boolean, default=True)

    categoria: Mapped["Categoria"] = relationship()
