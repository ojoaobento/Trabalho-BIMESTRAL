"""
backend/core/email_codigo.py

Envio de e-mail leve para a API (código de acesso). Lê as mesmas variáveis
SMTP_* do backend/.env usadas pela automação de lembretes.
Não abre navegador: em modo simulação apenas imprime o e-mail no console.
"""
import os
import smtplib
import email.utils
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

from dotenv import load_dotenv

_ENV = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_ENV if _ENV.exists() else None)


def _config() -> dict:
    return {
        "host": os.getenv("SMTP_HOST", "smtp.gmail.com"),
        "port": int(os.getenv("SMTP_PORT", "587")),
        "usuario": os.getenv("SMTP_USUARIO", "").strip(),
        "senha": os.getenv("SMTP_SENHA", "").strip().replace(" ", ""),
        "nome": os.getenv("SMTP_REMETENTE_NOME", "Studio Cleusa"),
        "simular": os.getenv("SMTP_SIMULAR", "false").lower() in ("true", "1", "sim", "yes"),
    }


def enviar_email_simples(
    destino: str,
    assunto: str,
    corpo_texto: str,
    corpo_html: str | None = None,
) -> bool:
    cfg = _config()

    if cfg["simular"] or not cfg["usuario"] or not cfg["senha"]:
        print(f"\n[E-MAIL SIMULADO] Para: {destino} | Assunto: {assunto}\n{corpo_texto}\n")
        return True

    msg = MIMEMultipart("alternative")
    msg["From"] = f"{cfg['nome']} <{cfg['usuario']}>"
    msg["To"] = destino
    msg["Subject"] = assunto
    msg["Date"] = email.utils.formatdate(localtime=True)
    msg["Message-ID"] = email.utils.make_msgid(domain="gmail.com")
    msg["Reply-To"] = cfg["usuario"]
    msg["Auto-Submitted"] = "auto-generated"
    msg.attach(MIMEText(corpo_texto, "plain", "utf-8"))
    if corpo_html:
        msg.attach(MIMEText(corpo_html, "html", "utf-8"))

    try:
        with smtplib.SMTP(cfg["host"], cfg["port"], timeout=20) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(cfg["usuario"], cfg["senha"])
            server.send_message(msg)
        return True
    except Exception as e:
        print(f"[ERRO E-MAIL] Falha ao enviar para {destino}: {e}")
        return False