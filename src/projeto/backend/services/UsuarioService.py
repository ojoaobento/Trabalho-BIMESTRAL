from fastapi import HTTPException, status 
from schemas.UsuarioSchema import (
    UsuarioAtualizarRequest,
    UsuarioRequest,
    UsuarioAtualizarCompletoRequest
)
from models.Usuario import Usuario
from repositories.UsuarioRepository import UsuarioRepository
from core.security import verificar_senha, gerar_hash
from sqlalchemy.exc import IntegrityError

class UsuarioService:

    def __init__(self, repository: UsuarioRepository):
        self.repository = repository

    def listar(self):
        return self.repository.listar()

    def buscar_por_id(self, usuario_id: int) -> Usuario:
        usuario = self.repository.buscar_por_id(usuario_id)

        if usuario is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Usuario {usuario_id} não encontrado.")
            )

        return usuario

    def buscar_por_email(self, usuario_email: str) -> Usuario:
        usuario = self.repository.buscar_por_email(usuario_email)

        if usuario is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Usuario {usuario_email} não encontrado.")
            )

        return usuario 

    def criar(self, dados: UsuarioRequest) -> Usuario:

        if self.repository.buscar_por_email(dados.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(f"Já existe um usuário cadastrado com este e-mail.")
            )

        campos = dados.model_dump(exclude={"senha"})
        usuario = Usuario(**campos, senha_hash=gerar_hash(dados.senha))
        return self.repository.salvar(usuario)

    def atualizar(self, usuario_id: int, dados: UsuarioAtualizarRequest) -> Usuario:
        usuario = self.buscar_por_id(usuario_id)  
        campos = dados.model_dump(exclude_unset=True)

        for campo in ["nome", "email", "senha", "ativo"]:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(f"O campo {campo} não pode ser nulo")
                )

        novo_email = campos.get("email")
        if novo_email is not None and novo_email != usuario.email:
            if self.repository.buscar_por_email(novo_email):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Este e-mail já pertence a outro usuário.",
                )
 
        if "senha" in campos:
            usuario.senha_hash = gerar_hash(campos.pop("senha"))
 
        for campo, valor in campos.items():
            setattr(usuario, campo, valor)
        return self.repository.salvar(usuario)

    def atualizar_completo(self, usuario_id: int, dados: UsuarioAtualizarCompletoRequest) -> Usuario:
        usuario = self.buscar_por_id(usuario_id)  
        campos = dados.model_dump()

        for campo in ["nome", "email", "senha", "ativo"]:
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(f"O campo {campo} não pode ser nulo")
                )

        novo_email = campos.get("email")
        if novo_email is not None and novo_email != usuario.email:
            if self.repository.buscar_por_email(novo_email):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Este e-mail já pertence a outro usuário.",
                )
 
        if "senha" in campos:
            usuario.senha_hash = gerar_hash(campos.pop("senha"))
 
        for campo, valor in campos.items():
            setattr(usuario, campo, valor)
        return self.repository.salvar(usuario)

    def deletar(self, usuario_id : int) -> None:
        usuario = self.repository.buscar_por_id(usuario_id)
        try:
            self.repository.deletar(usuario)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Não é possível excluir: este usuário confirmou agendamentos. "
                       "Desative o usuário em vez de excluir.",
            )

    def autenticar(self, email:str, senha:str) -> Usuario:
        usuario = self.repository.buscar_por_email(email)

        if usuario is None or not verificar_senha(senha, usuario.senha_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="E-mail ou senha inválidos.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if not usuario.ativo:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Usuário desativado.",
            )    

        return usuario