from core.database import Base, engine
from models.Cliente import Cliente

Base.metadata.create_all(bind=engine)
print("Tabela criada")