from datetime import datetime, date

from sqlalchemy import String, Boolean, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column


class Usuario(Base):
    id: Mapped(int) = mapped_column(primary_key=True)
    nome: Mapped(str) = mapped_column(String(100))
    email: Mapped(str) = mapped_column(String(100), unique=True)
    senha_hash: Mapped(str) = mapped_column(String(100))
    ativo: Mapped(bool) = mapped_column(Boolean)
    dt_cadastro: Mapped(datetime) = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )