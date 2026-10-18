from datetime import time
from sqlalchemy import String, Integer, Boolean, Time
from sqlalchemy.orm import Mapped, mapped_column
from core.database import Base

class Disponibilidade(Base):

    __tablename__ = "disponibilidade"

    id: Mapped[int] = mapped_column(primary_key=True)
    dia_semana: Mapped[int] = mapped_column(Integer)
    hora_inicio: Mapped[time] = mapped_column(Time)
    hora_fim: Mapped[time] = mapped_column(Time)
    ativo: Mapped[bool] = mapped_column(Boolean)