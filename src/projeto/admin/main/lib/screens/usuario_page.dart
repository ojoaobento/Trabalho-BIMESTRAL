import 'package:flutter/material.dart';

import 'package:main/models/usuario_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

const double _larguraMinimaTabela = 720;

/// Minúsculas e sem acentos, para a busca não depender disso.
String _normalizar(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';

  final saida = StringBuffer();

  for (final c in texto.toLowerCase().split('')) {
    final i = de.indexOf(c);
    saida.write(i == -1 ? c : para[i]);
  }

  return saida.toString();
}

class UsuarioPage extends StatefulWidget {
  const UsuarioPage({super.key});

  @override
  State<UsuarioPage> createState() => _UsuarioPageState();
}

class _UsuarioPageState extends State<UsuarioPage> {
  List<UsuarioModel> _usuarios = [];
  bool _carregando = true;
  String? _erro;

  final _buscaController = TextEditingController();
  String _busca = '';

  /// Usuários que combinam com o texto da busca (nome ou e-mail),
  /// ignorando maiúsculas e acentos.
  List<UsuarioModel> get _filtrados {
    final termo = _normalizar(_busca.trim());
    if (termo.isEmpty) return _usuarios;

    return _usuarios.where((u) {
      return _normalizar('${u.nome} ${u.email}').contains(termo);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _limparBusca() {
    _buscaController.clear();
    setState(() => _busca = '');
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final dados = await ApiClient.instancia.get('/usuarios') as List;
      final lista = dados
          .map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _usuarios = lista;
        _carregando = false;
        _erro = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    }
  }

  Future<void> _abrirFormulario({UsuarioModel? usuario}) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioUsuario(usuario: usuario),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(
        context,
        usuario == null ? 'Usuário criado.' : 'Usuário atualizado.',
      );
      _carregar(silencioso: true);
    }
  }

