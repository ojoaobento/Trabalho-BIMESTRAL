import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:main/models/categoria_model.dart';
import 'package:main/models/servico_model.dart';
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

class ServicosPage extends StatefulWidget {
  const ServicosPage({super.key});

  @override
  State<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends State<ServicosPage> {
  List<ServicoModel> _servicos = [];
  List<CategoriaModel> _categorias = [];
  bool _carregando = true;
  String? _erro;

  final _buscaController = TextEditingController();
  String _busca = '';

  Map<int, String> get _nomesCategoria => {
        for (final c in _categorias) c.id: c.nome,
      };

  List<ServicoModel> get _filtrados {
    final termo = _normalizar(_busca.trim());
    if (termo.isEmpty) return _servicos;

    final nomes = _nomesCategoria;

    return _servicos.where((s) {
      final alvo = _normalizar(
        '${s.nome} ${s.descricao ?? ''} ${nomes[s.categoriaId] ?? ''}',
      );
      return alvo.contains(termo);
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
      final resultados = await Future.wait([
        ApiClient.instancia.get('/servicos'),
        ApiClient.instancia.get('/categorias'),
      ]);

      final servicos = (resultados[0] as List)
          .map((e) => ServicoModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      final categorias = (resultados[1] as List)
          .map((e) => CategoriaModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _servicos = servicos;
        _categorias = categorias;
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

  Future<void> _abrirFormulario({ServicoModel? servico}) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioServico(categorias: _categorias, servico: servico),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(
        context,
        servico == null ? 'Serviço criado.' : 'Serviço atualizado.',
      );
      _carregar(silencioso: true);
    }
  }

  Future<void> _alternarAtivo(ServicoModel servico, bool novoValor) async {
    try {
      await ApiClient.instancia
          .patch('/servicos/${servico.id}', {'ativo': novoValor});
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _excluir(ServicoModel servico) async {
    final confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogExcluirServico(servico: servico),
    );

    if (confirmou != true) return;

    try {
      await ApiClient.instancia.delete('/servicos/${servico.id}');

      if (!mounted) return;

      mostrarMensagem(context, 'Serviço excluído.');
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
          resumo: _busca.trim().isEmpty
              ? '${_servicos.length} serviço(s)'
              : '${_filtrados.length} de ${_servicos.length} serviço(s)',
          rotuloBotao: 'Novo serviço',
          onPressed: () => _abrirFormulario(),
        ),
        const SizedBox(height: 16),
        if (!_carregando && _erro == null && _servicos.isNotEmpty) ...[
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
        hintText: 'Buscar por nome, descrição ou categoria',
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
    if (_servicos.isEmpty) {
      return const Center(child: Text('Nenhum serviço cadastrado.'));
    }

    final nomes = _nomesCategoria;
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
              'Nenhum serviço encontrado para "${_busca.trim()}".',
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
          return _listaCards(lista, nomes);
        }
        return _tabela(constraints, lista, nomes);
      },
    );
  }

  Widget _tabela(
    BoxConstraints constraints,
    List<ServicoModel> lista,
    Map<int, String> nomes,
  ) {
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
              DataColumn(label: Text('Serviço')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Duração')),
              DataColumn(label: Text('Preço')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: lista.map((s) {
              final descricao = s.descricao;
              return DataRow(cells: [
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (descricao != null && descricao.isNotEmpty)
                        Text(
                          descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                )),
                DataCell(Text(nomes[s.categoriaId] ?? '—')),
                DataCell(Text('${s.duracaoMinutos} min')),
                DataCell(Text(s.precoFormatado)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: s.ativo,
                      activeThumbColor: PainelCores.vinho,
                      onChanged: (valor) => _alternarAtivo(s, valor),
                    ),
                    StatusChip(ativo: s.ativo),
                  ],
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar',
                      onPressed: () => _abrirFormulario(servico: s),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade700),
                      tooltip: 'Excluir',
                      onPressed: () => _excluir(s),
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

  Widget _listaCards(List<ServicoModel> lista, Map<int, String> nomes) {
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoServico(lista[i], nomes),
    );
  }

  Widget _info(IconData icone, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(color: Colors.grey.shade800)),
      ],
    );
  }

  Widget _cartaoServico(ServicoModel s, Map<int, String> nomes) {
    final descricao = s.descricao;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    s.nome,
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
                  child: StatusChip(ativo: s.ativo),
                ),
              ],
            ),
            if (descricao != null && descricao.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Text(
                  descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _info(Icons.category_outlined, nomes[s.categoriaId] ?? '—'),
                _info(Icons.schedule, '${s.duracaoMinutos} min'),
                _info(Icons.payments_outlined, s.precoFormatado),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: s.ativo,
                  activeThumbColor: PainelCores.vinho,
                  onChanged: (valor) => _alternarAtivo(s, valor),
                ),
                const Text('Ativo'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => _abrirFormulario(servico: s),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  tooltip: 'Excluir',
                  onPressed: () => _excluir(s),
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
// Formulário de serviço (criar / editar)
// ---------------------------------------------------------------------------

class _FormularioServico extends StatefulWidget {
  final List<CategoriaModel> categorias;
  final ServicoModel? servico;

  const _FormularioServico({required this.categorias, this.servico});

  @override
  State<_FormularioServico> createState() => _FormularioServicoState();
}

class _FormularioServicoState extends State<_FormularioServico> {
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);
  static const _corErro = Color(0xFFB3261E);
  static const _corErroFundo = Color(0xFFFDE7E9);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _precoController;
  late final TextEditingController _duracaoController;
  int? _categoriaId;
  bool _ativo = true;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.servico != null;

  @override
  void initState() {
    super.initState();
    final s = widget.servico;
    _nomeController = TextEditingController(text: s?.nome ?? '');
    _descricaoController = TextEditingController(text: s?.descricao ?? '');
    _precoController = TextEditingController(
      text: s == null ? '' : s.preco.replaceAll('.', ','),
    );
    _duracaoController = TextEditingController(
      text: s == null ? '' : '${s.duracaoMinutos}',
    );
    _categoriaId = s?.categoriaId;
    _ativo = s?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _duracaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final descricao = _descricaoController.text.trim();
    final corpo = <String, dynamic>{
      'categoria_id': _categoriaId,
      'nome': _nomeController.text.trim(),
      'descricao': descricao.isEmpty ? null : descricao,
      'preco': _precoController.text.trim().replaceAll(',', '.'),
      'duracao_minutos': int.parse(_duracaoController.text.trim()),
    };

    try {
      if (_editando) {
        corpo['ativo'] = _ativo;
        await ApiClient.instancia.patch('/servicos/${widget.servico!.id}', corpo);
      } else {
        await ApiClient.instancia.post('/servicos', corpo);
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
    String? prefixo,
    String? sufixo,
    IconData? icone,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: _corFundo,
      hintText: dica,
      hintStyle: TextStyle(color: _corSuave.withValues(alpha: .6), fontSize: 14),
      prefixText: prefixo,
      prefixStyle: const TextStyle(
        color: _corTexto,
        fontWeight: FontWeight.w600,
      ),
      suffixText: sufixo,
      suffixStyle: const TextStyle(color: _corSuave, fontSize: 13),
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

  Widget _campoPreco() {
    return _rotulado(
      'Preço',
      TextFormField(
        controller: _precoController,
        enabled: !_salvando,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(fontSize: 14, color: _corTexto),
        decoration: _decoracao(prefixo: 'R\$ ', dica: '80,00'),
        validator: (valor) {
          final texto = (valor ?? '').trim().replaceAll(',', '.');
          if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(texto)) {
            return 'Ex.: 80 ou 80,50';
          }
          if (double.parse(texto) <= 0) {
            return 'Deve ser maior que zero';
          }
          return null;
        },
      ),
    );
  }

  Widget _campoDuracao() {
    return _rotulado(
      'Duração',
      TextFormField(
        controller: _duracaoController,
        enabled: !_salvando,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        style: const TextStyle(fontSize: 14, color: _corTexto),
        decoration: _decoracao(sufixo: 'min', dica: '60'),
        validator: (valor) {
          final numero = int.tryParse((valor ?? '').trim());
          if (numero == null || numero <= 0) {
            return 'Informe os minutos';
          }
          return null;
        },
      ),
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
              _editando ? Icons.edit_outlined : Icons.spa_outlined,
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
                  _editando ? 'Editar serviço' : 'Novo serviço',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editando
                      ? 'Atualize os dados do serviço.'
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

  Widget _rodape(bool semCategorias) {
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
              onPressed: (_salvando || semCategorias) ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: PainelCores.vinho,
                foregroundColor: Colors.white,
                disabledBackgroundColor: PainelCores.vinho.withValues(alpha: .4),
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
                      _editando ? 'Salvar alterações' : 'Criar serviço',
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
    final opcoes = widget.categorias
        .where((c) => c.ativo || c.id == _categoriaId)
        .toList();

    final telaEstreita = MediaQuery.of(context).size.width < 400;

    final tema = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: PainelCores.vinho,
            onPrimary: Colors.white,
            surface: Colors.white,
            surfaceTint: Colors.transparent,
          ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: PainelCores.vinho,
        selectionColor: PainelCores.vinho.withValues(alpha: .2),
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (opcoes.isEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _corErroFundo,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Cadastre uma categoria ativa antes de criar um serviço.',
                              style: TextStyle(fontSize: 13, color: _corErro),
                            ),
                          ),
                        _rotulado(
                          'Categoria',
                          DropdownButtonFormField<int>(
                            initialValue: _categoriaId,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _corSuave,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'Selecione',
                              icone: Icons.category_outlined,
                            ),
                            items: opcoes
                                .map((c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.nome),
                                    ))
                                .toList(),
                            onChanged: _salvando
                                ? null
                                : (valor) =>
                                    setState(() => _categoriaId = valor),
                            validator: (valor) =>
                                valor == null ? 'Escolha uma categoria' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _rotulado(
                          'Nome do serviço',
                          TextFormField(
                            controller: _nomeController,
                            enabled: !_salvando,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'Ex.: Limpeza de pele',
                              icone: Icons.spa_outlined,
                            ),
                            validator: (valor) {
                              final texto = (valor ?? '').trim();
                              if (texto.length < 2) {
                                return 'Informe pelo menos 2 caracteres';
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
                          'Descrição',
                          TextFormField(
                            controller: _descricaoController,
                            enabled: !_salvando,
                            maxLines: 3,
                            minLines: 2,
                            maxLength: 255,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _corTexto,
                            ),
                            decoration: _decoracao(
                              dica: 'Conte o que está incluso no serviço',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (telaEstreita) ...[
                          _campoPreco(),
                          const SizedBox(height: 16),
                          _campoDuracao(),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _campoPreco()),
                              const SizedBox(width: 12),
                              Expanded(child: _campoDuracao()),
                            ],
                          ),
                        if (_editando) ...[
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Serviço ativo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _corTexto,
                                        ),
                                      ),
                                      Text(
                                        'Aparece para as clientes agendarem.',
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
                                  activeThumbColor: Colors.white,
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
              _rodape(opcoes.isEmpty),
            ],
            ),
          ),
        ),
      ),
    );
  }
}


class _DialogExcluirServico extends StatelessWidget {
  final ServicoModel servico;

  const _DialogExcluirServico({
    required this.servico,
  });

  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);
  static const _corFundo = Color(0xFFFFF8FA);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: PainelCores.vinho,
        onPrimary: Colors.white,
        surface: Colors.white,
        surfaceTint: Colors.transparent,
      ),
    );

    return Theme(
      data: tema,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
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
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: PainelCores.vinho,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Excluir serviço',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _corTexto,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Confirme esta ação.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _corSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _corSuave,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: _corBorda),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _corFundo,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _corBorda),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.spa_outlined,
                            color: PainelCores.vinho,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              servico.nome,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _corTexto,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deseja realmente excluir este serviço?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _corTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Se já houver agendamentos vinculados a ele, '
                      'o sistema não permitirá a exclusão. Nesse caso, '
                      'desative o serviço em vez de excluí-lo.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _corSuave,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PainelCores.vinho,
                          side: const BorderSide(color: _corBorda),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: PainelCores.vinho,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Excluir serviço',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
