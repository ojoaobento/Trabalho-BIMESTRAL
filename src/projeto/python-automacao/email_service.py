import os
import sys
import base64
import smtplib
import webbrowser
import email.utils
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from pathlib import Path
from dotenv import load_dotenv

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

caminho_env_backend = Path(__file__).resolve().parent.parent / "backend" / ".env"
if caminho_env_backend.exists():
    load_dotenv(caminho_env_backend)
else:
    load_dotenv()

CAMINHO_LOGO_CIRCLE = Path(__file__).resolve().parent / "assets" / "logo_cleusa_circle.png"
CAMINHO_LOGO = CAMINHO_LOGO_CIRCLE if CAMINHO_LOGO_CIRCLE.exists() else Path(__file__).resolve().parent / "assets" / "logo_cleusa.png"


def gerar_marca_studio_html() -> str:
    """Logo do Studio Cleusa (flor de lótus com gota) feita só com HTML e CSS.

    Sem <img>, sem CID e sem SVG: nada para o e-mail "bloquear imagens" nem
    anexo escondido, o que ajuda a não cair no spam. Usa só tabelas, divs e
    border-radius, que Gmail, Apple Mail, Outlook.com e Thunderbird renderizam.
    (O Outlook para desktop não suporta border-radius e mostra formas retas.)
    """
    cor = "#D6284A"
    fundo = "#FCE8ED"
    zero = "padding:0;line-height:0;font-size:0;"
    return f"""
<table role="presentation" align="center" cellpadding="0" cellspacing="0" border="0" style="margin:0 auto 14px auto;">
  <tr>
    <td align="center" valign="middle" width="78" height="78" style="width:78px;height:78px;background-color:{fundo};border-radius:50%;text-align:center;">
      <table role="presentation" align="center" cellpadding="0" cellspacing="0" border="0" style="margin:0 auto;">
        <tr>
          <td align="center" style="{zero}">
            <div style="width:7px;height:10px;background-color:{cor};border-radius:50% 50% 50% 50% / 70% 70% 30% 30%;margin:0 auto 3px auto;"></div>
          </td>
        </tr>
        <tr>
          <td align="center" style="{zero}">
            <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 auto;">
              <tr>
                <td valign="bottom" style="{zero}">
                  <div style="width:14px;height:20px;border:2px solid {cor};border-radius:0 100% 0 100%;"></div>
                </td>
                <td valign="bottom" style="padding:0 1px;line-height:0;font-size:0;">
                  <div style="width:12px;height:26px;border:2px solid {cor};border-radius:50% 50% 50% 50% / 80% 80% 20% 20%;"></div>
                </td>
                <td valign="bottom" style="{zero}">
                  <div style="width:14px;height:20px;border:2px solid {cor};border-radius:100% 0 100% 0;"></div>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td align="center" style="{zero}">
            <div style="width:34px;height:7px;border:2px solid {cor};border-top:0;border-radius:0 0 50% 50% / 0 0 100% 100%;margin:2px auto 0 auto;"></div>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<h1 style="margin:0;font-family:Georgia,'Times New Roman',serif;font-size:21px;font-weight:700;color:#8E2348;letter-spacing:1.5px;text-transform:uppercase;">Studio Cleusa</h1>
<p style="margin:3px 0 0 0;font-size:10px;font-weight:600;color:#A45C74;letter-spacing:2.5px;text-transform:uppercase;">Beleza &bull; Est&eacute;tica</p>
""".strip()


def obter_logo_bytes() -> bytes | None:
    if CAMINHO_LOGO.exists():
        try:
            with open(CAMINHO_LOGO, "rb") as f:
                return f.read()
        except Exception:
            pass
    return None


def obter_logo_base64() -> str:
    dados = obter_logo_bytes()
    if dados:
        return base64.b64encode(dados).decode("utf-8")
    return ""


def obter_config_smtp():
    return {
        "host": os.getenv("SMTP_HOST", "smtp.gmail.com"),
        "port": int(os.getenv("SMTP_PORT", "587")),
        "usuario": os.getenv("SMTP_USUARIO", "").strip(),
        "senha": os.getenv("SMTP_SENHA", "").strip().replace(" ", ""),
        "remetente_nome": os.getenv("SMTP_REMETENTE_NOME", "Studio Cleusa"),
        "simular": os.getenv("SMTP_SIMULAR", "false").lower() in ("true", "1", "sim", "yes"),
    }


def gerar_template_confirmacao(
    nome_cliente: str,
    nome_servico: str,
    data_formatada: str,
    hora_inicio: str,
    hora_fim: str,
    valor_formatado: str,
    observacoes: str | None = None,
) -> tuple[str, str]:
    corpo_texto = f"""
Olá, {nome_cliente}.

Confirmamos o seu agendamento no Studio Cleusa.

Detalhes do atendimento:
- Serviço: {nome_servico}
- Data: {data_formatada}
- Horário: {hora_inicio} às {hora_fim}
- Valor: R$ {valor_formatado}
- Local: Bairro Santa Luzia, 313

Caso precise remarcar ou cancelar, pedimos que nos avise com antecedência.

Studio Cleusa
""".strip()

    marca_html = gerar_marca_studio_html()

    corpo_html = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Confirmação de Agendamento</title>
</head>
<body style="margin: 0; padding: 24px 12px; background-color: #f7f6f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; color: #222222; line-height: 1.5;">

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width: 520px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; border: 1px solid #e8e4e1; overflow: hidden;">
    
    <tr>
      <td style="padding: 28px 24px 20px 24px; text-align: center; border-bottom: 1px solid #f0ece9;">
        {marca_html}
        <p style="margin: 6px 0 0 0; font-size: 13px; color: #777777;">Confirmação de Agendamento</p>
      </td>
    </tr>

    <tr>
      <td style="padding: 24px;">
        <p style="margin: 0 0 14px 0; font-size: 15px;">
          Olá, <strong>{nome_cliente}</strong>.
        </p>
        <p style="margin: 0 0 20px 0; font-size: 14px; color: #444444;">
          Seu horário foi agendado com sucesso no Studio Cleusa. Seguem as informações do seu atendimento:
        </p>

        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #faf9f8; border: 1px solid #ede8e5; border-radius: 8px; padding: 12px 16px; margin-bottom: 20px;">
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px; width: 32%;">Serviço</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px; font-weight: 600;">{nome_servico}</td>
          </tr>
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Data</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px;">{data_formatada}</td>
          </tr>
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Horário</td>
            <td style="padding: 8px 0; color: #8E2348; font-size: 14px; font-weight: 600;">{hora_inicio} às {hora_fim}</td>
          </tr>
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Valor</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px;">R$ {valor_formatado}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Local</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px;">Studio Cleusa</td>
          </tr>
        </table>

        <p style="margin: 0 0 16px 0; font-size: 13px; color: #666666;">
          Caso precise cancelar ou remarcar, pedimos que nos avise com antecedência.
        </p>

        <p style="margin: 0; font-size: 14px; color: #333333;">
          Até breve,
        </p>
        <p style="margin: 4px 0 0 0; font-size: 14px; font-weight: 600; color: #8E2348;">
          Studio Cleusa
        </p>
      </td>
    </tr>

    <tr>
      <td style="padding: 14px 20px; text-align: center; background-color: #faf8f7; border-top: 1px solid #f0eae7; font-size: 11px; color: #888888;">
        Studio Cleusa &bull; Mensagem automática sobre o seu agendamento
      </td>
    </tr>

  </table>

</body>
</html>"""
    return corpo_texto, corpo_html


def gerar_template_lembrete_24h(
    nome_cliente: str,
    nome_servico: str,
    data_formatada: str,
    hora_inicio: str,
    valor_formatado: str,
    dia_semana: str,
) -> tuple[str, str]:
    """Lembrete enviado com antecedência (24h): mostra o dia da semana em vez de "Hoje"."""
    corpo_texto = f"""
Olá, {nome_cliente}.

Lembramos do seu atendimento no Studio Cleusa: {dia_semana}, {data_formatada}, às {hora_inicio}.

Detalhes:
- Serviço: {nome_servico}
- Dia: {dia_semana}, {data_formatada}
- Horário: {hora_inicio}
- Valor: R$ {valor_formatado}
- Local: Studio Cleusa

Recomendamos chegar com 5 a 10 minutos de antecedência.

