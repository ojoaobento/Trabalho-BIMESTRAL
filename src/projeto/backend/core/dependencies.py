import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import ler_token
from models.Usuario import Usuario
from repositories.UsuarioRepository import UsuarioRepository

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


def get_usuario_logado(
    token: str | None = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de acesso ausente. Faça login e envie o header "
                   "'Authorization: Bearer <token>'.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_invalido = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido ou expirado. Faça login novamente.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        usuario_id = ler_token(token)
    except (jwt.InvalidTokenError, KeyError, ValueError):  
        raise token_invalido

    usuario = UsuarioRepository(db).buscar_por_id(usuario_id)
    if usuario is None or not usuario.ativo:
        raise token_invalido
    return usuario