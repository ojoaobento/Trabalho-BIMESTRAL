from sqlalchemy import String, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column
from core.database import Base

class Disponibilidade(Base):
    id: Mapped[int] = mapped_column(primary_key=True)
    dia_semana: Mapped[int] = mapped_column(Integer)
    hora_inicio: Mapped[DateTime] = mapped_column(DateTime)