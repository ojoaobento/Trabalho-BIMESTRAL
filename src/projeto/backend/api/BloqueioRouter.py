from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.database import get_db
from core.dependencies import get_usuario_logado
from models.BloqueioHorario import BloqueioHorario
from models.Usuario import Usuario
from repositories.BloqueioHorarioRepository import BloqueioHorarioRepository
from schemas.BloqueioHorarioSchema import BloqueioHorarioRequest, BloqueioHorarioResponse

FUSO = ZoneInfo("America/Sao_Paulo")

router = APIRouter(
    prefix="/bloqueios",
    tags=["Bloqueios de Horário"],
    dependencies=[Depends(get_usuario_logado)],
)

def get_repository(db: Session = Depends(get_db)) -> BloqueioHorarioRepository:
    return BloqueioHorarioRepository(db)

@router.get("", response_model=list[BloqueioHorarioResponse])
def listar(repo: BloqueioHorarioRepository = Depends(get_repository)):
    return repo.listar()

@router.post("", response_model=BloqueioHorarioResponse, status_code=status.HTTP_201_CREATED)
def criar(
    dados: BloqueioHorarioRequest,
    repo: BloqueioHorarioRepository = Depends(get_repository),
    usuario: Usuario = Depends(get_usuario_logado),
):
    dt_inicio = datetime.combine(dados.data, dados.hora_inicio, tzinfo=FUSO)
    dt_fim = datetime.combine(dados.data, dados.hora_fim, tzinfo=FUSO)

    if dt_fim <= dt_inicio:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O horário de fim do bloqueio deve ser posterior ao início.",
        )

    conflitos = repo.buscar_conflitos(dt_inicio, dt_fim)
    if conflitos:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe um bloqueio cadastrado para esse intervalo de horário.",
        )

    bloqueio = BloqueioHorario(
        dt_inicio=dt_inicio,
        dt_fim=dt_fim,
        motivo=dados.motivo,
        criado_por=usuario.id,
        criado_em=datetime.now(timezone.utc),
    )
    return repo.salvar(bloqueio)

@router.delete("/{bloqueio_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar(bloqueio_id: int, repo: BloqueioHorarioRepository = Depends(get_repository)):
    bloqueio = repo.buscar_por_id(bloqueio_id)
    if not bloqueio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bloqueio não encontrado.")
    repo.deletar(bloqueio)

