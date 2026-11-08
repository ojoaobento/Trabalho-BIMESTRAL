from core.email_codigo import _ENV, _config

print("Procurando .env em:", _ENV)
print("Existe:", _ENV.exists())

cfg = _config()
print("host:", cfg["host"], "| port:", cfg["port"])
print("usuario:", repr(cfg["usuario"]))
print("senha preenchida:", bool(cfg["senha"]), "| tamanho:", len(cfg["senha"]))
print("simular:", cfg["simular"])