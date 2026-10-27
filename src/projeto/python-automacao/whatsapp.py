import requests

def enviar_whatsapp(numero: str, mensagem: str):
    # Exemplo genérico consumindo API do WhatsApp
    url = "https://api.exemplo.com/send-message"
    headers = {"Authorization": "Bearer SEU_TOKEN_AQUI"}
    payload = {
        "phone": numero,
        "message": mensagem
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        return response.status_code == 200
    except Exception as e:
        print(f"Erro ao enviar mensagem no WhatsApp: {e}")
        return False