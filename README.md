# Studio Cleusa - Sistema de Gestao e Agendamento

Sistema completo de agendamento e gerenciamento para clinicas de estetica, integrando backend **FastAPI**, aplicativos **Flutter** (Mobile Cliente e Web Admin), interface adicional em **Python (Flask)** e servico de **automacao de e-mails**.

---

## Funcionalidades

- **Backend (FastAPI)**:
  - API RESTful com documentacao interativa automatica (Swagger/OpenAPI).
  - Autenticacao e rotas protegidas via Bearer Token JWT e senhas criptografadas com bcrypt.
  - Operacoes CRUD completas para: Agendamentos, Servicos, Categorias, Clientes (com consentimento LGPD), Usuarios administradores, Disponibilidades semanais, Bloqueios pontuais de horarios e Feriados.
  - Endpoints de metricas e resumo para dashboard gerencial.
- **Aplicativo Cliente (Flutter Mobile/Web)**:
  - Consulta de servicos e horarios livres em tempo real.
  - Agendamento simplificado com identificacao e confirmacao.
- **Painel Administrativo (Flutter Web/Desktop)**:
  - Gestao visual completa de agendamentos, clientes, servicos, horarios e equipe.
- **Interface Adicional (Python / Flask)**:
  - Segunda interface administrativa desenvolvida em Flask, consumindo a mesma API centralizada em tempo real com paridade visual e funcional total em relacao ao Flutter Admin.
- **Servico de Automacao (Python)**:
  - Worker em segundo plano para envio automatico de e-mails transacionais (confirmacao e lembretes 24h antes do atendimento).

---

## Documentacao da API (FastAPI)

A API roda por padrao em `http://localhost:8000`. A documentacao interativa automatica fica disponivel em `/docs` (Swagger UI) e `/redoc` (ReDoc).

Rotas protegidas exigem o cabecalho HTTP: `Authorization: Bearer <token_jwt>`.

### 1. Autenticacao (`/auth`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/login` | Publico | Autentica usuario (username e password via form-data) e devolve o JWT. |
| `GET` | `/auth/me` | Protegido | Retorna o usuario atualmente autenticado. |

### 2. Agendamentos (`/agendamentos`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `POST` | `/agendamentos` | Publico | Cria novo agendamento com dados do cliente e servico. |
| `GET` | `/agendamentos` | Protegido | Lista agendamentos (suporta filtros `inicio`, `fim`, `cliente_id`). |
| `GET` | `/agendamentos/{id}` | Protegido | Consulta detalhes de um agendamento por ID. |
| `PATCH` | `/agendamentos/{id}` | Protegido | Remarca data/hora ou atualiza observacoes. |
| `PATCH` | `/agendamentos/{id}/status` | Protegido | Altera o status (`reservado`, `pendente`, `confirmado`, `concluido`, `cancelado`, `faltou`). |
| `DELETE` | `/agendamentos/{id}` | Protegido | Cancela e remove o agendamento. |
| `GET` | `/agendamentos/horarios-livres` | Publico | Consulta horarios livres informando parametro `data=YYYY-MM-DD`. |
| `GET` | `/agendamentos/feriados` | Publico | Consulta feriados nacionais do ano (`ano=YYYY`). |

### 3. Area da Cliente (`/agendamentos/acesso` e `/agendamentos/minhas`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `POST` | `/agendamentos/acesso/codigo` | Publico | Envia codigo de verificacao de 6 digitos por e-mail para a cliente. |
| `POST` | `/agendamentos/minhas` | Publico | Retorna os agendamentos da cliente via codigo ou token de sessao. |
| `PATCH` | `/agendamentos/minhas/{id}/cancelar` | Publico | Cancela agendamento pela cliente com antecedencia minima. |
| `PATCH` | `/agendamentos/minhas/lembretes` | Publico | Ativa ou desativa recebimento de lembretes da cliente. |

### 4. Servicos (`/servicos`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/servicos` | Protegido | Lista todos os servicos (ativos e inativos). |
| `GET` | `/servicos/ativos` | Publico | Lista apenas servicos com status ativo. |
| `GET` | `/servicos/{id}` | Publico | Consulta dados de um servico. |
| `POST` | `/servicos` | Protegido | Cria novo servico (`categoria_id`, `nome`, `preco`, `duracao_minutos`). |
| `PATCH` | `/servicos/{id}` | Protegido | Atualiza parcialmente dados ou status ativo do servico. |
| `DELETE` | `/servicos/{id}` | Protegido | Exclui o servico (caso nao possua agendamentos vinculados). |

### 5. Categorias (`/categorias`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/categorias` | Publico | Lista categorias de servicos. |
| `GET` | `/categorias/{id}` | Publico | Consulta categoria por ID. |
| `POST` | `/categorias` | Protegido | Cria nova categoria. |
| `PATCH` | `/categorias/{id}` | Protegido | Altera nome ou status ativo. |
| `DELETE` | `/categorias/{id}` | Protegido | Exclui a categoria. |

### 6. Clientes (`/clientes`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/clientes` | Protegido | Lista todos os clientes cadastrados. |
| `GET` | `/clientes/{id}` | Protegido | Consulta cliente por ID. |
| `POST` | `/clientes` | Protegido | Cadastra cliente (`nome`, `telefone`, `email`, `consentimento: true`). |
| `PATCH` | `/clientes/{id}` | Protegido | Atualiza dados ou preferencia de lembretes. |
| `DELETE` | `/clientes/{id}` | Protegido | Exclui o cliente. |

