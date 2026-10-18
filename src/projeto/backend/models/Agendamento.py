import enum
from decimal import Decimal
from datetime import datetime
from sqlalchemy import ForeignKey, DateTime, Numeric, func, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from core.database import Base
class StatusAgendamento(str, enum.Enum):
    RESERVADO = "reservado"
    PENDENTE = "pendente"
    CONFIRMADO = "confirmado"
    CANCELADO = "cancelado"
    CONCLUIDO = "concluido"
    FALTOU = "faltou"

class Agendamento(Base):
    
    __tablename__ = "agendamento"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    cliente_id: Mapped[int] = mapped_column(ForeignKey("cliente.id"))
    servico_id: Mapped[int] = mapped_column(ForeignKey("servico.id"))
    confirmado_por: Mapped[int | None] = mapped_column(ForeignKey("usuario.id"))
    dt_inicio: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    dt_fim: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    reserva_expira_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[StatusAgendamento] = mapped_column(Enum(
        StatusAgendamento, name="status_agendamento"
    ), default=StatusAgendamento.PENDENTE)
    valor_cobrado: Mapped[Decimal] = mapped_column(Numeric(10,2), nullable=False)
    dt_cadastro: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    cliente: Mapped["Cliente"] = relationship()
    servico: Mapped["Servico"] = relationship()
    usuario: Mapped["Usuario | None"] = relationship()