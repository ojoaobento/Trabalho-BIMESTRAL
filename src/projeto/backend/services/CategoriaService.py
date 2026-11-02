from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError


from models.Categoria import Categoria
from repositories.CategoriaRepository import CategoriaRepository
from schemas.CategoriaSchema import CategoriaRequest, CategoriaAtualizarRequest, CategoriaAtualizarCompletoRequest

class CategoriaService:
    def __init__(self, repository: CategoriaRepository):
        self.repository = repository

    def listar(self):
        return self.repository.listar()

    def buscar(self, categoria_id : int) -> Categoria:
        categoria = self.repository.buscar_por_id(categoria_id)
        if categoria is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Categoria {categoria_id} não foi encontrada")
            )
        
        return categoria
    def criar(self, dados: CategoriaRequest) -> Categoria:
        if self.repository.buscar_por_nome(dados.nome):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(f"Já existe uma categoria com essa chamada: {dados.nome}")
            )
        categoria = Categoria(nome=dados.nome)

        try:
            return self.repository.salvar(categoria)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Já existe uma categoria com o nome: {dados.nome}"
            )

    def atualizar(self, categoria_id : int, dados: CategoriaAtualizarRequest) -> Categoria:
        categoria = self.buscar(categoria_id)

        campos = dados.model_dump(exclude_unset=True)


        for campo in ("nome", "ativo"):
            if campo in campos and campos[campo] is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(f"O campo '{campo}' não pode ser nulo")
                )

        novo_nome = campos.get("nome")
        if novo_nome is not None and novo_nome != categoria.nome:
            if self.repository.buscar_por_nome(novo_nome):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Já existe uma categoria com o nome: {novo_nome}"
                )
    
        for campo, valor in campos.items():
            setattr(categoria, campo, valor)

        try:
            return self.repository.salvar(categoria)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Já existe uma categoria com este nome."
            )
        
    def atualizar_completo(self, categoria_id: int, dados: CategoriaAtualizarCompletoRequest) -> Categoria:
        return self.atualizar(categoria_id, CategoriaAtualizarRequest(**dados.model_dump()))
    
    def deletar(self, categoria_id : int) -> None:
        categoria = self.buscar(categoria_id)  

        try:
            self.repository.deletar(categoria)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Não é possível excluir: existem serviços nesta categoria. "
                       "Desative a categoria em vez de excluir."
            )