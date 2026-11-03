import 'package:flutter/material.dart';

import 'package:main/models/categoria_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

const double _larguraMinimaTabela = 600;

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  List<CategoriaModel> _categorias = [];
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
      final dados = await ApiClient.instancia.get('/categorias') as List;
      final lista = dados
          .map((e) => CategoriaModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _categorias = lista;
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

  Future<void> _abrirFormulario({CategoriaModel? categoria}) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioCategoria(categoria: categoria),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(
        context,
        categoria == null ? 'Categoria criada.' : 'Categoria atualizada.',
      );
      _carregar(silencioso: true);
    }
  }

  Future<void> _alternarAtivo(CategoriaModel categoria, bool novoValor) async {
    try {
      await ApiClient.instancia
          .patch('/categorias/${categoria.id}', {'ativo': novoValor});
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _excluir(CategoriaModel categoria) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir categoria',
      mensagem: 'Excluir "${categoria.nome}"?\n'
          'Se ela tiver serviços, o sistema não permite: desative em vez de excluir.',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.delete('/categorias/${categoria.id}');
      if (!mounted) return;
      mostrarMensagem(context, 'Categoria excluída.');
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CabecalhoLista(
          resumo: '${_categorias.length} categoria(s)',
          rotuloBotao: 'Nova categoria',
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
    if (_categorias.isEmpty) {
      return const Center(child: Text('Nenhuma categoria cadastrada.'));
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
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: _categorias.map((c) {
              return DataRow(cells: [
                DataCell(Text(c.nome)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: c.ativo,
                      activeColor: PainelCores.vinho,
                      onChanged: (valor) => _alternarAtivo(c, valor),
                    ),
                    StatusChip(ativo: c.ativo),
                  ],
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar',
                      onPressed: () => _abrirFormulario(categoria: c),
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

  Widget _listaCards() {
    return ListView.separated(
      itemCount: _categorias.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoCategoria(_categorias[i]),
    );
  }

  Widget _cartaoCategoria(CategoriaModel c) {
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
                    c.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: StatusChip(ativo: c.ativo),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: c.ativo,
                  activeColor: PainelCores.vinho,
                  onChanged: (valor) => _alternarAtivo(c, valor),
                ),
                const Text('Ativa'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => _abrirFormulario(categoria: c),
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

class _FormularioCategoria extends StatefulWidget {
  final CategoriaModel? categoria;

  const _FormularioCategoria({this.categoria});

  @override
  State<_FormularioCategoria> createState() => _FormularioCategoriaState();
}

class _FormularioCategoriaState extends State<_FormularioCategoria> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  bool _ativo = true;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.categoria?.nome ?? '');
    _ativo = widget.categoria?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final nome = _nomeController.text.trim();
    try {
      if (_editando) {
        await ApiClient.instancia.patch(
          '/categorias/${widget.categoria!.id}',
          {'nome': nome, 'ativo': _ativo},
        );
      } else {
        await ApiClient.instancia.post('/categorias', {'nome': nome});
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
      title: Text(_editando ? 'Editar categoria' : 'Nova categoria'),
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _salvar(),
                    decoration: decoracaoFormulario('Nome'),
                    validator: (valor) {
                      final texto = (valor ?? '').trim();
                      if (texto.isEmpty) return 'Informe o nome';
                      if (texto.length > 100) return 'No máximo 100 caracteres';
                      return null;
                    },
                  ),
                  if (_editando)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ativa'),
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