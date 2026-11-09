# Interface Web Completa em Python (Flask) - Studio Cleusa
## Trabalho Bimestral: FastAPI + Flutter + Python Web

Esta aplicação web desenvolvida em **Python (Flask)** cumpre a exigência do **Item 3 do Enunciado**:
> *"Além do aplicativo Flutter, você deverá desenvolver uma segunda interface (web ou desktop) utilizando Python (por exemplo, com Tkinter, PyQt, ou Flask para web). Essa interface também deve consumir a mesma API FastAPI criada no backend."*

---

### Módulos e Rotas em Paridade Total com a Tela Admin

Esta interface implementa o consumo completo de todos os roteadores do backend FastAPI:

| Módulo | Endpoints FastAPI Consumidos | Funcionalidade no Flask |
| :--- | :--- | :--- |
| **Autenticação** | `POST /auth/login`, `GET /auth/me` | Login com Token JWT e sessão autenticada. |
| **Serviços** | `GET /servicos`, `POST /servicos`, `PUT /servicos/{id}`, `DELETE /servicos/{id}` | CRUD completo de serviços com preços e duração. |
| **Agendamentos**| `GET /agendamentos`, `POST /agendamentos`, `PATCH /agendamentos/{id}/status`, `DELETE /agendamentos/{id}` | Listagem, novo agendamento, mudança de status e cancelamento. |
| **Categorias** | `GET /categorias`, `POST /categorias`, `PUT /categorias/{id}` | Gestão de categorias de serviços. |
| **Clientes** | `GET /clientes`, `POST /clientes`, `PUT /clientes/{id}`, `DELETE /clientes/{id}` | Gestão de clientes e preferência de lembretes. |
| **Disponibilidade** | `GET /disponibilidades`, `POST /disponibilidades`, `DELETE /disponibilidades/{id}` | Turnos semanais de funcionamento. |
| **Bloqueios** | `GET /bloqueios`, `POST /bloqueios`, `DELETE /bloqueios/{id}` | Bloqueio de horários específicos e intervalos de folga. |
| **Lembretes** | `GET /lembretes`, `PATCH /lembretes/{id}/enviado`, `DELETE /lembretes/{id}` | Acompanhamento e disparo de lembretes automáticos. |
| **Usuários** | `GET /usuarios`, `POST /usuarios`, `PUT /usuarios/{id}`, `DELETE /usuarios/{id}` | Gestão de administradores com senhas criptografadas (bcrypt). |

---

### Sincronização em Tempo Real (FastAPI + Flutter + Flask)

- **Flutter (Mobile / Cliente)**: Agenda horários pelo app no smartphone.
- **Flutter (Admin Web)**: Painel gerencial em Dart/Flutter.
- **Python (Flask Web)**: Interface adicional em Python para gestão e validação do backend.
- **FastAPI (Backend Centralizado)**: Todas as alterações realizadas no Flutter refletem imediatamente no Flask e vice-versa, pois compartilham a mesma base de dados.

---

### Como Executar

#### 1. Iniciar a API FastAPI
```bash
cd src/projeto/backend
uvicorn main:app --reload --port 8000
```

#### 2. Iniciar a Interface Web em Flask
```bash
cd src/projeto/interface-python
python app.py
```

Acesse no navegador:
👉 **http://localhost:5000**

#### 3. Credenciais para Teste (Usuários Cadastrados no Banco)
- **E-mail:** `joao@gmail.com` | **Senha:** `123456`
- **E-mail:** `junji@gmail.com` | **Senha:** `123456`
- **E-mail:** `gabriel@gmail.com` | **Senha:** `123456`
