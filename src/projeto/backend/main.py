from fastapi import FastAPI

from api.CategoriaRouter import router as categoria_router
from api.ClienteRouter import router as cliente_router
from api.UsuarioRouter import router as usuario_router

app = FastAPI(title="API de Agendamento - Studio Cleusa")

app.include_router(categoria_router)
app.include_router(cliente_router)
app.include_router(usuario_router)

@app.get("/", tags=["Testes"])
def raiz():
    return {"status": "ok"}