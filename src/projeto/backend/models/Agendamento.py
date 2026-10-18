from decimal import Decimal
from datetime import datetime

from sqlalchemy import String, ForeignKey, DateTime, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base


class Agendamento(Base):
    
    __tablename__ = "agendamento"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    cliente_id: Mapped[int] = mapped_column(ForeignKey("cliente.id"), nullable=False)
    servico_id: Mapped[int] = mapped_column(ForeignKey("servico.id"), nullable=False)
    confirmado_por: Mapped[str] = mapped_column(ForeignKey("usuario.nome"))
    dt_inicio: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    dt_fim: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    reserva_expira_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(100), default="pendente")
    valor_cobrado: Mapped[Decimal] = mapped_column(Numeric(10,2), nullable=False)
    dt_cadastro: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    cliente: Mapped["Cliente"] = relationship()
    servico: Mapped["Servico"] = relationship()
    usuario: Mapped["Usuario"] = relationship()