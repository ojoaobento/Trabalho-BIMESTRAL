import 'package:flutter/material.dart';

import 'package:main/models/agendamento_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

String _dois(int n) => n.toString().padLeft(2, '0');

String _formatarData(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

String _dataApi(DateTime d) => '${d.year}-${_dois(d.month)}-${_dois(d.day)}';

String _formatarHora(TimeOfDay t) => '${_dois(t.hour)}:${_dois(t.minute)}';

final Map<StatusAgendamento, Color> _coresStatus = {
  StatusAgendamento.reservado: Colors.blueGrey,
  StatusAgendamento.pendente: Colors.orange.shade800,
  StatusAgendamento.confirmado: Colors.green.shade700,
  StatusAgendamento.cancelado: Colors.red.shade700,
  StatusAgendamento.concluido: Colors.blue.shade700,
  StatusAgendamento.faltou: Colors.grey.shade700,
};

class _ChipStatus extends StatelessWidget {
  final StatusAgendamento status;

  const _ChipStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final cor = _coresStatus[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.rotulo,
        style: TextStyle(
          color: cor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AgendamentoPage extends StatefulWidget {
  const AgendamentoPage({super.key});

  @override
  State<AgendamentoPage> createState() => _AgendamentoPageState();
}

class _AgendamentoPageState extends State<AgendamentoPage> {
  List<AgendamentoModel> _agendamentos = [];
  bool _carregando = true;
  String? _erro;
  DateTimeRange? _periodo;
  StatusAgendamento? _statusFiltro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  List<AgendamentoModel> get _filtrados {
    if (_statusFiltro == null) return _agendamentos;
    return _agendamentos.where((a) => a.status == _statusFiltro).toList();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      var caminho = '/agendamentos';
      final periodo = _periodo;
      if (periodo != null) {
        final inicio = DateTime(
            periodo.start.year, periodo.start.month, periodo.start.day);
        // O fim da API é exclusivo, então vai até o começo do dia seguinte.
        final fim = DateTime(
            periodo.end.year, periodo.end.month, periodo.end.day + 1);
        caminho += '?inicio=${Uri.encodeQueryComponent(inicio.toUtc().toIso8601String())}'
            '&fim=${Uri.encodeQueryComponent(fim.toUtc().toIso8601String())}';
      }

      final dados = await ApiClient.instancia.get(caminho) as List;
      final lista = dados
          .map((e) => AgendamentoModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.dtInicio.compareTo(b.dtInicio));
      if (!mounted) return;
      setState(() {
        _agendamentos = lista;
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

  Future<void> _escolherPeriodo() async {
    final escolhido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDateRange: _periodo,
    );
    if (escolhido == null) return;
    setState(() => _periodo = escolhido);
    _carregar();
  }

  void _limparPeriodo() {
    setState(() => _periodo = null);
    _carregar();
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
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(rotulo),
          ),
        ],
      ),
    );
    return resposta == true;
  }

  Future<void> _alterarStatus(AgendamentoModel a, StatusAgendamento novo) async {
    if (novo == StatusAgendamento.cancelado) {
      final confirmou = await _confirmarAcao(
        'Cancelar agendamento',
        'Cancelar o agendamento de ${a.cliente?.nome ?? 'cliente'} '
            'em ${a.dataTexto} às ${a.horaInicioTexto}?\n'
            'O horário volta a ficar livre e os lembretes pendentes são removidos.',
        'Cancelar agendamento',
      );
      if (!confirmou) return;
    }

    try {
      await ApiClient.instancia
          .patch('/agendamentos/${a.id}/status', {'status': novo.valor});
      if (!mounted) return;
      mostrarMensagem(context, 'Status alterado para ${novo.rotulo.toLowerCase()}.');
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _remarcar(AgendamentoModel a) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioRemarcar(agendamento: a),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(context, 'Agendamento atualizado.');
      _carregar(silencioso: true);
    }
  }

  Future<void> _excluir(AgendamentoModel a) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir agendamento',
      mensagem: 'Excluir o agendamento de ${a.cliente?.nome ?? 'cliente'} '
          'em ${a.dataTexto}?\n'
          'Para manter o histórico, prefira cancelar. '
          'Se já houve lembretes enviados, o sistema não permite excluir.',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.delete('/agendamentos/${a.id}');
      if (!mounted) return;
      mostrarMensagem(context, 'Agendamento excluído.');
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
    final periodo = _periodo;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${_filtrados.length} agendamento(s)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: PainelCores.vinho,
          ),
        ),
        OutlinedButton.icon(
          onPressed: _escolherPeriodo,
          style: OutlinedButton.styleFrom(foregroundColor: PainelCores.vinho),
          icon: const Icon(Icons.date_range),
          label: Text(
            periodo == null
                ? 'Todo o período'
                : '${_formatarData(periodo.start)} – ${_formatarData(periodo.end)}',
                
          ), 
        ),
        if (periodo != null)
          IconButton(
            onPressed: _limparPeriodo,
            icon: const Icon(Icons.close),
            tooltip: 'Limpar período',
          ),
        DropdownButton<StatusAgendamento?>(
          value: _statusFiltro,
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos os status')),
            ...StatusAgendamento.values.map(
              (s) => DropdownMenuItem(value: s, child: Text(s.rotulo)),
            ),
          ],
          onChanged: (v) => setState(() => _statusFiltro = v),
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
    if (_agendamentos.isEmpty) {
      return const Center(child: Text('Nenhum agendamento encontrado.'));
    }

    final lista = _filtrados;
    if (lista.isEmpty) {
      return const Center(child: Text('Nenhum agendamento com esse status.'));
    }

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
                DataColumn(label: Text('Data')),
                DataColumn(label: Text('Horário')),
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Serviço')),
                DataColumn(label: Text('Valor')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Ações')),
              ],
              rows: lista.map((a) {
                final proximos = a.status.proximos;
                return DataRow(cells: [
                  DataCell(Text(a.dataTexto)),
                  DataCell(Text('${a.horaInicioTexto} – ${a.horaFimTexto}')),
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.cliente?.nome ?? '-'),
                      if (a.cliente != null)
                        Text(
                          a.cliente!.telefone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  )),
                  DataCell(Text(a.servico?.nome ?? '-')),
                  DataCell(Text(a.valorTexto)),
                  DataCell(_ChipStatus(status: a.status)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<StatusAgendamento>(
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: 'Alterar status',
                        enabled: proximos.isNotEmpty,
                        onSelected: (novo) => _alterarStatus(a, novo),
                        itemBuilder: (_) => proximos
                            .map((s) => PopupMenuItem(
                                  value: s,
                                  child: Text(
                                    s.rotulo,
                                    style: TextStyle(color: _coresStatus[s]),
                                  ),
                                ))
                            .toList(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined),
                        tooltip: 'Remarcar',
                        onPressed: a.podeRemarcar ? () => _remarcar(a) : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade700),
                        tooltip: 'Excluir',
                        onPressed: () => _excluir(a),
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

class _FormularioRemarcar extends StatefulWidget {
  final AgendamentoModel agendamento;

  const _FormularioRemarcar({required this.agendamento});

  @override
  State<_FormularioRemarcar> createState() => _FormularioRemarcarState();
}

class _FormularioRemarcarState extends State<_FormularioRemarcar> {
  final _dataController = TextEditingController();
  final _horaController = TextEditingController();
  late final TextEditingController _obsController;
  late DateTime _data;
  late TimeOfDay _hora;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final inicio = widget.agendamento.dtInicio.toLocal();
    _data = DateTime(inicio.year, inicio.month, inicio.day);
    _hora = TimeOfDay(hour: inicio.hour, minute: inicio.minute);
    _dataController.text = _formatarData(_data);
    _horaController.text = _formatarHora(_hora);
    _obsController =
        TextEditingController(text: widget.agendamento.observacoes ?? '');
  }

  @override
  void dispose() {
    _dataController.dispose();
    _horaController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data.isBefore(hoje) ? hoje : _data,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 1, hoje.month, hoje.day),
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

    final obs = _obsController.text.trim();
    try {
      await ApiClient.instancia.patch(
        '/agendamentos/${widget.agendamento.id}',
        {
          'data': _dataApi(_data),
          'hora': _formatarHora(_hora),
          'observacoes': obs.isEmpty ? null : obs,
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
    final a = widget.agendamento;
    final duracao = a.servico?.duracaoMinutos;

    return AlertDialog(
      title: const Text('Remarcar agendamento'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${a.cliente?.nome ?? 'Cliente'} • ${a.servico?.nome ?? 'Serviço'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (duracao != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Duração: $duracao min. O horário de término é calculado automaticamente.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _dataController,
                readOnly: true,
                enabled: !_salvando,
                onTap: _escolherData,
                decoration: decoracaoFormulario('Data').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _horaController,
                readOnly: true,
                enabled: !_salvando,
                onTap: _escolherHora,
                decoration: decoracaoFormulario('Horário de início').copyWith(
                  suffixIcon: const Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _obsController,
                enabled: !_salvando,
                maxLines: 3,
                maxLength: 500,
                decoration: decoracaoFormulario('Observações (opcional)'),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
            ],
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