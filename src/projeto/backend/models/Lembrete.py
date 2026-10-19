from datetime import datetime
import enum
from sqlalchemy import String, ForeignKey, DateTime, Boolean, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from core.database import Base 

class TipoLembrete(str, enum.Enum):
    CONFIRMACAO = "confirmacao"
    LEMBRETE_24H = "lembrete_24h"

class Lembrete(Base):

    __tablename__ = "lembrete"

    id: Mapped[int] = mapped_column(primary_key=True)
    agendamento_id: Mapped[int] = mapped_column(ForeignKey("agendamento.id"), index=True)
    enviar_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    tipo: Mapped[TipoLembrete] = mapped_column(
        Enum(TipoLembrete, name="tipo_lembrete")
    )
    enviado: Mapped[bool] = mapped_column(Boolean, default=False)
    enviado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    agendamento: Mapped["Agendamento"] = relationship()
