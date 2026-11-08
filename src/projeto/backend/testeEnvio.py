import smtplib
from core.email_codigo import _config

cfg = _config()
destino = "joaovictorbento.s.b@gmail.com"

try:
    with smtplib.SMTP(cfg["host"], cfg["port"], timeout=20) as s:
        s.set_debuglevel(1)  
        s.ehlo()
        s.starttls()
        s.ehlo()
        s.login(cfg["usuario"], cfg["senha"])
        s.sendmail(
            cfg["usuario"],
            destino,
            f"Subject: Teste\nFrom: {cfg['usuario']}\nTo: {destino}\n\nFuncionou!",
        )
    print("\n>>> ENVIADO COM SUCESSO")
except Exception as e:
    print(f"\n>>> ERRO: {type(e).__name__}: {e}")