from sqlalchemy import String, DateTime, Integer, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from core.database import Base

class Disponibilidade(Base):
    id: Mapped[int] = mapped_column(primary_key=True)
    dia_semana: Mapped[int] = mapped_column(Integer)
    hora_inicio: Mapped[DateTime] = mapped_column(DateTime)
    hora_fim: Mapped[DateTime] = mapped_column(DateTime)
    status: Mapped[bool] = mapped_column(Boolean)