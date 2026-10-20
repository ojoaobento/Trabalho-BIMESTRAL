from core.database import engine
from sqlalchemy import text  

with engine.connect() as conn:
    resultado = conn.execute(text("SELECT 1"))
    print("Conexão OK! Resultado:", resultado.scalar())

from core.database import SessionLocal

db = SessionLocal()
print(db)
db.close()