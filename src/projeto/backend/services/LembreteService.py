from fastapi import HTTPException, status 
from models.Lembrete import Lembrete
from models.Agendamento import Agendamento, StatusAgendamento
from schemas.LembreteSchema import (
    LembreteAtualizarRequest,
    LembreteRequest,
    TipoLembrete,
    LembreteAtualizarCompletoRequest
)
from repositories.AgendamentoRepository import AgendamentoRepository
from repositories.LembreteRepository import LembreteRepository
from repositories.ServicoRepository import ServicoRepository
from datetime import datetime, timedelta, timezone


STATUS_ENCERRADOS = (
    StatusAgendamento.CANCELADO,
    StatusAgendamento.CONCLUIDO,
    StatusAgendamento.FALTOU,
)

class LembreteService:

    def __init__(self, repository: LembreteRepository, agendamento_repository: AgendamentoRepository, servico_repository: ServicoRepository):
        self.repository = repository
        self.agendamento_repository = agendamento_repository
        self.servico_repository = servico_repository


    def listar(self):
        return self.repository.listar()

    def listar_pendentes(self):
        return self.repository.listar_pendentes(datetime.now(timezone.utc))

    def buscar_por_id(self, lembrete_id: int) -> Lembrete:
        lembrete = self.repository.buscar_por_id(lembrete_id)

        if lembrete is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Lembrete {lembrete_id} não encontrado."
            )

        return lembrete

    def criar(self, dados: LembreteRequest) -> Lembrete:
        agendamento = self.agendamento_repository.buscar_por_id(dados.agendamento_id)

        if agendamento is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Agendamento {dados.agendamento_id} não encontrado.",
            )

        if agendamento.status in STATUS_ENCERRADOS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este agendamento já foi encerrado e não precisa de lembrete.",
            )

        servico_id = dados.servico_id or agendamento.servico_id

        if dados.servico_id is not None:
            if self.servico_repository.buscar_por_id(dados.servico_id) is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Servico {dados.servico_id} não encontrado.",
                )

        lembrete = Lembrete(
            agendamento_id=dados.agendamento_id,
            servico_id=servico_id,
            enviar_em=dados.enviar_em,
            tipo=dados.tipo,
            enviado=False,
        )
        return self.repository.salvar(lembrete)

    def atualizar(self, lembrete_id: int, dados: LembreteAtualizarRequest) -> Lembrete:
        lembrete = self.buscar_por_id(lembrete_id)
        campos = dados.model_dump(exclude_unset=True)

        for campo, valor in campos.items():
            if valor is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"O campo {campo} não pode ser nulo."
                )

        novo_servico = campos.get("servico_id")
        if novo_servico is not None and novo_servico != lembrete.servico_id:
            if self.servico_repository.buscar_por_id(novo_servico) is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Servico {novo_servico} não encontrado.",
                )

        for campo, valor in campos.items():
            setattr(lembrete, campo, valor)

        return self.repository.salvar(lembrete)

    def atualizar_completo(self, lembrete_id: int, dados: LembreteAtualizarCompletoRequest) -> Lembrete:
        return self.atualizar(lembrete_id, LembreteAtualizarRequest(**dados.model_dump()))

    def deletar(self, lembrete_id: int) -> None:
        lembrete = self.buscar_por_id(lembrete_id)

        self.repository.deletar(lembrete)


    def marcar_como_enviado(self, lembrete_id: int) -> Lembrete:
        lembrete = self.buscar_por_id(lembrete_id)
        if lembrete.enviado:
            return lembrete 
        
        lembrete.enviado = True
        lembrete.enviado_em = datetime.now(timezone.utc)
        return self.repository.salvar(lembrete)

    def criar_para_agendamento(self, agendamento: Agendamento) -> list[Lembrete]:
 
        criados = []
        agora = datetime.now(timezone.utc)

        lembretes_existentes = self.repository.listar_por_agendamento(agendamento.id)
        tipos_existentes = {l.tipo for l in lembretes_existentes}

        if TipoLembrete.CONFIRMACAO not in tipos_existentes:
            lembrete_confirmacao = Lembrete(
                agendamento_id=agendamento.id,
                servico_id=agendamento.servico_id,
                tipo=TipoLembrete.CONFIRMACAO,
                enviar_em=agora,
                enviado=False,
            )
            criados.append(self.repository.salvar(lembrete_confirmacao))

        cliente = agendamento.cliente
        aceita = getattr(cliente, "aceita_lembretes", True) if cliente else True

        if aceita and TipoLembrete.LEMBRETE_24H not in tipos_existentes:
            enviar_em = agendamento.dt_inicio - timedelta(hours=24)

            if enviar_em < agora:
                enviar_em = agora

            lembrete_24h = Lembrete(
                agendamento_id=agendamento.id,
                servico_id=agendamento.servico_id,
                tipo=TipoLembrete.LEMBRETE_24H,
                enviar_em=enviar_em,
                enviado=False,
            )
            criados.append(self.repository.salvar(lembrete_24h))

        return criados
    
    def cancelar_pendentes(self, agendamento_id: int) -> None:
        for lembrete in self.repository.listar_por_agendamento(agendamento_id):
            if not lembrete.enviado:
                self.repository.deletar(lembrete)
