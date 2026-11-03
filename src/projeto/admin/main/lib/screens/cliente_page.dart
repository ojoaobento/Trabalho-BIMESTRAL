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

class _FormularioCliente extends StatefulWidget {
  final ClienteModel? cliente;

  const _FormularioCliente({this.cliente});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _emailController;
  bool _aceitaLembretes = true;
  bool _consentimento = false;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.cliente?.nome ?? '');
    _telefoneController =
        TextEditingController(text: widget.cliente?.telefone ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _aceitaLembretes = widget.cliente?.aceitaLembretes ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_editando && !_consentimento) {
      setState(() => _erro = 'É necessário confirmar o consentimento do cliente.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final email = _emailController.text.trim();
    final corpo = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'email': email.isEmpty ? null : email,
      'aceita_lembretes': _aceitaLembretes,
    };

    try {
      if (_editando) {
        await ApiClient.instancia.patch('/clientes/${widget.cliente!.id}', corpo);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_editando ? 'Editar cliente' : 'Novo cliente'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    autofocus: true,
                    enabled: !_salvando,
                    textInputAction: TextInputAction.next,
                    decoration: decoracaoFormulario('Nome'),
                    validator: (valor) {
                      final texto = (valor ?? '').trim();
                      if (texto.isEmpty) return 'Informe o nome';
                      if (texto.length < 2) return 'Mínimo de 2 caracteres';
                      if (texto.length > 100) return 'No máximo 100 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefoneController,
                    enabled: !_salvando,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: decoracaoFormulario('Telefone (DDD + número)'),
                    validator: (valor) {
                      final texto = (valor ?? '').trim();
                      if (texto.isEmpty) return 'Informe o telefone';
                      if (texto.length != 11) {
                        return 'Use 11 dígitos, ex.: 44988136876';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_salvando,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _salvar(),
                    decoration: decoracaoFormulario('E-mail (opcional)'),
                    validator: (valor) {
                      final texto = (valor ?? '').trim();
                      if (texto.isEmpty) return null;
                      final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!valido.hasMatch(texto)) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aceita lembretes'),
                    value: _aceitaLembretes,
                    activeColor: PainelCores.vinho,
                    onChanged: _salvando
                        ? null
                        : (v) => setState(() => _aceitaLembretes = v),
                  ),
                  if (!_editando)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: PainelCores.vinho,
                      title: const Text(
                        'O cliente consentiu com o tratamento dos seus dados.',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _consentimento,
                      onChanged: _salvando
                          ? null
                          : (v) => setState(() => _consentimento = v ?? false),
                    ),
                  if (_erro != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _erro!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: PainelCores.vinho,
            foregroundColor: Colors.white,
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
              : const Text('Salvar'),
        ),
      ],
    );
  }
}