import 'package:flutter/material.dart';

import 'package:main/models/lembrete_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

const double _larguraMinimaTabela = 720;

String _dois(int n) => n.toString().padLeft(2, '0');

String _formatarData(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

String _formatarHora(TimeOfDay t) => '${_dois(t.hour)}:${_dois(t.minute)}';

String _formatarDataHora(DateTime d) {
  final l = d.toLocal();
  return '${_formatarData(l)} às ${_dois(l.hour)}:${_dois(l.minute)}';
}

const Map<TipoLembrete, String> _rotulosTipo = {
  TipoLembrete.confirmacao: 'Confirmação',
  TipoLembrete.lembrete24h: 'Lembrete 24h',
};

enum _Situacao {
  agendado('Agendado'),
  naFila('Na fila'),
  enviado('Enviado');

  final String rotulo;
  const _Situacao(this.rotulo);
}

_Situacao _situacaoDe(LembreteModel l) {
  if (l.enviado) return _Situacao.enviado;
  if (!l.enviarEm.isAfter(DateTime.now())) return _Situacao.naFila;
  return _Situacao.agendado;
}

final Map<_Situacao, Color> _coresSituacao = {
  _Situacao.agendado: Colors.blueGrey,
  _Situacao.naFila: Colors.orange.shade800,
  _Situacao.enviado: Colors.green.shade700,
};

class _ChipSituacao extends StatelessWidget {
  final _Situacao situacao;

  const _ChipSituacao({required this.situacao});

  @override
  Widget build(BuildContext context) {
    final cor = _coresSituacao[situacao]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        situacao.rotulo,
        style: TextStyle(
          color: cor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LembretePage extends StatefulWidget {
  const LembretePage({super.key});

  @override
  State<LembretePage> createState() => _LembretePageState();
}

class _LembretePageState extends State<LembretePage> {
  List<LembreteModel> _lembretes = [];
  bool _carregando = true;
  String? _erro;
  _Situacao? _situacaoFiltro;
  TipoLembrete? _tipoFiltro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  List<LembreteModel> get _filtrados {
    return _lembretes.where((l) {
      if (_situacaoFiltro != null && _situacaoDe(l) != _situacaoFiltro) {
        return false;
      }
      if (_tipoFiltro != null && l.tipo != _tipoFiltro) return false;
      return true;
    }).toList();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final dados = await ApiClient.instancia.get('/lembretes') as List;
      final lista = dados
          .map((e) => LembreteModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.enviarEm.compareTo(a.enviarEm));
      if (!mounted) return;
      setState(() {
        _lembretes = lista;
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

  Future<bool> _confirmarAcao(String titulo, String mensagem, String rotulo) async {
    final resposta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PainelCores.vinho,
              foregroundColor: Colors.white,
            ),
            child: Text(rotulo),
          ),
        ],
      ),
    );
    return resposta == true;
  }

  Future<void> _marcarEnviado(LembreteModel l) async {
    final confirmou = await _confirmarAcao(
      'Marcar como enviado',
      'Marcar este lembrete como enviado?\n'
          'O e-mail não será mais disparado pela automação.',
      'Marcar como enviado',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.patch('/lembretes/${l.id}/enviado', {});
      if (!mounted) return;
      mostrarMensagem(context, 'Lembrete marcado como enviado.');
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _editar(LembreteModel l) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioEditarLembrete(lembrete: l),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(context, 'Lembrete atualizado.');
      _carregar(silencioso: true);
    }
  }

  Future<void> _excluir(LembreteModel l) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir lembrete',
      mensagem: 'Excluir o lembrete #${l.id} do agendamento #${l.agendamentoId}?\n'
          'Ele não será mais enviado ao cliente.',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.delete('/lembretes/${l.id}');
      if (!mounted) return;
      mostrarMensagem(context, 'Lembrete excluído.');
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
        _cabecalho(),
        const SizedBox(height: 16),
        Expanded(child: _conteudo()),
      ],
    );
  }

  Widget _cabecalho() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${_filtrados.length} lembrete(s)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: PainelCores.vinho,
          ),
        ),
        DropdownButton<_Situacao?>(
          value: _situacaoFiltro,
          isDense: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas as situações')),
            ..._Situacao.values.map(
              (s) => DropdownMenuItem(value: s, child: Text(s.rotulo)),
            ),
          ],
          onChanged: (v) => setState(() => _situacaoFiltro = v),
        ),
        DropdownButton<TipoLembrete?>(
          value: _tipoFiltro,
          isDense: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos os tipos')),
            ...TipoLembrete.values.map(
              (t) => DropdownMenuItem(value: t, child: Text(_rotulosTipo[t]!)),
            ),
          ],
          onChanged: (v) => setState(() => _tipoFiltro = v),
        ),
        IconButton(
          onPressed: () => _carregar(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
        ),
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
    if (_lembretes.isEmpty) {
      return const Center(child: Text('Nenhum lembrete encontrado.'));
    }

    final lista = _filtrados;
    if (lista.isEmpty) {
      return const Center(child: Text('Nenhum lembrete com esse filtro.'));
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

  Widget _tabela(BoxConstraints constraints, List<LembreteModel> lista) {
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
              DataColumn(label: Text('Envio programado')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Agendamento')),
              DataColumn(label: Text('Serviço')),
              DataColumn(label: Text('Situação')),
              DataColumn(label: Text('Enviado em')),
              DataColumn(label: Text('Ações')),
            ],
            rows: lista.map((l) {
              return DataRow(cells: [
                DataCell(Text(_formatarDataHora(l.enviarEm))),
                DataCell(Text(_rotulosTipo[l.tipo]!)),
                DataCell(Text('#${l.agendamentoId}')),
                DataCell(Text(l.servicoId != null ? '#${l.servicoId}' : '-')),
                DataCell(_ChipSituacao(situacao: _situacaoDe(l))),
                DataCell(Text(
                  l.enviadoEm != null ? _formatarDataHora(l.enviadoEm!) : '-',
                )),
                DataCell(_acoes(l)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _acoes(LembreteModel l) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.mark_email_read_outlined),
          tooltip: 'Marcar como enviado',
          onPressed: l.enviado ? null : () => _marcarEnviado(l),
        ),
        IconButton(
          icon: const Icon(Icons.edit_calendar_outlined),
          tooltip: 'Editar',
          onPressed: l.enviado ? null : () => _editar(l),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
          tooltip: 'Excluir',
          onPressed: () => _excluir(l),
        ),
      ],
    );
  }

  Widget _listaCards(List<LembreteModel> lista) {
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoLembrete(lista[i]),
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

  Widget _cartaoLembrete(LembreteModel l) {
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
                    _rotulosTipo[l.tipo]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: _ChipSituacao(situacao: _situacaoDe(l)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _info(Icons.schedule, _formatarDataHora(l.enviarEm)),
                _info(Icons.event_note_outlined, 'Agendamento #${l.agendamentoId}'),
                if (l.servicoId != null)
                  _info(Icons.spa_outlined, 'Serviço #${l.servicoId}'),
              ],
            ),
            if (l.enviadoEm != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Enviado em ${_formatarDataHora(l.enviadoEm!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: _acoes(l),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioEditarLembrete extends StatefulWidget {
  final LembreteModel lembrete;

  const _FormularioEditarLembrete({required this.lembrete});

  @override
  State<_FormularioEditarLembrete> createState() =>
      _FormularioEditarLembreteState();
}

class _FormularioEditarLembreteState extends State<_FormularioEditarLembrete> {
  final _dataController = TextEditingController();
  final _horaController = TextEditingController();
  late DateTime _data;
  late TimeOfDay _hora;
  late TipoLembrete _tipo;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final envio = widget.lembrete.enviarEm.toLocal();
    _data = DateTime(envio.year, envio.month, envio.day);
    _hora = TimeOfDay(hour: envio.hour, minute: envio.minute);
    _tipo = widget.lembrete.tipo;
    _dataController.text = _formatarData(_data);
    _horaController.text = _formatarHora(_hora);
  }

  @override
  void dispose() {
    _dataController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (escolhida == null) return;
    setState(() {
      _data = escolhida;
      _dataController.text = _formatarData(escolhida);
    });
  }

  Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (escolhida == null) return;
    setState(() {
      _hora = escolhida;
      _horaController.text = _formatarHora(escolhida);
    });
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });

    final novoEnvio = DateTime(
      _data.year,
      _data.month,
      _data.day,
      _hora.hour,
      _hora.minute,
    );

    try {
      await ApiClient.instancia.patch(
        '/lembretes/${widget.lembrete.id}',
        {
          'enviar_em': novoEnvio.toUtc().toIso8601String(),
          'tipo': _tipo.valor,
        },
      );
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
    final l = widget.lembrete;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Editar lembrete'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lembrete #${l.id} • Agendamento #${l.agendamentoId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TipoLembrete>(
                  value: _tipo,
                  isExpanded: true,
                  decoration: decoracaoFormulario('Tipo'),
                  items: TipoLembrete.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_rotulosTipo[t]!),
                          ))
                      .toList(),
                  onChanged: _salvando
                      ? null
                      : (v) {
                          if (v != null) setState(() => _tipo = v);
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dataController,
                  readOnly: true,
                  enabled: !_salvando,
                  onTap: _escolherData,
                  decoration: decoracaoFormulario('Data de envio').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _horaController,
                  readOnly: true,
                  enabled: !_salvando,
                  onTap: _escolherHora,
                  decoration: decoracaoFormulario('Horário de envio').copyWith(
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                ),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
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