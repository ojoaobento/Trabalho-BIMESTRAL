import getpass

from core.database import SessionLocal
from core.security import gerar_hash
from models.Usuario import Usuario
from repositories.UsuarioRepository import UsuarioRepository


def main():
    nome = input("Nome: ").strip()
    email = input("E-mail: ").strip()
    senha = getpass.getpass("Senha (mínimo 8 caracteres): ")
    confirmacao = getpass.getpass("Repita a senha: ")

    if not nome or not email:
        print("Nome e e-mail são obrigatórios.")
        return
    if senha != confirmacao:
        print("As senhas não conferem.")
        return
    if len(senha) < 8 or len(senha.encode("utf-8")) > 72:
        print("A senha deve ter de 8 caracteres a 72 bytes.")
        return

    db = SessionLocal()
    try:
        repo = UsuarioRepository(db)
        if repo.buscar_por_email(email):
            print("Já existe um usuário com esse e-mail.")
            return
        usuario = repo.salvar(
            Usuario(nome=nome, email=email, senha_hash=gerar_hash(senha), ativo=True)
        )
        print(f"Administrador criado: id {usuario.id}, e-mail {usuario.email}")
    finally:
        db.close()


if __name__ == "__main__":
    main()