
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.AgendamentoRouter import router as agendamento_router
from api.AuthRouter import router as auth_router
from api.CategoriaRouter import router as categoria_router
from api.UsuarioRouter import router as usuario_router
from api.LembreteRouter import router as lembrete_router
from api.DisponibilidadeRouter import router as disponibilidade_router
from api.ServicoRouter import router as servico_router
from api.ClienteRouter import router as cliente_router

app = FastAPI(
    title="API de Agendamento - Studio Cleusa",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(usuario_router)
app.include_router(categoria_router)
app.include_router(agendamento_router)
app.include_router(lembrete_router)
app.include_router(disponibilidade_router)
app.include_router(servico_router)
app.include_router(cliente_router)
