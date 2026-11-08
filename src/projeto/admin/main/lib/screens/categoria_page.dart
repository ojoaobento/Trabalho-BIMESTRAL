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
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  List<CategoriaModel> get _filtradas {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return _categorias;
    return _categorias
        .where((c) => c.nome.toLowerCase().contains(termo))
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
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: TextField(
            onChanged: (v) => setState(() => _busca = v),
            decoration: decoracaoFormulario('Buscar por nome da categoria')
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
    if (_categorias.isEmpty) {
      return const Center(child: Text('Nenhuma categoria cadastrada.'));
    }

    final lista = _filtradas;
    if (lista.isEmpty) {
      return const Center(child: Text('Nenhuma categoria encontrada para a busca.'));
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

  Widget _tabela(BoxConstraints constraints, List<CategoriaModel> lista) {
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
            rows: lista.map((c) {
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

  Widget _listaCards(List<CategoriaModel> lista) {
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoCategoria(lista[i]),
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

// ---------------------------------------------------------------------------
// Formulário de categoria (criar / editar)
// ---------------------------------------------------------------------------

class _FormularioCategoria extends StatefulWidget {
  final CategoriaModel? categoria;

  const _FormularioCategoria({this.categoria});

  @override
  State<_FormularioCategoria> createState() => _FormularioCategoriaState();
}

class _FormularioCategoriaState extends State<_FormularioCategoria> {
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);
  static const _corErro = Color(0xFFB3261E);
  static const _corErroFundo = Color(0xFFFDE7E9);

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
    if (_salvando) return;
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
      counterStyle: const TextStyle(fontSize: 11, color: _corSuave),
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
              _editando ? Icons.edit_outlined : Icons.folder_open_outlined,
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
                  _editando ? 'Editar categoria' : 'Nova categoria',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editando
                      ? 'Atualize os dados da categoria.'
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
                      _editando ? 'Salvar alterações' : 'Criar categoria',
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
    // (cursor, seleção de texto, switch).
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
                          'Nome da categoria',
                          TextFormField(
                            controller: _nomeController,
                            autofocus: true,
                            enabled: !_salvando,
                            maxLength: 100,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _salvar(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'Ex.: Estética facial',
                              icone: Icons.label_outline,
                            ),
                            validator: (valor) {
                              final texto = (valor ?? '').trim();
                              if (texto.isEmpty) return 'Informe o nome';
                              if (texto.length > 100) {
                                return 'No máximo 100 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_editando) ...[
                          const SizedBox(height: 12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Categoria ativa',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _corTexto,
                                        ),
                                      ),
                                      Text(
                                        'Disponível para novos vínculos.',
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
                                  trackOutlineColor:
                                      WidgetStateProperty.all(Colors.transparent),
                                  onChanged: _salvando
                                      ? null
                                      : (v) => setState(() => _ativo = v),
                                ),
                              ],
                            ),
                          ),
                        ],
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