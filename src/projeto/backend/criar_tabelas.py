from core.database import Base, engine
from models.Cliente import Cliente
from models.Categoria import Categoria
from models.Servico import Servico

Base.metadata.create_all(bind=engine)
print("Tabela criada")