Studio Cleusa
""".strip()

    marca_html = gerar_marca_studio_html()

    corpo_html = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Lembrete de Agendamento</title>
</head>
<body style="margin: 0; padding: 24px 12px; background-color: #f7f6f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; color: #222222; line-height: 1.5;">

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width: 520px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; border: 1px solid #e8e4e1; overflow: hidden;">
    
    <tr>
      <td style="padding: 26px 24px 18px 24px; text-align: center; border-bottom: 1px solid #f0ece9;">
        {marca_html}
        <p style="margin: 6px 0 0 0; font-size: 13px; color: #777777;">Lembrete de Horário</p>
      </td>
    </tr>

    <tr>
      <td style="padding: 24px;">
        <p style="margin: 0 0 14px 0; font-size: 15px;">
          Olá, <strong>{nome_cliente}</strong>.
        </p>
        <p style="margin: 0 0 18px 0; font-size: 14px; color: #444444;">
          Lembramos do seu horário no Studio Cleusa:
        </p>

        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #faf9f8; border: 1px solid #ede8e5; border-radius: 8px; padding: 12px 16px; margin-bottom: 18px;">
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px; width: 32%;">Serviço</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px; font-weight: 600;">{nome_servico}</td>
          </tr>
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Horário</td>
            <td style="padding: 8px 0; color: #8E2348; font-size: 15px; font-weight: 600;">{hora_inicio} <span style="font-size: 13px; font-weight: normal; color: #666666;">({dia_semana})</span></td>
          </tr>
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Valor</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px;">R$ {valor_formatado}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Local</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px;">Studio Cleusa</td>
          </tr>
        </table>

        <p style="margin: 0 0 16px 0; font-size: 13px; color: #666666;">
          Recomendamos chegar com 5 a 10 minutos de antecedência.
        </p>

        <p style="margin: 0; font-size: 14px; color: #333333;">
          Aguardamos você,
        </p>
        <p style="margin: 4px 0 0 0; font-size: 14px; font-weight: 600; color: #8E2348;">
          Studio Cleusa
        </p>
      </td>
    </tr>

    <tr>
      <td style="padding: 14px 20px; text-align: center; background-color: #faf8f7; border-top: 1px solid #f0eae7; font-size: 11px; color: #888888;">
        Studio Cleusa &bull; Lembrete enviado conforme solicitado
      </td>
    </tr>

  </table>

</body>
</html>"""
    return corpo_texto, corpo_html


def gerar_template_lembrete_1h(
    nome_cliente: str,
    nome_servico: str,
    data_formatada: str,
    hora_inicio: str,
    valor_formatado: str,
) -> tuple[str, str]:
    corpo_texto = f"""
Olá, {nome_cliente}.

Lembramos que o seu atendimento no Studio Cleusa será hoje às {hora_inicio}.

Detalhes:
- Serviço: {nome_servico}
- Data: {data_formatada}
- Horário: {hora_inicio}
- Valor: R$ {valor_formatado}
- Local: Studio Cleusa

Recomendamos chegar com alguns minutos de antecedência.

Studio Cleusa
""".strip()

    marca_html = gerar_marca_studio_html()

    corpo_html = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Lembrete de Agendamento</title>
</head>
<body style="margin: 0; padding: 24px 12px; background-color: #f7f6f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; color: #222222; line-height: 1.5;">

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width: 520px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; border: 1px solid #e8e4e1; overflow: hidden;">
    
    <tr>
      <td style="padding: 26px 24px 18px 24px; text-align: center; border-bottom: 1px solid #f0ece9;">
        {marca_html}
        <p style="margin: 6px 0 0 0; font-size: 13px; color: #777777;">Lembrete de Horário</p>
      </td>
    </tr>

    <tr>
      <td style="padding: 24px;">
        <p style="margin: 0 0 14px 0; font-size: 15px;">
          Olá, <strong>{nome_cliente}</strong>.
        </p>
        <p style="margin: 0 0 18px 0; font-size: 14px; color: #444444;">
          Lembramos que seu horário no Studio Cleusa acontece daqui a pouco:
        </p>

        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #faf9f8; border: 1px solid #ede8e5; border-radius: 8px; padding: 12px 16px; margin-bottom: 18px;">
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px; width: 32%;">Serviço</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px; font-weight: 600;">{nome_servico}</td>
          </tr>
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Horário</td>
            <td style="padding: 8px 0; color: #8E2348; font-size: 15px; font-weight: 600;">{hora_inicio} <span style="font-size: 13px; font-weight: normal; color: #666666;">(Hoje)</span></td>
          </tr>
          <tr style="border-bottom: 1px solid #f0eae7;">
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Valor</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px;">R$ {valor_formatado}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #6b6b6b; font-size: 14px;">Local</td>
            <td style="padding: 8px 0; color: #222222; font-size: 14px;">Studio Cleusa</td>
          </tr>
        </table>

        <p style="margin: 0 0 16px 0; font-size: 13px; color: #666666;">
          Recomendamos chegar com 5 a 10 minutos de antecedência.
        </p>

        <p style="margin: 0; font-size: 14px; color: #333333;">
          Aguardamos você,
        </p>
        <p style="margin: 4px 0 0 0; font-size: 14px; font-weight: 600; color: #8E2348;">
          Studio Cleusa
        </p>
      </td>
    </tr>

    <tr>
      <td style="padding: 14px 20px; text-align: center; background-color: #faf8f7; border-top: 1px solid #f0eae7; font-size: 11px; color: #888888;">
        Studio Cleusa &bull; Lembrete enviado conforme solicitado
      </td>
    </tr>

  </table>

