from flask import Flask, render_template, request, redirect, url_for, flash, session
from functools import wraps
import requests
import os
import re
from datetime import datetime, timezone, timedelta

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "studiocleusa_secret_key_bimestral_2026")

API_BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")


class ApiException(Exception):
    def __init__(self, status_code: int, mensagem: str):
        super().__init__(mensagem)
        self.status_code = status_code
        self.mensagem = mensagem


class SessaoExpiradaException(Exception):
    pass


def extrair_mensagem_erro(dados) -> str:
    if isinstance(dados, dict) and dados.get("detail") is not None:
        detail = dados["detail"]
        if isinstance(detail, str):
            return detail
        if isinstance(detail, list) and len(detail) > 0 and isinstance(detail[0], dict):
            primeiro = detail[0]
            loc = primeiro.get("loc")
            local = loc[-1] if isinstance(loc, list) and len(loc) > 0 else "campo"
            msg = primeiro.get("msg", "valor inválido")
            return f"{local}: {msg}"
    return "Erro inesperado. Tente novamente."


def api_call(method: str, path: str, params: dict = None, json_data: dict = None, form_data: dict = None, auth: bool = True):
    headers = {}
    if auth and session.get("token"):
        headers["Authorization"] = f"Bearer {session['token']}"

    url = f"{API_BASE_URL}{path}"
    try:
        resp = requests.request(
            method=method,
            url=url,
            params=params,
            json=json_data,
            data=form_data,
            headers=headers,
            timeout=10,
        )
    except requests.exceptions.RequestException:
        raise ApiException(0, "Sem conexão com o servidor.")

    dados = None
    if resp.content:
        try:
            dados = resp.json()
        except ValueError:
            dados = None

    if 200 <= resp.status_code < 300:
        return dados

    if resp.status_code == 401 and auth:
        session.clear()
        raise SessaoExpiradaException()

    raise ApiException(resp.status_code, extrair_mensagem_erro(dados))