### 7. Usuarios Administrativos (`/usuarios`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/usuarios` | Protegido | Lista usuarios administrativos. |
| `GET` | `/usuarios/{id}` | Protegido | Consulta usuario por ID. |
| `POST` | `/usuarios` | Protegido | Cria usuario (senha criptografada com bcrypt). |
| `PATCH` | `/usuarios/{id}` | Protegido | Atualiza nome, e-mail, senha ou status ativo. |
| `DELETE` | `/usuarios/{id}` | Protegido | Exclui usuario (impede autoexclusao). |

### 8. Disponibilidades e Bloqueios (`/disponibilidades` e `/bloqueios`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/disponibilidades` | Protegido | Lista os blocos de atendimento semanal. |
| `POST` | `/disponibilidades` | Protegido | Cria horario semanal (`dia_semana`, `hora_inicio`, `hora_fim`). |
| `PATCH` | `/disponibilidades/{id}` | Protegido | Altera horario ou status do bloco semanal. |
| `DELETE` | `/disponibilidades/{id}` | Protegido | Remove bloco semanal. |
| `GET` | `/bloqueios` | Protegido | Lista bloqueios pontuais de horarios. |
| `POST` | `/bloqueios` | Protegido | Cria bloqueio pontual (`data`, `hora_inicio`, `hora_fim`, `motivo`). |
| `DELETE` | `/bloqueios/{id}` | Protegido | Remove bloqueio pontual (desbloqueia o horario). |

### 9. Lembretes (`/lembretes`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/lembretes` | Protegido | Lista lembretes gerados no sistema. |
| `GET` | `/lembretes/pendentes` | Protegido | Lista lembretes aguardando envio. |
| `PATCH` | `/lembretes/{id}` | Protegido | Altera data de envio ou tipo do lembrete. |
| `PATCH` | `/lembretes/{id}/enviado` | Protegido | Marca lembrete manualmente como enviado. |
| `DELETE` | `/lembretes/{id}` | Protegido | Exclui lembrete. |

### 10. Dashboard (`/dashboard`)
| Metodo | Rota | Acesso | Descricao |
| :--- | :--- | :--- | :--- |
| `GET` | `/dashboard/resumo` | Protegido | Retorna contadores de hoje, clientes, servicos ativos, distribuicao mensal por status e desempenho semanal (Seg-Dom). |

---

## Pre-requisitos

- **Python** 3.10 ou superior
- **Flutter SDK** 3.x e Dart
- **Git**
- Navegador Web moderno (Google Chrome / Edge) ou Emulador/Dispositivo Android
- Banco de dados PostgreSQL (ex.: Supabase) ou SQLite configurado

---

## Estrutura de Pastas

```text
Trabalho-BIMESTRAL/
├── README.md
├── requirements.txt
└── src/
    └── projeto/
        ├── backend/            # API RESTful em FastAPI (rotas, models, schemas, servicos)
        ├── admin/main/         # Painel Administrativo em Flutter (Web/Desktop)
        ├── flutter/flutter-app # Aplicativo do Cliente em Flutter (Mobile/Web)
        ├── interface-python/   # Interface Web Administrativa em Python (Flask)
        └── python-automacao/   # Servico de automacao e envio de e-mails/lembretes
```

---

## Como Compilar / Instalar Dependencias

### 1. Dependencias em Python (Backend, Flask e Automacao)
Na raiz do projeto, crie e ative um ambiente virtual e instale as dependencias:

```bash
# Criar ambiente virtual
python -m venv venv

# Ativar ambiente virtual
# Windows (PowerShell):
.\venv\Scripts\Activate.ps1
# Windows (CMD):
venv\Scripts\activate.bat
# Linux / macOS:
source venv/bin/activate

# Instalar pacotes
pip install -r requirements.txt
```

### 2. Dependencias em Flutter (App Cliente e Painel Admin)
Execute o download das dependencias nas pastas dos dois projetos Flutter:

```bash
# Aplicativo do Cliente
cd src/projeto/flutter/flutter-app
flutter pub get
cd ../../../

# Painel Admin em Flutter
cd src/projeto/admin/main
flutter pub get
cd ../../../
```

---

## Como Executar

### 1. Backend (FastAPI)
Certifique-se de que o arquivo `.env` dentro de `src/projeto/backend/` esteja configurado com a URL do banco e chave JWT.

```bash
cd src/projeto/backend
uvicorn main:app --reload --port 8000
```
- **API Base:** `http://localhost:8000`
- **Documentacao Swagger:** `http://localhost:8000/docs`

### 2. Interface Web em Python (Flask)
Abra um novo terminal (com o backend rodando):

```bash
cd src/projeto/interface-python
python app.py
```
- **Acesso Web:** `http://localhost:5000`

### 3. Aplicativo do Cliente (Flutter)
Em outro terminal:

```bash
cd src/projeto/flutter/flutter-app
flutter run
# Ou para rodar diretamente no navegador:
flutter run -d chrome
```

### 4. Painel Admin em Flutter (Opcional)
```bash
cd src/projeto/admin/main
flutter run -d chrome
```

### 5. Servico de Automacao de E-mails (Opcional)
```bash
cd src/projeto/python-automacao
python automacao_lembretes.py
```
