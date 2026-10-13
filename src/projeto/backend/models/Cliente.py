from datetime import datetime, date

from sqlalchemy import String, DateTime, Date, func
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base

class Cliente(Base):
    __tablename__ = "cliente"

    id: Mapped[int] = mapped_column(primary_key=True)
    nome: Mapped[str] = mapped_column(String(100))
    telefone: Mapped[str | None] = mapped_column(String(11))
    email: Mapped[str] = mapped_column(String(100))
    cpf: Mapped[str] = mapped_column(String(11), unique=True)
    dt_nascimento: Mapped[date | None] = mapped_column(Date)
    dt_cadastro: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )





