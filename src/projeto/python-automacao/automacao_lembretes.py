import sys
import time
import argparse
from datetime import datetime, timezone, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

DIRETORIO_ATUAL = Path(__file__).resolve().parent
DIRETORIO_BACKEND = DIRETORIO_ATUAL.parent / "backend"
if str(DIRETORIO_BACKEND) not in sys.path:
    sys.path.insert(0, str(DIRETORIO_BACKEND))

from email_service import (
    enviar_email,
    gerar_template_confirmacao,
    gerar_template_lembrete_1h,
    obter_config_smtp,
)

FUSO_SP = ZoneInfo("America/Sao_Paulo")


def formatar_data_hora(dt: datetime) -> tuple[str, str]:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    dt_local = dt.astimezone(FUSO_SP)
    return dt_local.strftime("%d/%m/%Y"), dt_local.strftime("%H:%M")


def carregar_modelos():
    from models.Usuario import Usuario
    from models.Categoria import Categoria
    from models.Servico import Servico
    from models.Cliente import Cliente
    from models.Agendamento import Agendamento, StatusAgendamento
    from models.Lembrete import Lembrete, TipoLembrete
    from models.Disponibilidade import Disponibilidade
    return Usuario, Categoria, Servico, Cliente, Agendamento, StatusAgendamento, Lembrete, TipoLembrete


def processar_fila_lembretes(simular: bool = False) -> int:
    
    try:
        from core.database import SessionLocal
        from sqlalchemy import select
        carregar_modelos()
        from models.Lembrete import Lembrete, TipoLembrete
        from models.Agendamento import StatusAgendamento
    except Exception as e:
        print(f"[ERRO DE INICIALIZAÇÃO] Não foi possível carregar os módulos do backend: {e}")
        return 0

    agora_utc = datetime.now(timezone.utc)
    processados = 0

    with SessionLocal() as db:
        query = (
            select(Lembrete)
            .where(Lembrete.enviado.is_(False), Lembrete.enviar_em <= agora_utc)
            .order_by(Lembrete.enviar_em)
        )
        lembretes_pendentes = db.scalars(query).all()

        if not lembretes_pendentes:
            return 0

        print(f"\n[FILA] Encontrado(s) {len(lembretes_pendentes)} lembrete(s) pronto(s) para disparo.")

        for lembrete in lembretes_pendentes:
            agendamento = lembrete.agendamento
            if not agendamento:
                print(f"[AVISO] Lembrete ID {lembrete.id} sem agendamento vinculado. Marcando como processado.")
                lembrete.enviado = True
                lembrete.enviado_em = agora_utc
                db.commit()
                continue

            if agendamento.status == StatusAgendamento.CANCELADO:
                print(f"[CANCELADO] Agendamento ID {agendamento.id} foi cancelado. Ignorando envio.")
                lembrete.enviado = True
                lembrete.enviado_em = agora_utc
                db.commit()
                continue

            cliente = agendamento.cliente
            servico = agendamento.servico

            if not cliente or not cliente.email:
                nome_cliente = cliente.nome if cliente else "Sem Nome"
                print(f"[PULADO] Cliente '{nome_cliente}' não possui e-mail cadastrado.")
                lembrete.enviado = True
                lembrete.enviado_em = agora_utc
                db.commit()
                continue

            if lembrete.tipo == TipoLembrete.LEMBRETE_24H and not getattr(cliente, "aceita_lembretes", True):
                print(f"[OPÇÃO DO CLIENTE] Cliente '{cliente.nome}' optou por não receber lembretes de horário.")
                lembrete.enviado = True
                lembrete.enviado_em = agora_utc
                db.commit()
                continue

            data_str, hora_inicio_str = formatar_data_hora(agendamento.dt_inicio)
            _, hora_fim_str = formatar_data_hora(agendamento.dt_fim)
            valor_str = f"{agendamento.valor_cobrado:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
            nome_servico = (
                lembrete.servico.nome if lembrete.servico 
                else (servico.nome if servico else "Atendimento Estético")
            )

            if lembrete.tipo == TipoLembrete.CONFIRMACAO:
                assunto = f"Confirmação de Agendamento: {nome_servico} - Studio Cleusa"
                corpo_txt, corpo_html = gerar_template_confirmacao(
                    nome_cliente=cliente.nome,
                    nome_servico=nome_servico,
                    data_formatada=data_str,
                    hora_inicio=hora_inicio_str,
                    hora_fim=hora_fim_str,
                    valor_formatado=valor_str,
                    observacoes=agendamento.observacoes,
                )
                tipo_desc = "Confirmação"
            else:
                assunto = f"Lembrete de Horário: {nome_servico} - Studio Cleusa"
                corpo_txt, corpo_html = gerar_template_lembrete_1h(
                    nome_cliente=cliente.nome,
                    nome_servico=nome_servico,
                    data_formatada=data_str,
                    hora_inicio=hora_inicio_str,
                    valor_formatado=valor_str,
                )
                tipo_desc = "Lembrete 1h"

            print(f"\n[DISPARANDO E-MAIL] Tipo: {tipo_desc}")
            print(f" -> Cliente: {cliente.nome} <{cliente.email}>")
            print(f" -> Agendamento ID: {agendamento.id} | Serviço: {nome_servico}")

            sucesso = enviar_email(
                destino=cliente.email,
                assunto=assunto,
                corpo_texto=corpo_txt,
                corpo_html=corpo_html,
                simular=simular,
            )

            if sucesso:
                lembrete.enviado = True
                lembrete.enviado_em = datetime.now(timezone.utc)
                db.commit()
                processados += 1
                print(f"[OK] Lembrete ID {lembrete.id} atualizado para 'enviado = True' no banco de dados.")
            else:
                print(f"[FALHA] Não foi possível enviar o e-mail para o lembrete ID {lembrete.id}.")

    return processados


def disparar_manual(agendamento_id: int, tipo: str, simular: bool = False):
    """Dispara manualmente um e-mail de confirmação ou lembrete para um agendamento específico."""
    carregar_modelos()
    from core.database import SessionLocal
    from models.Agendamento import Agendamento

    with SessionLocal() as db:
        agendamento = db.get(Agendamento, agendamento_id)
        if not agendamento:
            print(f"[ERRO] Agendamento ID {agendamento_id} não encontrado no banco de dados.")
            return

        cliente = agendamento.cliente
        servico = agendamento.servico

        if not cliente or not cliente.email:
            print(f"[ERRO] O agendamento ID {agendamento_id} não possui um cliente com e-mail cadastrado.")
            return

        data_str, hora_inicio_str = formatar_data_hora(agendamento.dt_inicio)
        _, hora_fim_str = formatar_data_hora(agendamento.dt_fim)
        valor_str = f"{agendamento.valor_cobrado:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
        nome_servico = servico.nome if servico else "Atendimento Estético"

        if tipo == "confirmacao":
            assunto = f"Confirmação de Agendamento: {nome_servico} - Studio Cleusa"
            corpo_txt, corpo_html = gerar_template_confirmacao(
                nome_cliente=cliente.nome,
                nome_servico=nome_servico,
                data_formatada=data_str,
                hora_inicio=hora_inicio_str,
                hora_fim=hora_fim_str,
                valor_formatado=valor_str,
                observacoes=agendamento.observacoes,
            )
        else:
            assunto = f"Lembrete de Horário: {nome_servico} - Studio Cleusa"
            corpo_txt, corpo_html = gerar_template_lembrete_1h(
                nome_cliente=cliente.nome,
                nome_servico=nome_servico,
                data_formatada=data_str,
                hora_inicio=hora_inicio_str,
                valor_formatado=valor_str,
            )

        print(f"\n[Envio Manual] {tipo.capitalize()}...")
        print(f" -> Para: {cliente.nome} <{cliente.email}>")
        print(f" -> Agendamento: ID {agendamento.id} | Horário: {hora_inicio_str}")

        enviar_email(
            destino=cliente.email,
            assunto=assunto,
            corpo_texto=corpo_txt,
            corpo_html=corpo_html,
            simular=simular,
        )


def enviar_teste_rapido(email_destino: str, simular: bool = False):
    print(f"\n[Teste] Preparando e-mail para {email_destino}...")
    corpo_txt, corpo_html = gerar_template_confirmacao(
        nome_cliente="Cliente Teste",
        nome_servico="Design de Sobrancelhas",
        data_formatada=datetime.now().strftime("%d/%m/%Y"),
        hora_inicio="14:30",
        hora_fim="15:30",
        valor_formatado="120,00",
        observacoes=None,
    )
    enviar_email(
        destino=email_destino,
        assunto="Confirmação de Agendamento: Design de Sobrancelhas - Studio Cleusa",
        corpo_texto=corpo_txt,
        corpo_html=corpo_html,
        simular=simular,
    )


def loop_monitoramento(intervalo: int = 15, simular: bool = False):
    """Executa o ciclo contínuo de verificação no terminal para apresentação."""
    config = obter_config_smtp()
    modo_str = "SIMULAÇÃO (Navegador/Offline)" if (simular or config["simular"] or not config["usuario"]) else f"REAL (SMTP {config['host']})"

    print("\n" + "=" * 65)
    print("   AUTOMATIZE - SERVIÇO DE DISPARO DE E-MAILS (STUDIO CLEUSA)")
    print("=" * 65)
    print(f" Modo de Operação: {modo_str}")
    print(f" Intervalo entre verificações: {intervalo} segundos")
    print(f" Banco de Dados: Supabase / PostgreSQL")
    print(" Pressione Ctrl+C para encerrar o monitoramento.")
    print("=" * 65 + "\n")

    ciclo = 1
    try:
        while True:
            agora_str = datetime.now(FUSO_SP).strftime("%H:%M:%S")
            print(f"[{agora_str} | Ciclo #{ciclo}] Verificando lembretes pendentes na agenda...", end="\r")
            
            total = processar_fila_lembretes(simular=simular)
            if total > 0:
                print(f"\n[{agora_str}] ✓ Sucesso: {total} e-mail(s) disparado(s) neste ciclo.")

            ciclo += 1
            time.sleep(intervalo)
    except KeyboardInterrupt:
        print("\n\n[ENCERRADO] Monitoramento de automação finalizado pelo usuário.")


def main():
    parser = argparse.ArgumentParser(
        description="Módulo de Automação de E-mails do Projeto Automatize (Studio Cleusa)"
    )
    parser.add_argument(
        "--loop", action="store_true", help="Executa o monitoramento contínuo em loop (ideal para a apresentação)."
    )
    parser.add_argument(
        "--intervalo", type=int, default=15, help="Intervalo em segundos entre verificações no modo loop (padrão: 15s)."
    )
    parser.add_argument(
        "--once", action="store_true", help="Executa uma única verificação na fila e encerra."
    )
    parser.add_argument(
        "--disparar-confirmacao", type=int, metavar="AGENDAMENTO_ID", help="Dispara imediatamente o e-mail de confirmação para o ID informado."
    )
    parser.add_argument(
        "--disparar-lembrete", type=int, metavar="AGENDAMENTO_ID", help="Dispara imediatamente o e-mail de lembrete (1h) para o ID informado."
    )
    parser.add_argument(
        "--test-email", type=str, metavar="EMAIL", help="Dispara um e-mail de teste rápido para o endereço especificado."
    )
    parser.add_argument(
        "--simular", action="store_true", help="Força o modo de simulação (abre preview HTML no navegador sem enviar via rede)."
    )

    args = parser.parse_args()

    if args.test_email:
        enviar_teste_rapido(args.test_email, simular=args.simular)
    elif args.disparar_confirmacao:
        disparar_manual(args.disparar_confirmacao, tipo="confirmacao", simular=args.simular)
    elif args.disparar_lembrete:
        disparar_manual(args.disparar_lembrete, tipo="lembrete", simular=args.simular)
    elif args.loop:
        loop_monitoramento(intervalo=args.intervalo, simular=args.simular)
    elif args.once:
        print("[PROCESSAMENTO ÚNICO] Verificando fila de lembretes pendentes...")
        total = processar_fila_lembretes(simular=args.simular)
        print(f"[CONCLUÍDO] {total} e-mail(s) processado(s).")
    else:
        print("[INFO] Nenhum argumento passado. Executando verificação única:")
        total = processar_fila_lembretes(simular=args.simular)
        print(f"[CONCLUÍDO] {total} e-mail(s) processado(s).")
        print("\nDica: Utilize 'python automacao_lembretes.py --help' para ver os modos de apresentação.")


if __name__ == "__main__":
    main()