</body>
</html>"""
    return corpo_texto, corpo_html


def salvar_preview_html(corpo_html: str, destino: str, assunto: str) -> str:
    pasta_preview = Path(__file__).resolve().parent
    caminho_arquivo = pasta_preview / "preview_email_agendamento.html"
    
    html_com_metadados = f"""
    <div style="background:#8E2348; color:#ffffff; padding:8px 14px; font-family:-apple-system, sans-serif; font-size:12px;">
      Prévia &bull; Para: {destino} &bull; Assunto: {assunto}
    </div>
    {corpo_html}
    """
    
    with open(caminho_arquivo, "w", encoding="utf-8") as f:
        f.write(html_com_metadados)
    
    try:
        webbrowser.open(caminho_arquivo.as_uri())
    except Exception:
        pass
        
    return str(caminho_arquivo)


def enviar_email(
    destino: str,
    assunto: str,
    corpo_texto: str,
    corpo_html: str | None = None,
    caminho_anexo: str | None = None,
    simular: bool = False,
) -> bool:
    config = obter_config_smtp()
    deve_simular = simular or config["simular"] or not config["usuario"] or not config["senha"]

    if deve_simular:
        print(f"\n[Prévia de E-mail]")
        print(f" -> Para: {destino}")
        print(f" -> Assunto: {assunto}")
        if corpo_html:
            caminho = salvar_preview_html(corpo_html, destino, assunto)
            print(f" -> Visualização aberta: {caminho}")
        else:
            print(corpo_texto)
        return True

    # Mensagem principal (multipart/alternative padrão sem anexos de imagem)
    if caminho_anexo and os.path.exists(caminho_anexo):
        msg_raiz = MIMEMultipart("mixed")
        msg_conteudo = MIMEMultipart("alternative")
        msg_conteudo.attach(MIMEText(corpo_texto, "plain", "utf-8"))
        if corpo_html:
            msg_conteudo.attach(MIMEText(corpo_html, "html", "utf-8"))
        msg_raiz.attach(msg_conteudo)

        try:
            with open(caminho_anexo, "rb") as anexo:
                part = MIMEBase("application", "octet-stream")
                part.set_payload(anexo.read())
                encoders.encode_base64(part)
                nome_anexo = os.path.basename(caminho_anexo)
                part.add_header("Content-Disposition", f'attachment; filename="{nome_anexo}"')
                msg_raiz.attach(part)
        except Exception:
            pass
    else:
        msg_raiz = MIMEMultipart("alternative")
        msg_raiz.attach(MIMEText(corpo_texto, "plain", "utf-8"))
        if corpo_html:
            msg_raiz.attach(MIMEText(corpo_html, "html", "utf-8"))

    # Auto-Submitted ou Reply-To repetido. O Gmail gera o Message-ID correto
    # e assina o e-mail (SPF/DKIM) sozinho.
    msg_raiz["From"] = email.utils.formataddr((config["remetente_nome"], config["usuario"]))
    msg_raiz["To"] = destino
    msg_raiz["Subject"] = assunto
    msg_raiz["Date"] = email.utils.formatdate(localtime=True)

    try:
        with smtplib.SMTP(config["host"], config["port"], timeout=20) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(config["usuario"], config["senha"])
            server.send_message(msg_raiz)
        print(f"E-mail enviado para: {destino}")
        return True
    except Exception as e:
        print(f"Erro no envio para {destino}: {e}")
        if corpo_html:
            salvar_preview_html(corpo_html, destino, assunto)
        return False