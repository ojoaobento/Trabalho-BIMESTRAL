import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:main/models/cliente_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

const double _larguraMinimaTabela = 720;

class ClientePage extends StatefulWidget {
  const ClientePage({super.key});

  @override
  State<ClientePage> createState() => _ClientePageState();
}

class _ClientePageState extends State<ClientePage> {
  List<ClienteModel> _clientes = [];
  bool _carregando = true;
  String? _erro;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  List<ClienteModel> get _filtrados {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return _clientes;
    return _clientes
        .where((c) =>
            c.nome.toLowerCase().contains(termo) ||
            c.telefone.contains(termo) ||
            (c.email ?? '').toLowerCase().contains(termo))
        .toList();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final dados = await ApiClient.instancia.get('/clientes') as List;
      final lista = dados
          .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _clientes = lista;
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

  Future<void> _abrirFormulario({ClienteModel? cliente}) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioCliente(cliente: cliente),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(
        context,
        cliente == null ? 'Cliente criado.' : 'Cliente atualizado.',
      );
      _carregar(silencioso: true);
    }
  }

  Future<void> _alternarLembretes(ClienteModel cliente, bool novoValor) async {
    try {
      await ApiClient.instancia
          .patch('/clientes/${cliente.id}', {'aceita_lembretes': novoValor});
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _excluir(ClienteModel cliente) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir cliente',
      mensagem: 'Excluir "${cliente.nome}"?\n'
          'Se ele tiver agendamentos, o sistema não permite a exclusão.',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.delete('/clientes/${cliente.id}');
      if (!mounted) return;
      mostrarMensagem(context, 'Cliente excluído.');
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

  String _formatarTelefone(String tel) {
    if (tel.length != 11) return tel;
    return '(${tel.substring(0, 2)}) ${tel.substring(2, 7)}-${tel.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CabecalhoLista(
          resumo: '${_clientes.length} cliente(s)',
          rotuloBotao: 'Novo cliente',
          onPressed: () => _abrirFormulario(),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: TextField(
            onChanged: (v) => setState(() => _busca = v),
            decoration: decoracaoFormulario('Buscar por nome, telefone ou e-mail')
                .copyWith(prefixIcon: const Icon(Icons.search)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _conteudo()),
      ],
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
    if (_clientes.isEmpty) {
      return const Center(child: Text('Nenhum cliente cadastrado.'));
    }

    final lista = _filtrados;
    if (lista.isEmpty) {
      return const Center(child: Text('Nenhum cliente encontrado para a busca.'));
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

  Widget _tabela(BoxConstraints constraints, List<ClienteModel> lista) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: PainelCores.vinho,
            ),
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Telefone')),
              DataColumn(label: Text('E-mail')),
              DataColumn(label: Text('Lembretes')),
              DataColumn(label: Text('Cadastro')),
              DataColumn(label: Text('Ações')),
            ],
            rows: lista.map((c) {
              return DataRow(cells: [
                DataCell(Text(c.nome)),
                DataCell(Text(_formatarTelefone(c.telefone))),
                DataCell(Text(c.email ?? '-')),
                DataCell(Switch(
                  value: c.aceitaLembretes,
                  activeColor: PainelCores.vinho,
                  onChanged: (valor) => _alternarLembretes(c, valor),
                )),
                DataCell(Text(_formatarData(c.dtCadastro))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar',
                      onPressed: () => _abrirFormulario(cliente: c),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade700),
                      tooltip: 'Excluir',
                      onPressed: () => _excluir(c),
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

  Widget _listaCards(List<ClienteModel> lista) {
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoCliente(lista[i]),
    );
  }

  Widget _info(IconData icone, String texto) {
    return Row(
      children: [
        Icon(icone, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  Widget _cartaoCliente(ClienteModel c) {
    final email = c.email;
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                c.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _info(Icons.phone_outlined, _formatarTelefone(c.telefone)),
            ),
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _info(Icons.mail_outline, email),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Cadastro: ${_formatarData(c.dtCadastro)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: c.aceitaLembretes,
                  activeColor: PainelCores.vinho,
                  onChanged: (valor) => _alternarLembretes(c, valor),
                ),
                const Flexible(
                  child: Text(
                    'Lembretes',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => _abrirFormulario(cliente: c),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  tooltip: 'Excluir',
                  onPressed: () => _excluir(c),
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
// Formulário de cliente (criar / editar)
// ---------------------------------------------------------------------------

/// Aplica a máscara (44) 98813-6876 enquanto o usuário digita.
class _TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue antigo, TextEditingValue novo) {
    final digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    final d = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      if (i == 7) b.write('-');
      b.write(d[i]);
    }
    final texto = b.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class _FormularioCliente extends StatefulWidget {
  final ClienteModel? cliente;

  const _FormularioCliente({this.cliente});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);
  static const _corErro = Color(0xFFB3261E);
  static const _corErroFundo = Color(0xFFFDE7E9);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _emailController;
  final _telefoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _aceitaLembretes = true;
  bool _consentimento = false;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.cliente != null;

  static String _mascarar(String digitos) {
    if (digitos.isEmpty) return '';
    return _TelefoneFormatter()
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: digitos),
        )
        .text;
  }

  String get _telefoneDigitos =>
      _telefoneController.text.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nomeController = TextEditingController(text: c?.nome ?? '');
    _telefoneController =
        TextEditingController(text: _mascarar(c?.telefone ?? ''));
    _emailController = TextEditingController(text: c?.email ?? '');
    _aceitaLembretes = c?.aceitaLembretes ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _telefoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_editando && !_consentimento) {
      setState(
          () => _erro = 'Confirme o consentimento do cliente para continuar.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final corpo = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'telefone': _telefoneDigitos,
      'email': email.isEmpty ? null : email,
      'aceita_lembretes': _aceitaLembretes,
    };

    try {
      if (_editando) {
        await ApiClient.instancia
            .patch('/clientes/${widget.cliente!.id}', corpo);
      } else {
        corpo['consentimento'] = true;
        await ApiClient.instancia.post('/clientes', corpo);
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

  InputDecoration _decoracao({String? dica, IconData? icone}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: _corFundo,
      hintText: dica,
      hintStyle: TextStyle(color: _corSuave.withOpacity(.6), fontSize: 14),
      prefixIcon: icone == null
          ? null
          : Icon(icone, size: 18, color: PainelCores.vinho),
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
              _editando ? Icons.edit_outlined : Icons.person_add_alt_1,
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
                  _editando ? 'Editar cliente' : 'Novo cliente',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editando
                      ? 'Atualize os dados do cliente.'
                      : 'Preencha os dados para cadastrar.',
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

  Widget _blocoOpcoes() {
    return Container(
      decoration: BoxDecoration(
        color: _corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _corBorda),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aceita lembretes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _corTexto,
                        ),
                      ),
                      Text(
                        'Receber avisos de agendamento.',
                        style: TextStyle(fontSize: 12, color: _corSuave),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _aceitaLembretes,
                  activeColor: Colors.white,
                  activeTrackColor: PainelCores.vinho,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: _corBorda,
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                  onChanged: _salvando
                      ? null
                      : (v) => setState(() => _aceitaLembretes = v),
                ),
              ],
            ),
          ),
          if (!_editando) ...[
            const Divider(height: 1, color: _corBorda),
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: PainelCores.vinho,
              title: const Text(
                'O cliente consentiu com o tratamento dos seus dados.',
                style: TextStyle(fontSize: 13, color: _corTexto),
              ),
              value: _consentimento,
              onChanged: _salvando
                  ? null
                  : (v) => setState(() {
                        _consentimento = v ?? false;
                        if (_consentimento) _erro = null;
                      }),
            ),
          ],
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
                      _editando ? 'Salvar alterações' : 'Criar cliente',
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
    // (cursor, seleção de texto, checkbox, switch).
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
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _cabecalho(),
                const Divider(height: 1, color: _corBorda),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            onFieldSubmitted: (_) =>
                                _telefoneFocus.requestFocus(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'Ex.: Maria Silva',
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
                          'Telefone / WhatsApp',
                          TextFormField(
                            controller: _telefoneController,
                            focusNode: _telefoneFocus,
                            enabled: !_salvando,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _TelefoneFormatter(),
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: '(44) 90000-0000',
                              icone: Icons.phone_outlined,
                            ),
                            validator: (_) {
                              final d = _telefoneDigitos;
                              if (d.isEmpty) return 'Informe o telefone';
                              if (d.length != 11) return 'Use DDD + 9 dígitos';
                              final ddd = int.parse(d.substring(0, 2));
                              if (ddd < 11) return 'DDD inválido';
                              if (d[2] != '9') {
                                return 'O número deve começar com 9';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _rotulado(
                          'E-mail (opcional)',
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            enabled: !_salvando,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            onFieldSubmitted: (_) => _salvar(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'cliente@email.com',
                              icone: Icons.mail_outline,
                            ),
                            validator: (valor) {
                              final texto = (valor ?? '').trim();
                              if (texto.isEmpty) return null;
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
                        _blocoOpcoes(),
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