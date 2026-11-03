import 'package:flutter/material.dart';

import 'package:main/models/usuario_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

const double _larguraMinimaTabela = 720;

class UsuarioPage extends StatefulWidget {
  const UsuarioPage({super.key});

  @override
  State<UsuarioPage> createState() => _UsuarioPageState();
}

class _UsuarioPageState extends State<UsuarioPage> {
  List<UsuarioModel> _usuarios = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
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
          resumo: '${_usuarios.length} usuário(s)',
          rotuloBotao: 'Novo usuário',
          onPressed: () => _abrirFormulario(),
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
    if (_usuarios.isEmpty) {
      return const Center(child: Text('Nenhum usuário cadastrado.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _larguraMinimaTabela) {
          return _listaCards();
        }
        return _tabela(constraints);
      },
    );
  }

  Widget _tabela(BoxConstraints constraints) {
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
              DataColumn(label: Text('E-mail')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Cadastro')),
              DataColumn(label: Text('Ações')),
            ],
            rows: _usuarios.map((u) {
              return DataRow(cells: [
                DataCell(Text(u.nome)),
                DataCell(Text(u.email)),
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

  Widget _listaCards() {
    return ListView.separated(
      itemCount: _usuarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoUsuario(_usuarios[i]),
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

class _FormularioUsuario extends StatefulWidget {
  final UsuarioModel? usuario;

  const _FormularioUsuario({this.usuario});

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Margem menor nas laterais para aproveitar melhor telas estreitas.
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_editando ? 'Editar usuário' : 'Novo usuário'),
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
                    controller: _emailController,
                    enabled: !_salvando,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: decoracaoFormulario('E-mail'),
                    validator: (valor) {
                      final texto = (valor ?? '').trim();
                      if (texto.isEmpty) return 'Informe o e-mail';
                      final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!valido.hasMatch(texto)) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senhaController,
                    enabled: !_salvando,
                    obscureText: _ocultarSenha,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _salvar(),
                    decoration: decoracaoFormulario(
                      _editando ? 'Nova senha (opcional)' : 'Senha',
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_ocultarSenha
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _ocultarSenha = !_ocultarSenha),
                      ),
                    ),
                    validator: (valor) {
                      final texto = valor ?? '';
                      if (_editando && texto.isEmpty) return null;
                      if (texto.isEmpty) return 'Informe a senha';
                      if (texto.length < 6) return 'Mínimo de 6 caracteres';
                      if (texto.length > 265) return 'Senha muito longa';
                      return null;
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativo'),
                    value: _ativo,
                    activeColor: PainelCores.vinho,
                    onChanged:
                        _salvando ? null : (v) => setState(() => _ativo = v),
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