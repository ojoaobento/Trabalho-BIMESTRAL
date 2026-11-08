from datetime import datetime
from sqlalchemy import DateTime, String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from core.database import Base
from models.Usuario import Usuario

class BloqueioHorario(Base):
    __tablename__ = "bloqueio_horario"

    id: Mapped[int] = mapped_column(primary_key=True)
    dt_inicio: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    dt_fim: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    motivo: Mapped[str | None] = mapped_column(String(255), nullable=True)
    criado_por: Mapped[int | None] = mapped_column(ForeignKey("usuario.id"), nullable=True)
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    usuario: Mapped["Usuario | None"] = relationship()

