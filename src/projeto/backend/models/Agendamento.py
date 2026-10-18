from sqlalchemy import String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base

class Agendamento(Base):
    id: Mapped[int] = mapped_column(primary_key=True)
    cliente_id: Mapped[int] = mapped_column(ForeignKey("cliente.id"))
    servico_id: Mapped[int] = mapped_column(ForeignKey("servico.id"))
    confirmado_por: Mapped[str] = mapped_column(ForeignKey("usuario.nome"))
    

    cliente: Mapped["Cliente"] = relationship()
    servico: Mapped["Servico"] = relationship()
    usuario: Mapped["Usuario"] = relationship()