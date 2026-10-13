from core.database import Base, engine
from models.Cliente import Cliente
from models.Categoria import Categoria

Base.metadata.create_all(bind=engine)
print("Tabela criada")