def login_obrigatorio(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get("token"):
            return redirect(url_for("login"))
        try:
            return f(*args, **kwargs)
        except SessaoExpiradaException:
            flash("Sua sessão expirou. Entre novamente.", "erro")
            return redirect(url_for("login"))
    return decorated_function


# ==========================================
# FILTROS DE FORMATAÇÃO JINJA2 (IDÊNTICOS AO FLUTTER)
# ==========================================
@app.template_filter("moeda")
def filtro_moeda(valor):
    try:
        v = float(valor or 0)
    except (ValueError, TypeError):
        v = 0.0
    inteiro, decimal = f"{v:.2f}".split(".")
    inteiro_formatado = re.sub(r"\B(?=(\d{3})+(?!\d))", ".", inteiro)
    return f"R$ {inteiro_formatado},{decimal}"


@app.template_filter("duracao_texto")
def filtro_duracao(minutos):
    try:
        m = int(minutos or 0)
    except (ValueError, TypeError):
        return "0 min"
    if m < 60:
        return f"{m} min"
    h = m // 60
    r = m % 60
    return f"{h}h" if r == 0 else f"{h}h {r}min"


@app.template_filter("telefone_br")
def filtro_telefone_br(telefone):
    d = re.sub(r"\D", "", str(telefone or ""))
    if len(d) == 11:
        return f"({d[:2]}) {d[2:7]}-{d[7:]}"
    if len(d) == 10:
        return f"({d[:2]}) {d[2:6]}-{d[6:]}"
    return telefone or "—"


def _parse_iso(valor):
    if not valor:
        return None
    try:
        texto = str(valor).replace("Z", "+00:00")
        dt = datetime.fromisoformat(texto)
        if dt.tzinfo is not None:
            dt = dt.astimezone()
        return dt
    except ValueError:
        return None


@app.template_filter("data_br")
def filtro_data_br(valor):
    dt = _parse_iso(valor)
    if not dt:
        return "—"
    return dt.strftime("%d/%m/%Y")


@app.template_filter("hora_br")
def filtro_hora_br(valor):
    dt = _parse_iso(valor)
    if not dt:
        texto = str(valor or "")
        return texto[:5] if len(texto) >= 5 else "—"
    return dt.strftime("%H:%M")


@app.template_filter("data_hora_br")
def filtro_data_hora_br(valor):
    dt = _parse_iso(valor)
    if not dt:
        return "—"
    return dt.strftime("%d/%m/%Y %H:%M")


@app.template_filter("data_iso_input")
def filtro_data_iso_input(valor):
    dt = _parse_iso(valor)
    if not dt:
        return ""
    return dt.strftime("%Y-%m-%d")


# ==========================================
# AUTENTICAÇÃO
# ==========================================
@app.route("/login", methods=["GET", "POST"])
def login():
    if session.get("token") and request.method == "GET":
        return redirect(url_for("visao_geral"))

    erro_login = None
    email_digitado = ""

    if request.method == "POST":
        email_digitado = request.form.get("email", "").strip()
        senha = request.form.get("senha", "")

        if not email_digitado or not senha:
            erro_login = "Preencha e-mail e senha."
        else:
            try:
                dados = api_call(
                    "POST",
                    "/auth/login",
                    form_data={"username": email_digitado, "password": senha},
                    auth=False,
                )
                session["token"] = dados["access_token"]
                return redirect(url_for("visao_geral"))
            except ApiException as e:
                erro_login = e.mensagem

    return render_template("login.html", erro_login=erro_login, email_digitado=email_digitado)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/")
def index():
    if not session.get("token"):
        return redirect(url_for("login"))
    return redirect(url_for("visao_geral"))


# ==========================================
# 0. VISÃO GERAL (/visao-geral)
# ==========================================
@app.route("/visao-geral")
@login_obrigatorio
def visao_geral():
    dados = None
    erro = None
    try:
        dados = api_call("GET", "/dashboard/resumo")
    except ApiException as e:
        erro = e.mensagem

    return render_template(
        "visao_geral.html",
        pagina_ativa="visao_geral",
        titulo_pagina="Visão Geral",
        dados=dados or {},
        erro=erro,
    )


# ==========================================
# 1. SERVIÇOS (/servicos)
# ==========================================
@app.route("/servicos")
@login_obrigatorio
def listar_servicos():
    servicos = []
    categorias = []
    erro = None
    busca = request.args.get("busca", "").strip()

    try:
        servicos = api_call("GET", "/servicos") or []
        categorias = api_call("GET", "/categorias") or []
    except ApiException as e:
        erro = e.mensagem

    mapa_categorias = {c["id"]: c["nome"] for c in categorias}
    for s in servicos:
        cat_obj = s.get("categoria")
        cat_id = s.get("categoria_id") or (cat_obj.get("id") if isinstance(cat_obj, dict) else None)
        s["categoria_id_resolvido"] = cat_id
        s["nome_categoria"] = mapa_categorias.get(cat_id, f"#{cat_id}")

    return render_template(
        "servicos/listar.html",
        pagina_ativa="servicos",
        titulo_pagina="Serviços",
        servicos=servicos,
        categorias=categorias,
        erro=erro,
        busca=busca,
    )


@app.route("/servicos/salvar", methods=["POST"])
@login_obrigatorio
def salvar_servico():
    servico_id = request.form.get("servico_id", "").strip()
    categoria_id = request.form.get("categoria_id", "").strip()
    nome = request.form.get("nome", "").strip()
    descricao = request.form.get("descricao", "").strip()
    preco_texto = request.form.get("preco", "0").strip().replace(".", "").replace(",", ".")
    duracao_texto = request.form.get("duracao_minutos", "30").strip()
    ativo = request.form.get("ativo") == "on"

    try:
        preco_formatado = f"{float(preco_texto):.2f}"
    except ValueError:
        preco_formatado = "0.00"

    try:
        duracao = int(duracao_texto)
    except ValueError:
        duracao = 30

    corpo = {
        "categoria_id": int(categoria_id) if categoria_id else None,
        "nome": nome,
        "descricao": descricao if descricao else None,
        "preco": preco_formatado,
        "duracao_minutos": duracao,
    }

    try:
        if servico_id:
            corpo["ativo"] = ativo
            api_call("PATCH", f"/servicos/{servico_id}", json_data=corpo)
            flash("Serviço atualizado.", "sucesso")
        else:
            api_call("POST", "/servicos", json_data=corpo)
            flash("Serviço criado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")

    return redirect(url_for("listar_servicos"))


@app.route("/servicos/<int:servico_id>/ativo", methods=["POST"])
@login_obrigatorio
def alternar_ativo_servico(servico_id: int):
    ativo = request.form.get("ativo") == "true"
    try:
        api_call("PATCH", f"/servicos/{servico_id}", json_data={"ativo": ativo})
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_servicos"))


@app.route("/servicos/<int:servico_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_servico(servico_id: int):
    try:
        api_call("DELETE", f"/servicos/{servico_id}")
        flash("Serviço excluído.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_servicos"))


# ==========================================
# 2. USUÁRIOS (/usuarios)
# ==========================================
@app.route("/usuarios")
@login_obrigatorio
def listar_usuarios():
    usuarios = []
    erro = None
    try:
        usuarios = api_call("GET", "/usuarios") or []
    except ApiException as e:
        erro = e.mensagem

    return render_template(
        "usuarios/listar.html",
        pagina_ativa="usuarios",
        titulo_pagina="Usuários",
        usuarios=usuarios,
        erro=erro,
    )


@app.route("/usuarios/salvar", methods=["POST"])
@login_obrigatorio
def salvar_usuario():
    usuario_id = request.form.get("usuario_id", "").strip()
    nome = request.form.get("nome", "").strip()
    email = request.form.get("email", "").strip()
    senha = request.form.get("senha", "")
    ativo = request.form.get("ativo") == "on"

    try:
        if usuario_id:
            corpo = {
                "nome": nome,
                "email": email,
                "ativo": ativo,
            }
            if senha:
                corpo["senha"] = senha
            api_call("PATCH", f"/usuarios/{usuario_id}", json_data=corpo)
            flash("Usuário atualizado.", "sucesso")
        else:
            corpo = {
                "nome": nome,
                "email": email,
                "senha": senha,
                "ativo": ativo,
            }
            api_call("POST", "/usuarios", json_data=corpo)
            flash("Usuário criado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")

    return redirect(url_for("listar_usuarios"))


@app.route("/usuarios/<int:usuario_id>/ativo", methods=["POST"])
@login_obrigatorio
def alternar_ativo_usuario(usuario_id: int):
    ativo = request.form.get("ativo") == "true"
    try:
        api_call("PATCH", f"/usuarios/{usuario_id}", json_data={"ativo": ativo})
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_usuarios"))


@app.route("/usuarios/<int:usuario_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_usuario(usuario_id: int):
    try:
        api_call("DELETE", f"/usuarios/{usuario_id}")
        flash("Usuário excluído.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_usuarios"))


# ==========================================
# 3. AGENDAMENTOS (/agendamentos)
# ==========================================
STATUS_TRANSICOES = {
    "reservado": [("pendente", "Pendente"), ("cancelado", "Cancelado")],
    "pendente": [("confirmado", "Confirmado"), ("cancelado", "Cancelado")],
    "confirmado": [("concluido", "Concluído"), ("faltou", "Faltou"), ("cancelado", "Cancelado")],
    "cancelado": [],
    "concluido": [],
    "faltou": [],
}

STATUS_ROTULOS = {
    "reservado": "Reservado",
    "pendente": "Pendente",
    "confirmado": "Confirmado",
    "cancelado": "Cancelado",
    "concluido": "Concluído",
    "faltou": "Faltou",
}


@app.route("/agendamentos")
@login_obrigatorio
def listar_agendamentos():
    inicio = request.args.get("inicio", "").strip()
    fim = request.args.get("fim", "").strip()
    status_filtro = request.args.get("status", "").strip()

    query = {}
    if inicio and fim:
        try:
            dt_ini = datetime.strptime(inicio, "%Y-%m-%d").astimezone()
            dt_fim = (datetime.strptime(fim, "%Y-%m-%d") + timedelta(days=1)).astimezone()
            query["inicio"] = dt_ini.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
            query["fim"] = dt_fim.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        except ValueError:
            pass

    agendamentos = []
    erro = None
    try:
        agendamentos = api_call("GET", "/agendamentos", params=query if query else None) or []
    except ApiException as e:
        erro = e.mensagem

    agendamentos.sort(key=lambda x: x.get("dt_inicio") or "")

    if status_filtro:
        agendamentos = [
            a for a in agendamentos
            if str(a.get("status", "")).lower() == status_filtro.lower()
        ]

    for a in agendamentos:
        st = a.get("status", "pendente")
        a["status_rotulo"] = STATUS_ROTULOS.get(st, st)
        a["proximos_status"] = STATUS_TRANSICOES.get(st, [])
        a["pode_remarcar"] = st in ("pendente", "confirmado")

    return render_template(
        "agendamentos/listar.html",
        pagina_ativa="agendamentos",
        titulo_pagina="Agendamentos",
        agendamentos=agendamentos,
        erro=erro,
        inicio=inicio,
        fim=fim,
        status_filtro=status_filtro,
        status_opcoes=list(STATUS_ROTULOS.items()),
    )


def _redirect_agendamentos():
    params = {}
    for k in ("inicio", "fim", "status"):
        v = request.form.get(f"filtro_{k}", "").strip() or request.args.get(k, "").strip()
        if v:
            params[k] = v
    return redirect(url_for("listar_agendamentos", **params))


@app.route("/agendamentos/<int:agendamento_id>/status", methods=["POST"])
@login_obrigatorio
def alterar_status_agendamento(agendamento_id: int):
    novo_status = request.form.get("status", "").strip()
    rotulo = STATUS_ROTULOS.get(novo_status, novo_status)
    try:
        api_call("PATCH", f"/agendamentos/{agendamento_id}/status", json_data={"status": novo_status})
        flash(f'Status alterado para "{rotulo}".', "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return _redirect_agendamentos()


@app.route("/agendamentos/<int:agendamento_id>/remarcar", methods=["POST"])
@login_obrigatorio
def remarcar_agendamento(agendamento_id: int):
    data_iso = request.form.get("data", "").strip()
    hora_str = request.form.get("hora", "").strip()
    observacoes = request.form.get("observacoes", "").strip()

    if len(hora_str) >= 5:
        hora_str = hora_str[:5]

    corpo = {
        "data": data_iso,
        "hora": hora_str,
        "observacoes": observacoes if observacoes else None,
    }
    try:
        api_call("PATCH", f"/agendamentos/{agendamento_id}", json_data=corpo)
        flash("Agendamento remarcado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return _redirect_agendamentos()


@app.route("/agendamentos/<int:agendamento_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_agendamento(agendamento_id: int):
    try:
        api_call("DELETE", f"/agendamentos/{agendamento_id}")
        flash("Agendamento excluído.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return _redirect_agendamentos()


# ==========================================
# 4. CLIENTES (/clientes)
# ==========================================
@app.route("/clientes")
@login_obrigatorio
def listar_clientes():
    clientes = []
    erro = None
    try:
        clientes = api_call("GET", "/clientes") or []
    except ApiException as e:
        erro = e.mensagem

    return render_template(
        "clientes/listar.html",
        pagina_ativa="clientes",
        titulo_pagina="Clientes",
        clientes=clientes,
        erro=erro,
    )


@app.route("/clientes/salvar", methods=["POST"])
@login_obrigatorio
def salvar_cliente():
    cliente_id = request.form.get("cliente_id", "").strip()
    nome = request.form.get("nome", "").strip()
    telefone_bruto = request.form.get("telefone", "").strip()
    telefone = re.sub(r"\D", "", telefone_bruto)
    email = request.form.get("email", "").strip()
    aceita_lembretes = request.form.get("aceita_lembretes") == "on"

    if not email:
        flash("O e-mail do cliente é obrigatório.", "erro")
        return redirect(url_for("listar_clientes"))

    if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email):
        flash("Informe um endereço de e-mail válido.", "erro")
        return redirect(url_for("listar_clientes"))

    corpo = {
        "nome": nome,
        "telefone": telefone,
        "email": email,
        "aceita_lembretes": aceita_lembretes,
    }

    try:
        if cliente_id:
            api_call("PATCH", f"/clientes/{cliente_id}", json_data=corpo)
            flash("Cliente atualizado.", "sucesso")
        else:
            corpo["consentimento"] = True
            api_call("POST", "/clientes", json_data=corpo)
            flash("Cliente cadastrado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")

    return redirect(url_for("listar_clientes"))


@app.route("/clientes/<int:cliente_id>/lembretes", methods=["POST"])
@login_obrigatorio
def alternar_lembretes_cliente(cliente_id: int):
    aceita = request.form.get("aceita_lembretes") == "true"
    try:
        api_call("PATCH", f"/clientes/{cliente_id}", json_data={"aceita_lembretes": aceita})
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_clientes"))


@app.route("/clientes/<int:cliente_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_cliente(cliente_id: int):
    try:
        api_call("DELETE", f"/clientes/{cliente_id}")
        flash("Cliente excluído.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_clientes"))


# ==========================================
# 5. CATEGORIAS (/categorias)
# ==========================================
@app.route("/categorias")
@login_obrigatorio
def listar_categorias():
    categorias = []
    erro = None
    try:
        categorias = api_call("GET", "/categorias") or []
    except ApiException as e:
        erro = e.mensagem

    return render_template(
        "categorias/listar.html",
        pagina_ativa="categorias",
        titulo_pagina="Categorias",
        categorias=categorias,
        erro=erro,
    )


@app.route("/categorias/salvar", methods=["POST"])
@login_obrigatorio
def salvar_categoria():
    categoria_id = request.form.get("categoria_id", "").strip()
    nome = request.form.get("nome", "").strip()
    ativo = request.form.get("ativo") == "on"

    try:
        if categoria_id:
            api_call("PATCH", f"/categorias/{categoria_id}", json_data={"nome": nome, "ativo": ativo})
            flash("Categoria atualizada.", "sucesso")
        else:
            api_call("POST", "/categorias", json_data={"nome": nome})
            flash("Categoria criada.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")

    return redirect(url_for("listar_categorias"))


@app.route("/categorias/<int:categoria_id>/ativo", methods=["POST"])
@login_obrigatorio
def alternar_ativo_categoria(categoria_id: int):
    ativo = request.form.get("ativo") == "true"
    try:
        api_call("PATCH", f"/categorias/{categoria_id}", json_data={"ativo": ativo})
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_categorias"))


@app.route("/categorias/<int:categoria_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_categoria(categoria_id: int):
    try:
        api_call("DELETE", f"/categorias/{categoria_id}")
        flash("Categoria excluída.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_categorias"))


# ==========================================
# 6. LEMBRETES (/lembretes)
# ==========================================
@app.route("/lembretes")
@login_obrigatorio
def listar_lembretes():
    lembretes = []
    erro = None
    try:
        lembretes = api_call("GET", "/lembretes") or []
    except ApiException as e:
        erro = e.mensagem

    agora = datetime.now().astimezone()
    total_enviados = 0
    total_fila = 0
    total_agendados = 0

    for l in lembretes:
        dt_envio = _parse_iso(l.get("enviar_em"))
        enviado = bool(l.get("enviado"))
        if enviado:
            l["situacao_calc"] = "enviado"
            total_enviados += 1
        elif dt_envio and dt_envio <= agora:
            l["situacao_calc"] = "fila"
            total_fila += 1
        else:
            l["situacao_calc"] = "agendado"
            total_agendados += 1

        l["data_input"] = dt_envio.strftime("%Y-%m-%d") if dt_envio else ""
        l["hora_input"] = dt_envio.strftime("%H:%M") if dt_envio else ""

    return render_template(
        "lembretes/listar.html",
        pagina_ativa="lembretes",
        titulo_pagina="Lembretes",
        lembretes=lembretes,
        erro=erro,
        total_enviados=total_enviados,
        total_fila=total_fila,
        total_agendados=total_agendados,
    )


@app.route("/lembretes/<int:lembrete_id>/enviado", methods=["POST"])
@login_obrigatorio
def marcar_lembrete_enviado(lembrete_id: int):
    try:
        api_call("PATCH", f"/lembretes/{lembrete_id}/enviado", json_data={})
        flash("Lembrete marcado como enviado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_lembretes"))


@app.route("/lembretes/<int:lembrete_id>/editar", methods=["POST"])
@login_obrigatorio
def editar_lembrete(lembrete_id: int):
    tipo = request.form.get("tipo", "confirmacao").strip()
    data_str = request.form.get("data", "").strip()
    hora_str = request.form.get("hora", "").strip()

    try:
        dt_local = datetime.strptime(f"{data_str} {hora_str[:5]}", "%Y-%m-%d %H:%M").astimezone()
        dt_utc_iso = dt_local.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
    except ValueError:
        flash("Data ou horário inválido.", "erro")
        return redirect(url_for("listar_lembretes"))

    try:
        api_call(
            "PATCH",
            f"/lembretes/{lembrete_id}",
            json_data={"enviar_em": dt_utc_iso, "tipo": tipo},
        )
        flash("Lembrete atualizado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")

    return redirect(url_for("listar_lembretes"))


@app.route("/lembretes/<int:lembrete_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_lembrete(lembrete_id: int):
    try:
        api_call("DELETE", f"/lembretes/{lembrete_id}")
        flash("Lembrete excluído.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_lembretes"))


# ==========================================
# 7. DISPONIBILIDADES (/disponibilidades)
# ==========================================
NOMES_DIAS = [
    "Segunda-feira",
    "Terça-feira",
    "Quarta-feira",
    "Quinta-feira",
    "Sexta-feira",
    "Sábado",
    "Domingo",
]

DIAS_CURTOS = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]


@app.route("/disponibilidades")
@login_obrigatorio
def listar_disponibilidades():
    aba = request.args.get("aba", "semanais").strip()
    if aba not in ("semanais", "bloqueados"):
        aba = "semanais"

    blocos = []
    bloqueios = []
    erro = None

    try:
        blocos = api_call("GET", "/disponibilidades") or []
        bloqueios = api_call("GET", "/bloqueios") or []
    except ApiException as e:
        erro = e.mensagem

    for b in blocos:
        dia_idx = b.get("dia_semana", 0)
        b["nome_dia"] = NOMES_DIAS[dia_idx] if 0 <= dia_idx < 7 else f"Dia {dia_idx}"
        b["inicio_curto"] = str(b.get("hora_inicio", ""))[:5]
        b["fim_curto"] = str(b.get("hora_fim", ""))[:5]

    hoje_iso = datetime.now().strftime("%Y-%m-%d")

    return render_template(
        "disponibilidade/listar.html",
        pagina_ativa="disponibilidades",
        titulo_pagina="Disponibilidades",
        blocos=blocos,
        bloqueios=bloqueios,
        erro=erro,
        aba=aba,
        nomes_dias=NOMES_DIAS,
        dias_curtos=DIAS_CURTOS,
        hoje_iso=hoje_iso,
    )


@app.route("/disponibilidades/salvar", methods=["POST"])
@login_obrigatorio
def salvar_disponibilidade():
    disp_id = request.form.get("disp_id", "").strip()
    dia_semana = int(request.form.get("dia_semana", 0))
    hora_inicio = request.form.get("hora_inicio", "08:00").strip()[:5]
    hora_fim = request.form.get("hora_fim", "18:00").strip()[:5]
    ativo = request.form.get("ativo") == "on"

    corpo = {
        "dia_semana": dia_semana,
        "hora_inicio": f"{hora_inicio}:00",
        "hora_fim": f"{hora_fim}:00",
        "ativo": ativo,
    }

    try:
        if disp_id:
            api_call("PATCH", f"/disponibilidades/{disp_id}", json_data=corpo)
            flash("Horário atualizado.", "sucesso")
        else:
            api_call("POST", "/disponibilidades", json_data=corpo)
            flash("Horário criado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")

    return redirect(url_for("listar_disponibilidades", aba="semanais"))


@app.route("/disponibilidades/<int:disp_id>/ativo", methods=["POST"])
@login_obrigatorio
def alternar_ativo_disponibilidade(disp_id: int):
    ativo = request.form.get("ativo") == "true"
    try:
        api_call("PATCH", f"/disponibilidades/{disp_id}", json_data={"ativo": ativo})
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_disponibilidades", aba="semanais"))


@app.route("/disponibilidades/<int:disp_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_disponibilidade(disp_id: int):
    try:
        api_call("DELETE", f"/disponibilidades/{disp_id}")
        flash("Horário excluído.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_disponibilidades", aba="semanais"))


@app.route("/bloqueios/salvar", methods=["POST"])
@login_obrigatorio
def salvar_bloqueio():
    data_iso = request.form.get("data", "").strip()
    hora_inicio = request.form.get("hora_inicio", "14:00").strip()[:5]
    hora_fim = request.form.get("hora_fim", "15:00").strip()[:5]
    motivo = request.form.get("motivo", "").strip()

    corpo = {
        "data": data_iso,
        "hora_inicio": f"{hora_inicio}:00",
        "hora_fim": f"{hora_fim}:00",
        "motivo": motivo,
    }

    try:
        api_call("POST", "/bloqueios", json_data=corpo)
        flash("Horário bloqueado com sucesso.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")

    return redirect(url_for("listar_disponibilidades", aba="bloqueados"))


@app.route("/bloqueios/<int:bloqueio_id>/excluir", methods=["POST"])
@login_obrigatorio
def excluir_bloqueio(bloqueio_id: int):
    try:
        api_call("DELETE", f"/bloqueios/{bloqueio_id}")
        flash("Horário desbloqueado.", "sucesso")
    except ApiException as e:
        flash(e.mensagem, "erro")
    return redirect(url_for("listar_disponibilidades", aba="bloqueados"))


if __name__ == "__main__":
    porta = int(os.getenv("PORT", 5000))
    print(f"Iniciando Painel Administrativo em Flask consumindo API em {API_BASE_URL}...")
    print(f"Acesse: http://localhost:{porta}")
    app.run(host="0.0.0.0", port=porta, debug=True)