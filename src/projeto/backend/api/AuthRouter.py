from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from core.database import get_db
from core.dependencies import get_usuario_logado
from core.security import criar_token
from models.Usuario import Usuario
from repositories.UsuarioRepository import UsuarioRepository
from schemas.AuthSchema import TokenResponse
from schemas.UsuarioSchema import UsuarioResponse
from services.UsuarioService import UsuarioService

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/login", response_model=TokenResponse)
def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    service = UsuarioService(UsuarioRepository(db))
    usuario = service.autenticar(form.username, form.password)
    return TokenResponse(access_token=criar_token(usuario.id))


@router.get("/me", response_model=UsuarioResponse)
def me(usuario: Usuario = Depends(get_usuario_logado)):
    return usuario