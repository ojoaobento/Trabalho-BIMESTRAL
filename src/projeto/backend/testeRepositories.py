from fastapi import HTTPException

from core.database import SessionLocal
from repositories.CategoriaRepository import CategoriaRepository
from services.CategoriaService import CategoriaService
from schemas.CategoriaSchema import CategoriaRequest, CategoriaAtualizarRequest

db = SessionLocal()
service = CategoriaService(CategoriaRepository(db))

criada = service.criar(CategoriaRequest(nome="CCCCCCCCCCCCCCC"))
print("criada:", criada.id, criada.nome, criada.ativo)

try:
    service.criar(CategoriaRequest(nome="CCCCCCCCCCCCCCC"))
except HTTPException as e:
    print("duplicada ->", e.status_code, e.detail)

editada = service.atualizar(criada.id, CategoriaAtualizarRequest(ativo=False))
print("desativada:", editada.ativo, "| nome continua:", editada.nome)

try:
    service.buscar(999999)
except HTTPException as e:
    print("inexistente ->", e.status_code, e.detail)

service.deletar(criada.id)
print("deletada. categorias restantes:", [c.nome for c in service.listar()])

db.close()