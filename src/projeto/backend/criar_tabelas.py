from core.database import Base, engine
from models.Cliente import Cliente
from models.Categoria import Categoria
from models.Servico import Servico
from models.Usuario import Usuario
from models.Agendamento import Agendamento
from models.Lembrete import Lembrete
from models.Disponibilidade import Disponibilidade
from models.BloqueioHorario import BloqueioHorario
from api.MeusAgendamentos import CodigoAcesso 

Base.metadata.create_all(bind=engine)
print("Tabela criada")