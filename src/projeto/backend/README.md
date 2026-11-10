# Backend e documentacao da API

[Voltar ao README principal](../../../README.md)

Backend REST do Studio Cleusa, implementado com FastAPI, SQLAlchemy e Pydantic. Os aplicativos Flutter, o painel Flask e os fluxos publicos do aplicativo cliente consomem esta API.

## Executar localmente

Requisitos: Python 3.10 ou superior, dependencias da raiz instaladas e um banco PostgreSQL acessivel.

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
cd src\projeto\backend
uvicorn main:app --reload --port 8000
```

Configure o arquivo `.env` deste diretorio antes de iniciar. Nao versionar credenciais.

| Variavel | Uso |
| :--- | :--- |
| `DATABASE_URL` | URL de conexao usada pelo SQLAlchemy. |
| `JWT_SECRET_KEY` | Chave para assinar os tokens de administrador. |
| `JWT_EXPIRE_MINUTES` | Validade do token de administrador; padrao de 60 minutos. |
| `ACESSO_CLIENTE_SECRET` | Segredo obrigatorio para assinar sessoes de cliente. |
| `CANCELAMENTO_ANTECEDENCIA_HORAS` | Antecedencia minima para cancelamento pela cliente; padrao de 2 horas. |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USUARIO`, `SMTP_SENHA` | Configuracao de envio de e-mail e codigos de acesso. |
| `SMTP_REMETENTE_NOME`, `SMTP_SIMULAR` | Nome exibido no remetente e modo de simulacao de e-mail. |

O backend nao possui prefixo `/api`: a base local e `http://localhost:8000`. O Swagger em `/docs`, o ReDoc em `/redoc` e o esquema OpenAPI em `/openapi.json` sao gerados pelo FastAPI e devem ser usados para conferir os tipos completos em execucao.

## Contrato geral

- Corpos JSON usam `Content-Type: application/json`, exceto o login de administrador, que recebe formulario (`application/x-www-form-urlencoded`).
- Datas usam `AAAA-MM-DD`; horarios, `HH:MM` ou `HH:MM:SS`; timestamps seguem ISO 8601.
- IDs nos caminhos sao inteiros.
- Exclusoes retornam `204 No Content`.
- Falhas de validacao do FastAPI retornam `422` com detalhes em `detail`. Recursos ausentes normalmente retornam `404`; erros de autenticacao de administrador retornam `401`.

### Autenticacao administrativa

`POST /auth/login` recebe `username` (e-mail do usuario) e `password` como campos de formulario. A resposta contem `access_token` e `token_type`. Nas rotas protegidas envie:

```http
Authorization: Bearer <access_token>
```

O token de administrador tem validade configurada por `JWT_EXPIRE_MINUTES`. A conta precisa estar ativa. `GET /auth/me` retorna o usuario autenticado.

As rotas publicas de cliente nao usam o JWT administrativo. Elas usam codigo enviado por e-mail ou token de sessao no corpo da requisicao.

## Endpoints

`Publico` nao exige autenticacao administrativa. `Bearer` exige o token descrito acima.

### Autenticacao

| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/login` | Publico | Autentica o usuario e emite token Bearer. |
| `GET` | `/auth/me` | Bearer | Retorna o usuario autenticado. |

### Agendamentos

| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `POST` | `/agendamentos` | Publico | Cria agendamento; retorna um token de cliente apenas quando cria uma cliente nova. |
| `GET` | `/agendamentos` | Bearer | Lista agendamentos; aceita `cliente_id` ou os filtros `inicio` e `fim`. |
| `GET` | `/agendamentos/horarios-livres?data=AAAA-MM-DD` | Publico | Lista horarios com disponibilidade para a data. |
| `GET` | `/agendamentos/feriados?ano=AAAA` | Publico | Lista feriados do ano; por padrao usa o ano atual. |
| `GET` | `/agendamentos/{agendamento_id}` | Bearer | Consulta um agendamento. |
| `PATCH` | `/agendamentos/{agendamento_id}` | Bearer | Atualiza parcialmente data, hora e/ou observacoes. |
| `PATCH` | `/agendamentos/{agendamento_id}/status` | Bearer | Atualiza o status do agendamento. |
| `DELETE` | `/agendamentos/{agendamento_id}` | Bearer | Exclui o registro do agendamento. |

Consulta de agendamentos aceita `cliente_id` ou o par `inicio` e `fim` (datetimes); sem filtros, lista todos. O corpo de criacao segue este formato:

```json
{
  "cliente": {
    "nome": "Ana Souza",
    "telefone": "44912345678",
    "email": "ana@example.com",
    "aceita_lembretes": true,
    "consentimento": true
  },
  "servico_id": 1,
  "data": "2026-11-09",
  "hora": "09:00",
  "observacoes": "Preferencia pela manha"
}
```

`nome` tem de 2 a 100 caracteres; telefone deve conter 11 digitos; `consentimento` deve ser `true`; e-mail pode ser nulo. `observacoes` e opcional (maximo 500 caracteres). O servico deve existir e o horario precisa estar disponivel. A resposta publica inclui `id`, inicio/fim, status, servico e `token_acesso` (nulo para clientes ja cadastradas).

Status possiveis: `reservado`, `pendente`, `confirmado`, `cancelado`, `concluido` e `faltou`. A resposta administrativa inclui cliente, servico, valor cobrado, observacoes e datas.

Exemplo de disponibilidade:

```http
GET /agendamentos/horarios-livres?data=2026-11-09
```

A resposta e uma lista com `horario` e `minutos_livres`.

### Acesso da cliente aos proprios agendamentos

Todas estas rotas sao publicas em relacao ao Bearer administrativo, mas exigem os dados ou o token de sessao da cliente.

| Metodo | Rota | Corpo / resultado |
| :--- | :--- | :--- |
| `POST` | `/agendamentos/acesso/codigo` | Envia `email` e `telefone` opcional. A resposta generica e `202 Accepted`; o codigo dura 10 minutos, pode ser solicitado novamente apos 60 segundos e permite ate 5 tentativas. |
| `POST` | `/agendamentos/minhas` | Recebe `email`, `codigo` e `telefone` opcional, ou somente `token`; retorna token, dados da cliente e agendamentos. |
| `POST` | `/agendamentos/minhas/{agendamento_id}/cancelar` | Recebe `{"token":"..."}`; so permite cancelar agendamentos `pendente` ou `confirmado`, respeitando a antecedencia configurada. |
| `PATCH` | `/agendamentos/minhas/telefone` | Recebe `token` e novo `telefone`; devolve um token renovado e o telefone. |
| `PATCH` | `/agendamentos/minhas/lembretes` | Recebe `token` e `aceita_lembretes` booleano; desativar remove lembretes 24h ainda nao enviados. |

Exemplo para pedir codigo:

```json
{"email":"ana@example.com","telefone":"44912345678"}
```

Exemplo para consultar a agenda apos receber o codigo:

```json
{"email":"ana@example.com","telefone":"44912345678","codigo":"123456"}
```

O token da cliente tem validade de 30 dias e deixa de ser valido se seu e-mail ou telefone mudar. Agendamentos `reservado` nao aparecem na listagem da cliente.

### Servicos

| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/servicos` | Bearer | Lista servicos ativos e inativos. |
| `GET` | `/servicos/ativos` | Publico | Lista servicos ativos. |
| `GET` | `/servicos/categoria?categoria_id={id}` | Publico | Filtra por categoria. |
| `GET` | `/servicos/nome/{servico_nome}` | Publico | Busca pelo nome. |
| `GET` | `/servicos/{servico_id}` | Publico | Consulta por ID. |
| `POST` | `/servicos` | Bearer | Cria servico. |
| `PATCH` | `/servicos/{servico_id}` | Bearer | Atualiza parcialmente. |
| `PUT` | `/servicos/{servico_id}` | Bearer | Substitui os campos do servico. |
| `DELETE` | `/servicos/{servico_id}` | Bearer | Exclui servico, quando permitido pelas relacoes. |

Campos de criacao/atualizacao completa: `categoria_id`, `nome`, `descricao`, `preco`, `duracao_minutos` e `ativo`. Preco deve ser maior que zero; nome e descricao aceitam de 2 a 100 caracteres. O PATCH aceita apenas os campos a alterar.

### Categorias

| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/categorias` | Publico | Lista categorias. |
| `GET` | `/categorias/{categoria_id}` | Publico | Consulta por ID. |
| `POST` | `/categorias` | Bearer | Cria com `nome`. |
| `PATCH` | `/categorias/{categoria_id}` | Bearer | Atualiza `nome` e/ou `ativo`. |
| `PUT` | `/categorias/{categoria_id}` | Bearer | Atualiza `nome` e `ativo`. |
| `DELETE` | `/categorias/{categoria_id}` | Bearer | Exclui categoria. |

### Clientes

Todas as rotas deste grupo exigem Bearer.

| Metodo | Rota | Descricao |
| :--- | :--- | :--- |
| `GET` | `/clientes` | Lista clientes. |
| `GET` | `/clientes/{cliente_id}` | Consulta por ID. |
| `GET` | `/clientes/telefone/{telefone}` | Consulta por telefone. |
| `POST` | `/clientes` | Cria cliente (nome, telefone, email opcional, `aceita_lembretes` e `consentimento: true`). |
| `PATCH` | `/clientes/{cliente_id}` | Atualizacao parcial. |
| `PUT` | `/clientes/{cliente_id}` | Atualizacao completa. |
| `DELETE` | `/clientes/{cliente_id}` | Exclui cliente. |

### Usuarios administrativos

Todas as rotas deste grupo exigem Bearer.

| Metodo | Rota | Descricao |
| :--- | :--- | :--- |
| `GET` | `/usuarios` | Lista usuarios sem retornar senhas. |
| `GET` | `/usuarios/{usuario_id}` | Consulta por ID. |
| `GET` | `/usuarios/email/{email}` | Consulta por e-mail. |
| `POST` | `/usuarios` | Cria usuario com `nome`, `email`, `senha` e `ativo`. |
| `PATCH` | `/usuarios/{usuario_id}` | Atualiza parcialmente. |
| `PUT` | `/usuarios/{usuario_id}` | Atualiza nome, e-mail, senha e estado ativo. |
| `DELETE` | `/usuarios/{usuario_id}` | Exclui usuario; nao permite excluir o proprio usuario autenticado. |

As senhas sao armazenadas com hash. Os schemas de resposta nao incluem senha.

### Disponibilidades e bloqueios

Todas as rotas destes grupos exigem Bearer.

| Metodo | Rota | Descricao |
| :--- | :--- | :--- |
| `GET` | `/disponibilidades` | Lista horarios semanais. |
| `GET` | `/disponibilidades/dia_semana?dia_semana=0` | Filtra pelo dia (0 segunda-feira, 6 domingo). |
| `GET` | `/disponibilidades/{disponibilidade_id}` | Consulta por ID. |
| `POST` | `/disponibilidades` | Cria com `dia_semana`, `hora_inicio`, `hora_fim` e `ativo`. |
| `PATCH` / `PUT` | `/disponibilidades/{disponibilidade_id}` | Atualizacao parcial ou completa. |
| `DELETE` | `/disponibilidades/{disponibilidade_id}` | Exclui disponibilidade. |
| `GET` | `/bloqueios` | Lista bloqueios pontuais. |
| `POST` | `/bloqueios` | Cria bloqueio com `data`, `hora_inicio`, `hora_fim` e `motivo` opcional. |
| `DELETE` | `/bloqueios/{bloqueio_id}` | Remove bloqueio. |

Disponibilidades usam `dia_semana` de 0 a 6. Um bloqueio cujo fim nao seja posterior ao inicio retorna `400`; conflito com outro bloqueio retorna `409`.

### Lembretes

Todas as rotas exigem Bearer. Tipos aceitos: `confirmacao` e `lembrete_24h`.

| Metodo | Rota | Descricao |
| :--- | :--- | :--- |
| `GET` | `/lembretes` | Lista lembretes. |
| `GET` | `/lembretes/pendentes` | Lista pendentes de envio. |
| `GET` | `/lembretes/{lembrete_id}` | Consulta por ID. |
| `POST` | `/lembretes` | Cria com `agendamento_id`, `enviar_em`, `tipo` e `servico_id` opcional. |
| `PATCH` / `PUT` | `/lembretes/{lembrete_id}` | Atualizacao parcial ou completa. |
| `PATCH` | `/lembretes/{lembrete_id}/enviado` | Marca como enviado. |
| `DELETE` | `/lembretes/{lembrete_id}` | Exclui lembrete. |

### Dashboard

| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/dashboard/resumo` | Bearer | Retorna contagem de agendamentos de hoje, clientes, servicos ativos, distribuicao mensal por status e total semanal por dia (segunda a domingo). |

## Integracao pelos aplicativos

- O Flutter cliente utiliza endpoints publicos de categorias, servicos ativos, horarios livres e criacao de agendamento; o fluxo "Meus agendamentos" usa codigo/token de cliente.
- O Flutter Admin autentica em `/auth/login` e envia Bearer nas operacoes administrativas.
- O painel Flask faz a mesma autenticacao e consome os endpoints protegidos; sua URL de API e configurada por `API_BASE_URL`.
- A automacao Python acessa o banco configurado no backend para processar a fila de lembretes.

Para contratos de resposta e validacoes completas, consulte `/docs` com o servidor em execucao; este documento descreve os endpoints implementados no codigo.
