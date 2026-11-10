# Automacao de e-mails

[Voltar ao README principal](../../../README.md) | [Documentacao da API](../backend/README.md)

Worker Python que consulta no banco a fila de lembretes e envia e-mails de confirmacao e lembretes de atendimento. Diferentemente dos aplicativos web/mobile, ele integra-se diretamente ao banco configurado pelo backend (nao faz chamadas HTTP a API).

## O que faz

- Busca lembretes ainda nao enviados cujo `enviar_em` ja chegou.
- Envia confirmacoes e lembretes de 24 horas, usando os templates de `email_service.py`.
- Nao envia lembretes de 24 horas quando a cliente desativou essa preferencia.
- Ignora agendamentos cancelados ou clientes sem e-mail e marca esses itens como processados.
- Suporta modo de simulacao e disparos/testes manuais.

## Preparacao

Na raiz do repositorio:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

A automacao carrega as configuracoes de `src/projeto/backend/.env` quando esse arquivo existe. Configure ao menos `DATABASE_URL` para apontar ao mesmo banco usado pela API. Para envio SMTP real, configure:

| Variavel | Descricao | Padrao |
| :--- | :--- | :--- |
| `SMTP_HOST` | Servidor SMTP | `smtp.gmail.com` |
| `SMTP_PORT` | Porta SMTP | `587` |
| `SMTP_USUARIO` | Conta remetente | Vazio |
| `SMTP_SENHA` | Credencial SMTP | Vazio |
| `SMTP_REMETENTE_NOME` | Nome exibido no remetente | `Studio Cleusa` |
| `SMTP_SIMULAR` | Ativa simulacao (`true`, `1`, `sim` ou `yes`) | `false` |

Nao coloque senhas ou tokens no README, no codigo ou no controle de versao. Com credenciais SMTP ausentes, o envio e tratado em modo de simulacao pelo servico de e-mail.

## Execucao

Os comandos podem ser executados a partir da raiz:

```powershell
# Uma consulta a fila e encerramento (tambem e o comportamento padrao)
python src\projeto\python-automacao\automacao_lembretes.py --once

# Monitoramento continuo, verificando a cada 15 segundos
python src\projeto\python-automacao\automacao_lembretes.py --loop

# Ajustar intervalo do monitoramento
python src\projeto\python-automacao\automacao_lembretes.py --loop --intervalo 30

# Simular envio e abrir a visualizacao HTML local
python src\projeto\python-automacao\automacao_lembretes.py --once --simular

# Enviar teste ou disparar para um agendamento especifico
python src\projeto\python-automacao\automacao_lembretes.py --test-email destinatario@example.com --simular
python src\projeto\python-automacao\automacao_lembretes.py --disparar-confirmacao 123 --simular
python src\projeto\python-automacao\automacao_lembretes.py --disparar-lembrete 123 --simular
python src\projeto\python-automacao\automacao_lembretes.py --disparar-lembrete-24h 123 --simular

# Opcoes disponiveis
python src\projeto\python-automacao\automacao_lembretes.py --help
```

Para operar continuamente em producao, execute `--loop` sob um supervisor de processos e evite iniciar varias instancias concorrentes sobre a mesma fila. Teste primeiro com `--simular`.

## Arquivos

- `automacao_lembretes.py`: leitura da fila, templates selecionados pelo tipo de lembrete, modos `--once`, `--loop` e disparo manual.
- `email_service.py`: configuracao SMTP, templates HTML/texto e modo de simulacao.
- `preview_email_agendamento.html`: visualizacao local de modelo de e-mail.
- `relatorio.py`: helper independente para gerar PDF a partir de uma lista de dados.
- `assets/`: imagens de marca usadas nos modelos.

O helper de PDF depende de `reportlab`, que nao esta listado em `requirements.txt` na raiz; instale essa dependencia separadamente caso utilize `relatorio.py`.
