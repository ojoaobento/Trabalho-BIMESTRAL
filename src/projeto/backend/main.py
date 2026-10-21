from fastapi import FastAPI

from api.CategoriaRouter import router as categoria_router

app = FastAPI(title="API de Agendamento - Studio Cleusa")

app.include_router(categoria_router)

@app.get("/", tags=["Saúde"])
def raiz():
    return {"status": "ok"}