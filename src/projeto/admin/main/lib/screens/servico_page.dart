import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:main/models/categoria_model.dart';
import 'package:main/models/servico_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

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

  Map<int, String> get _nomesCategoria => {
        for (final c in _categorias) c.id: c.nome,
      };

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
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir serviço',
      mensagem: 'Excluir "${servico.nome}"?\n'
          'Se já houver agendamentos com ele, o sistema não permite: desative em vez de excluir.',
    );
    if (!confirmou) return;

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
          resumo: '${_servicos.length} serviço(s)',
          rotuloBotao: 'Novo serviço',
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
    if (_servicos.isEmpty) {
      return const Center(child: Text('Nenhum serviço cadastrado.'));
    }

    final nomes = _nomesCategoria;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
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
                DataColumn(label: Text('Serviço')),
                DataColumn(label: Text('Categoria')),
                DataColumn(label: Text('Duração')),
                DataColumn(label: Text('Preço')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Ações')),
              ],
              rows: _servicos.map((s) {
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
                        activeColor: PainelCores.vinho,
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
      ),
    );
  }
}

class _FormularioServico extends StatefulWidget {
  final List<CategoriaModel> categorias;
  final ServicoModel? servico;

  const _FormularioServico({required this.categorias, this.servico});

  @override
  State<_FormularioServico> createState() => _FormularioServicoState();
}

class _FormularioServicoState extends State<_FormularioServico> {
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

  @override
  Widget build(BuildContext context) {
    final opcoes = widget.categorias
        .where((c) => c.ativo || c.id == _categoriaId)
        .toList();

    return AlertDialog(
      title: Text(_editando ? 'Editar serviço' : 'Novo serviço'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (opcoes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Cadastre uma categoria ativa antes de criar um serviço.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                DropdownButtonFormField<int>(
                  value: _categoriaId,
                  isExpanded: true,
                  decoration: decoracaoFormulario('Categoria'),
                  items: opcoes
                      .map((c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.nome),
                          ))
                      .toList(),
                  onChanged: _salvando
                      ? null
                      : (valor) => setState(() => _categoriaId = valor),
                  validator: (valor) =>
                      valor == null ? 'Escolha uma categoria' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomeController,
                  enabled: !_salvando,
                  decoration: decoracaoFormulario('Nome'),
                  validator: (valor) {
                    final texto = (valor ?? '').trim();
                    if (texto.length < 2) return 'Informe pelo menos 2 caracteres';
                    if (texto.length > 100) return 'No máximo 100 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoController,
                  enabled: !_salvando,
                  maxLines: 2,
                  maxLength: 255,
                  decoration: decoracaoFormulario('Descrição'),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precoController,
                        enabled: !_salvando,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: decoracaoFormulario('Preço', prefixo: 'R\$ '),
                        validator: (valor) {
                          final texto =
                              (valor ?? '').trim().replaceAll(',', '.');
                          if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(texto)) {
                            return 'Ex.: 80 ou 80,50';
                          }
                          if (double.parse(texto) <= 0) {
                            return 'Deve ser maior que zero';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _duracaoController,
                        enabled: !_salvando,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: decoracaoFormulario('Duração (min)'),
                        validator: (valor) {
                          final numero = int.tryParse((valor ?? '').trim());
                          if (numero == null || numero <= 0) {
                            return 'Informe os minutos';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (_editando)
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
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_salvando || opcoes.isEmpty) ? null : _salvar,
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