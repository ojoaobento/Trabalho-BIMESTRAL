from core.database import SessionLocal
from models.Categoria import Categoria
from repositories.CategoriaRepository import CategoriaRepository
 
db = SessionLocal()
repo = CategoriaRepository(db)
 
nova = Categoria(nome="AAA")
salva = repo.salvar(nova)
print("id gerado:", salva.id)
 
print("todas:", [c.nome for c in repo.listar()])
print("por id:", repo.buscar_por_id(salva.id))
 
repo.deletar(salva)
 
db.close()