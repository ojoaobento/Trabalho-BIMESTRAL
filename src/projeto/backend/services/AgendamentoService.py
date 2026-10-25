from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
 
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
 
from models.Agendamento import Agendamento, StatusAgendamento
from models.Servico import Servico
from repositories.AgendamentoRepository import AgendamentoRepository
from repositories.DisponibilidadeRepository import DisponibilidadeRepository
from repositories.ServicoRepository import ServicoRepository
from schemas.AgendamentoSchema import AgendamentoAtualizarRequest, AgendamentoRequest
from services.ClienteService import ClienteService
from services.LembreteService import LembreteService

FUSO = ZoneInfo("America/Sao_Paulo")
 
S = StatusAgendamento
TRANSICOES = {
    S.RESERVADO: {S.PENDENTE, S.CANCELADO},
    S.PENDENTE: {S.CONFIRMADO, S.CANCELADO},
    S.CONFIRMADO: {S.CONCLUIDO, S.FALTOU, S.CANCELADO},
    S.CANCELADO: set(),
    S.CONCLUIDO: set(),
    S.FALTOU: set(),
}

class AgendamentoService:

    def __init__(
        self,
        repository: AgendamentoRepository,
        cliente_service: ClienteService,
        servico_repository: ServicoRepository,
        disponibilidade_repository: DisponibilidadeRepository,
        lembrete_service: LembreteService,
    ):
        self.repository = repository
        self.cliente_service = cliente_service
        self.servico_repository = servico_repository
        self.disponibilidade_repository = disponibilidade_repository
        self.lembrete_service = lembrete_service

    def listar(self):
        return self.repository.listar()

    def listar_por_cliente(self, cliente_id: int):
        self.cliente_service.buscar_por_id(cliente_id)
        return self.repository.listar_por_cliente(cliente_id)
    
    def buscar_por_id(self, agendamento_id: int):

        agendamento = self.repository.buscar_por_id(agendamento_id)

        if agendamento is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(f"Agendamento {agendamento_id} não encontrado.")
            )

        return agendamento

    
    def listar_por_período(self, inicio: datetime, fim: datetime):
        if fim <= inicio:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O fim do período deve ser depois do início.",
            )
        return self.repository.buscar_por_periodo(inicio, fim)

    
    def _servico_agendavel(self, servico_id: int) -> Servico:
        servico = self.servico_repository.buscar_por_id(servico_id)
        if servico is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Serviço {servico_id} não encontrado.",
            )
        if not servico.ativo or not servico.categoria.ativo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este serviço não está disponível para agendamento.",
            )
        return servico
 
    def _dentro_do_expediente(self, inicio: datetime, fim: datetime) -> bool:
        local_inicio = inicio.astimezone(FUSO)
        local_fim = fim.astimezone(FUSO)
        if local_inicio.date() != local_fim.date():
            return False 
        blocos = self.disponibilidade_repository.listar_por_dia_semana(local_inicio.weekday())
        return any(
            bloco.hora_inicio <= local_inicio.time() and local_fim.time() <= bloco.hora_fim
            for bloco in blocos
        )
 
    def _validar_horario(
        self, servico: Servico, inicio: datetime, ignorar_id: int | None = None
    ) -> datetime:
        agora = datetime.now(timezone.utc)
        if inicio <= agora:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O horário escolhido já passou.",
            )
 
        fim = inicio + timedelta(minutes=servico.duracao_minutos)
 
        if not self._dentro_do_expediente(inicio, fim):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O horário está fora do expediente de atendimento.",
            )
 
        for outro in self.repository.buscar_conflitos(inicio, fim):
            if ignorar_id is not None and outro.id == ignorar_id:
                continue 
            reserva_vencida = (
                outro.status == StatusAgendamento.RESERVADO
                and outro.reserva_expira_em is not None
                and outro.reserva_expira_em <= agora
            )
            if reserva_vencida:
                continue  
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Esse horário acabou de ser ocupado. Escolha outro.",
            )
        return fim

    def criar(self, dados: AgendamentoRequest) -> Agendamento:
        servico = self._servico_agendavel(dados.servico_id)
        fim = self._validar_horario(servico, dados.dt_inicio)
 
        cliente = self.cliente_service.buscar_ou_criar(dados.cliente)
 
        agendamento = Agendamento(
            cliente_id=cliente.id,
            servico_id=servico.id,
            dt_inicio=dados.dt_inicio,
            dt_fim=fim,
            status=StatusAgendamento.PENDENTE,
            valor_cobrado=servico.preco, 
            observacoes=dados.observacoes,
        )
        return self.repository.salvar(agendamento)
    
    def atualizar(self, agendamento_id: int, dados: AgendamentoAtualizarRequest) -> Agendamento:
        agendamento = self.buscar_por_id(agendamento_id)
        campos = dados.model_dump(exclude_unset=True)
 
        if "dt_inicio" in campos and campos["dt_inicio"] is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O campo 'dt_inicio' não pode ser nulo.",
            )
 
        if agendamento.status not in (StatusAgendamento.PENDENTE, StatusAgendamento.CONFIRMADO):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Só agendamentos pendentes ou confirmados podem ser alterados.",
            )
 
        novo_inicio = campos.get("dt_inicio")
        remarcou = novo_inicio is not None and novo_inicio != agendamento.dt_inicio
        if remarcou:
            fim = self._validar_horario(agendamento.servico, novo_inicio, ignorar_id=agendamento.id)
            agendamento.dt_inicio = novo_inicio
            agendamento.dt_fim = fim
 
        if "observacoes" in campos:
            agendamento.observacoes = campos["observacoes"]
 
        agendamento = self.repository.salvar(agendamento)
 
        if remarcou and agendamento.status == StatusAgendamento.CONFIRMADO:
            self.lembrete_service.cancelar_pendentes(agendamento.id)
            self.lembrete_service.criar_para_agendamento(agendamento)
        return agendamento
 
    def alterar_status(
        self, agendamento_id: int, novo_status: StatusAgendamento, usuario_id: int | None = None
    ) -> Agendamento:
        agendamento = self.buscar_por_id(agendamento_id)
        agora = datetime.now(timezone.utc)
 
        if novo_status not in TRANSICOES[agendamento.status]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Não é possível mudar de '{agendamento.status.value}' "
                    f"para '{novo_status.value}'."
                ),
            )
 
        if (
            agendamento.status == StatusAgendamento.RESERVADO
            and agendamento.reserva_expira_em is not None
            and agendamento.reserva_expira_em <= agora
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A reserva deste horário expirou.",
            )
 
        if novo_status == StatusAgendamento.CONFIRMADO and agendamento.dt_inicio <= agora:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Não é possível confirmar um horário que já passou.",
            )
 
        if novo_status in (StatusAgendamento.CONCLUIDO, StatusAgendamento.FALTOU) \
                and agora < agendamento.dt_inicio:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O atendimento ainda não aconteceu.",
            )
 
        if novo_status == StatusAgendamento.CONFIRMADO:
            agendamento.confirmado_por = usuario_id  
        if novo_status in (StatusAgendamento.PENDENTE, StatusAgendamento.CONFIRMADO):
            agendamento.reserva_expira_em = None
 
        agendamento.status = novo_status
        agendamento = self.repository.salvar(agendamento)
 
        if novo_status == StatusAgendamento.CONFIRMADO:
            self.lembrete_service.criar_para_agendamento(agendamento)
        elif novo_status == StatusAgendamento.CANCELADO:
            self.lembrete_service.cancelar_pendentes(agendamento.id)
        return agendamento

    def deletar(self, agendamento_id: int) -> None:
        agendamento = self.buscar_por_id(agendamento_id)
        self.lembrete_service.cancelar_pendentes(agendamento.id)
        try:
            self.repository.deletar(agendamento)
        except IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Não é possível excluir: o agendamento já tem lembretes enviados. "
                       "Cancele o agendamento em vez de excluir.",
            )

        