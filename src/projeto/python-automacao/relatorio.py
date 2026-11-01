from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import os

def gerar_relatorio_pdf(nome_arquivo: str, dados: list) -> str:
    caminho = os.path.join("/tmp", nome_arquivo)
    c = canvas.Canvas(caminho, pagesize=letter)
    
    c.setFont("Helvetica-Bold", 16)
    c.drawString(100, 750, "Relatório de Agendamentos / Serviços")
    
    c.setFont("Helvetica", 12)
    y = 700
    for item in dados:
        c.drawString(100, y, f"- {item}")
        y -= 20
        if y < 50:
            c.showPage()
            y = 750
            
    c.save()
    return caminho