  Future<void> _alternarAtivo(UsuarioModel usuario, bool novoValor) async {
    try {
      await ApiClient.instancia
          .patch('/usuarios/${usuario.id}', {'ativo': novoValor});
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _excluir(UsuarioModel usuario) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir usuário',
      mensagem: 'Excluir "${usuario.nome}"?\n'
          'Se ele já confirmou agendamentos, o sistema não permite: desative em vez de excluir.',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.delete('/usuarios/${usuario.id}');
      if (!mounted) return;
      mostrarMensagem(context, 'Usuário excluído.');
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) return '-';
    final d = data.toLocal();
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CabecalhoLista(
          resumo: _busca.trim().isEmpty
              ? '${_usuarios.length} usuário(s)'
              : '${_filtrados.length} de ${_usuarios.length} usuário(s)',
          rotuloBotao: 'Novo usuário',
          onPressed: () => _abrirFormulario(),
        ),
        const SizedBox(height: 16),
        if (!_carregando && _erro == null && _usuarios.isNotEmpty) ...[
          _campoBusca(),
          const SizedBox(height: 16),
        ],
        Expanded(child: _conteudo()),
      ],
    );
  }

  Widget _campoBusca() {
    OutlineInputBorder borda(Color cor, {double largura = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    return TextField(
      controller: _buscaController,
      onChanged: (valor) => setState(() => _busca = valor),
      textInputAction: TextInputAction.search,
      cursorColor: PainelCores.vinho,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: 'Buscar por nome ou e-mail',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: PainelCores.vinho,
        ),
        suffixIcon: _busca.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                onPressed: _limparBusca,
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: borda(Colors.grey.shade300),
        enabledBorder: borda(Colors.grey.shade300),
        focusedBorder: borda(PainelCores.vinho, largura: 1.6),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: PainelCores.vinho),
      );
    }
    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, onTentarNovamente: _carregar);
    }
    if (_usuarios.isEmpty) {
      return const Center(child: Text('Nenhum usuário cadastrado.'));
    }

    final lista = _filtrados;

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Nenhum usuário encontrado para "${_busca.trim()}".',
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _limparBusca,
              style: TextButton.styleFrom(foregroundColor: PainelCores.vinho),
              child: const Text('Limpar busca'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _larguraMinimaTabela) {
          return _listaCards(lista);
        }
        return _tabela(constraints, lista);
      },
    );
  }

  Widget _tabela(BoxConstraints constraints, List<UsuarioModel> lista) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: PainelCores.vinho,
            ),
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('E-mail')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Cadastro')),
              DataColumn(label: Text('Ações')),
            ],
            rows: lista.map((u) {
              return DataRow(cells: [
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    u.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                )),
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    u.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: u.ativo,
                      activeColor: PainelCores.vinho,
                      onChanged: (valor) => _alternarAtivo(u, valor),
                    ),
                    StatusChip(ativo: u.ativo),
                  ],
                )),
                DataCell(Text(_formatarData(u.dt_cadastro))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar',
                      onPressed: () => _abrirFormulario(usuario: u),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade700),
                      tooltip: 'Excluir',
                      onPressed: () => _excluir(u),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _listaCards(List<UsuarioModel> lista) {
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoUsuario(lista[i]),
    );
  }

  Widget _cartaoUsuario(UsuarioModel u) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    u.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: StatusChip(ativo: u.ativo),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              u.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 2),
            Text(
              'Cadastro: ${_formatarData(u.dt_cadastro)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: u.ativo,
                  activeColor: PainelCores.vinho,
                  onChanged: (valor) => _alternarAtivo(u, valor),
                ),
                const Text('Ativo'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => _abrirFormulario(usuario: u),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  tooltip: 'Excluir',
                  onPressed: () => _excluir(u),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulário de usuário (criar / editar)
// ---------------------------------------------------------------------------

class _FormularioUsuario extends StatefulWidget {
  final UsuarioModel? usuario;

  const _FormularioUsuario({this.usuario});

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);
  static const _corErro = Color(0xFFB3261E);
  static const _corErroFundo = Color(0xFFFDE7E9);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  final _senhaController = TextEditingController();
  bool _ativo = true;
  bool _ocultarSenha = true;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _ativo = widget.usuario?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final corpo = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'ativo': _ativo,
    };
    // Na edição, a senha só vai se o campo foi preenchido.
    if (_senhaController.text.isNotEmpty) {
      corpo['senha'] = _senhaController.text;
    }

    try {
      if (_editando) {
        await ApiClient.instancia.patch('/usuarios/${widget.usuario!.id}', corpo);
      } else {
        await ApiClient.instancia.post('/usuarios', corpo);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = e.mensagem;
      });
    }
  }

  // ---------- visual ----------

  OutlineInputBorder _borda(Color cor, {double largura = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cor, width: largura),
    );
  }

  InputDecoration _decoracao({
    String? dica,
    IconData? icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: _corFundo,
      hintText: dica,
      hintStyle: TextStyle(color: _corSuave.withOpacity(.6), fontSize: 14),
      prefixIcon: icone == null
          ? null
          : Icon(icone, size: 18, color: PainelCores.vinho),
      suffixIcon: sufixo,
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _borda(_corBorda),
      enabledBorder: _borda(_corBorda),
      disabledBorder: _borda(_corBorda),
      focusedBorder: _borda(PainelCores.vinho, largura: 1.6),
      errorBorder: _borda(_corErro),
      focusedErrorBorder: _borda(_corErro, largura: 1.6),
    );
  }

  Widget _rotulado(String titulo, Widget campo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _corTexto,
            ),
          ),
        ),
        campo,
      ],
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEF3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _editando ? Icons.edit_outlined : Icons.person_add_alt_1_outlined,
              color: PainelCores.vinho,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editando ? 'Editar usuário' : 'Novo usuário',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editando
                      ? 'Atualize os dados de acesso.'
                      : 'Crie um acesso ao painel.',
                  style: const TextStyle(fontSize: 12, color: _corSuave),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: _salvando ? null : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded, color: _corSuave),
          ),
        ],
      ),
    );
  }

  Widget _rodape() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _salvando ? null : () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: PainelCores.vinho,
                side: const BorderSide(color: _corBorda),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: PainelCores.vinho,
                foregroundColor: Colors.white,
                disabledBackgroundColor: PainelCores.vinho.withOpacity(.4),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _editando ? 'Salvar alterações' : 'Criar usuário',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Troca o roxo padrão do Material pela cor do painel dentro do diálogo
    // (cursor, seleção de texto).
    final tema = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: PainelCores.vinho,
            onPrimary: Colors.white,
            surface: Colors.white,
            surfaceTint: Colors.transparent,
          ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: PainelCores.vinho,
        selectionColor: PainelCores.vinho.withOpacity(.2),
        selectionHandleColor: PainelCores.vinho,
      ),
    );

    return Theme(
      data: tema,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _cabecalho(),
                const Divider(height: 1, color: _corBorda),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _rotulado(
                          'Nome',
                          TextFormField(
                            controller: _nomeController,
                            autofocus: true,
                            enabled: !_salvando,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'Nome completo',
                              icone: Icons.person_outline,
                            ),
                            validator: (valor) {
                              final texto = (valor ?? '').trim();
                              if (texto.isEmpty) return 'Informe o nome';
                              if (texto.length < 2) {
                                return 'Mínimo de 2 caracteres';
                              }
                              if (texto.length > 100) {
                                return 'No máximo 100 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _rotulado(
                          'E-mail',
                          TextFormField(
                            controller: _emailController,
                            enabled: !_salvando,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'nome@email.com',
                              icone: Icons.mail_outline,
                            ),
                            validator: (valor) {
                              final texto = (valor ?? '').trim();
                              if (texto.isEmpty) return 'Informe o e-mail';
                              final valido =
                                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                              if (!valido.hasMatch(texto)) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _rotulado(
                          _editando ? 'Nova senha (opcional)' : 'Senha',
                          TextFormField(
                            controller: _senhaController,
                            enabled: !_salvando,
                            obscureText: _ocultarSenha,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _salvar(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: _editando
                                  ? 'Deixe em branco para manter'
                                  : 'Mínimo de 6 caracteres',
                              icone: Icons.lock_outline,
                              sufixo: IconButton(
                                tooltip: _ocultarSenha
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                icon: Icon(
                                  _ocultarSenha
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: _corSuave,
                                ),
                                onPressed: () => setState(
                                  () => _ocultarSenha = !_ocultarSenha,
                                ),
                              ),
                            ),
                            validator: (valor) {
                              final texto = valor ?? '';
                              if (_editando && texto.isEmpty) return null;
                              if (texto.isEmpty) return 'Informe a senha';
                              if (texto.length < 6) {
                                return 'Mínimo de 6 caracteres';
                              }
                              if (texto.length > 265) {
                                return 'Senha muito longa';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                          decoration: BoxDecoration(
                            color: _corFundo,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _corBorda),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Usuário ativo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _corTexto,
                                      ),
                                    ),
                                    Text(
                                      'Pode entrar no painel.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _corSuave,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _ativo,
                                activeColor: Colors.white,
                                activeTrackColor: PainelCores.vinho,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: _corBorda,
                                trackOutlineColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                onChanged: _salvando
                                    ? null
                                    : (v) => setState(() => _ativo = v),
                              ),
                            ],
                          ),
                        ),
                        if (_erro != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _corErroFundo,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 18,
                                  color: _corErro,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _erro!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _corErro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _rodape(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}