# Interface administrativa Python

[Voltar ao README principal](../../../README.md) | [Documentacao da API](../backend/README.md)

Painel web administrativo em Flask/Jinja2 que consome a mesma API FastAPI usada pelo Flutter Admin. O Flask gerencia a navegacao, apresenta os dados em paginas HTML e guarda o token Bearer de administrador na sessao do servidor.

## Funcionalidades

- Login e encerramento de sessao.
- Visao geral com indicadores do dashboard.
- Gestao de agendamentos, clientes, servicos e categorias.
- Gestao de usuarios, disponibilidades, bloqueios e lembretes.
- Formularios HTML enviam alteracoes para os endpoints da API; o painel nao acessa o banco diretamente.

## Requisitos e configuracao

Requer Python 3.10 ou superior e as dependencias declaradas em `requirements.txt` na raiz. O backend precisa estar acessivel e a conta administrativa deve existir e estar ativa.

| Variavel | Uso | Padrao |
| :--- | :--- | :--- |
| `API_BASE_URL` | URL base do backend FastAPI | `http://127.0.0.1:8000` |
| `FLASK_SECRET_KEY` | Chave usada para assinar a sessao Flask | Valor de desenvolvimento definido no codigo |
| `PORT` | Porta HTTP do painel | `5000` |

Defina uma `FLASK_SECRET_KEY` exclusiva fora do desenvolvimento local. Nao publique a chave de sessao nem use o valor padrao em producao.

## Iniciar localmente

Com o backend em execucao na porta 8000, a partir da raiz do repositorio:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python src\projeto\interface-python\app.py
```

Abra `http://localhost:5000` e entre com as credenciais de um usuario administrativo. Para outro endereco de API ou porta do painel:

```powershell
$env:API_BASE_URL = "http://127.0.0.1:8000"
$env:PORT = "5000"
$env:FLASK_SECRET_KEY = "defina-uma-chave-local-segura"
python src\projeto\interface-python\app.py
```

## Organizacao

- `app.py`: aplicacao Flask, autenticacao, cliente HTTP da API e rotas de paginas/operacoes.
- `templates/`: layouts e paginas Jinja2 por funcionalidade.

Rotas administrativas do Flask exigem sessao iniciada no navegador. Se a API responder `401`, a sessao e limpa e o painel solicita novo login. Consulte [a documentacao da API](../backend/README.md) para endpoints, formatos de dados e autenticacao Bearer.
