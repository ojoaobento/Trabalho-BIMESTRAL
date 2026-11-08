import 'package:flutter/material.dart';

import 'package:main/models/disponibilidade_model.dart';
import 'package:main/models/bloqueio_model.dart';
import 'package:main/services/api_client.dart';
import 'package:main/widgets/painel_widgets.dart';

const double _larguraMinimaTabela = 720;

const _nomesDias = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

String _formatarHora(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _lerHora(String texto) => TimeOfDay(
      hour: int.parse(texto.substring(0, 2)),
      minute: int.parse(texto.substring(3, 5)),
    );

int _minutos(TimeOfDay t) => t.hour * 60 + t.minute;

class DisponibilidadePage extends StatefulWidget {
  const DisponibilidadePage({super.key});

  @override
  State<DisponibilidadePage> createState() => _DisponibilidadePageState();
}

class _DisponibilidadePageState extends State<DisponibilidadePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<DisponibilidadeModel> _blocos = [];
  List<BloqueioModel> _bloqueios = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        ApiClient.instancia.get('/disponibilidades') as Future<dynamic>,
        ApiClient.instancia.get('/bloqueios') as Future<dynamic>,
      ]);

      final dadosDisponibilidade = resultados[0] as List;
      final dadosBloqueios = resultados[1] as List;

      final lista = dadosDisponibilidade
          .map((e) => DisponibilidadeModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) {
          final porDia = a.diaSemana.compareTo(b.diaSemana);
          return porDia != 0 ? porDia : a.horaInicio.compareTo(b.horaInicio);
        });

      final listaBloqueios = dadosBloqueios
          .map((e) => BloqueioModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _blocos = lista;
        _bloqueios = listaBloqueios;
        _carregando = false;
        _erro = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar dados de disponibilidade.';
        _carregando = false;
      });
    }
  }

  Future<void> _abrirFormulario({DisponibilidadeModel? bloco}) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioDisponibilidade(bloco: bloco),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(
        context,
        bloco == null ? 'Horário criado.' : 'Horário atualizado.',
      );
      _carregar(silencioso: true);
    }
  }

  Future<void> _abrirFormularioBloqueio() async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => const _FormularioBloqueio(),
    );
    if (salvou == true) {
      if (!mounted) return;
      mostrarMensagem(context, 'Horário bloqueado com sucesso.');
      _carregar(silencioso: true);
    }
  }

  Future<void> _alternarAtivo(DisponibilidadeModel bloco, bool novoValor) async {
    try {
      await ApiClient.instancia
          .patch('/disponibilidades/${bloco.id}', {'ativo': novoValor});
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _excluir(DisponibilidadeModel bloco) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir horário',
      mensagem: 'Excluir o bloco de ${bloco.nomeDia}, '
          '${bloco.inicioCurto} às ${bloco.fimCurto}?',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.delete('/disponibilidades/${bloco.id}');
      if (!mounted) return;
      mostrarMensagem(context, 'Horário excluído.');
      await _carregar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _excluirBloqueio(BloqueioModel b) async {
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Remover bloqueio',
      mensagem: 'Desbloquear o horário de ${b.dataTexto} '
          'das ${b.horaInicioTexto} às ${b.horaFimTexto}?\n'
          'Esse horário voltará a ficar disponível para agendamento.',
    );
    if (!confirmou) return;

    try {
      await ApiClient.instancia.delete('/bloqueios/${b.id}');
      if (!mounted) return;
      mostrarMensagem(context, 'Bloqueio removido.');
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: PainelCores.vinho,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: PainelCores.vinho,
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_view_week, size: 18),
                      const SizedBox(width: 8),
                      Text('Horários Semanais (${_blocos.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.block, size: 18),
                      const SizedBox(width: 8),
                      Text('Horários Bloqueados (${_bloqueios.length})'),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _abrirFormularioBloqueio,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Bloquear Horário'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _abrirFormulario(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PainelCores.vinho,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Novo Bloco Semanal'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _conteudoSemanal(),
              _conteudoBloqueios(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _conteudoSemanal() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: PainelCores.vinho),
      );
    }
    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, onTentarNovamente: _carregar);
    }
    if (_blocos.isEmpty) {
      return const Center(child: Text('Nenhum horário semanal cadastrado.'));
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

  Widget _conteudoBloqueios() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: PainelCores.vinho),
      );
    }
    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, onTentarNovamente: _carregar);
    }
    if (_bloqueios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Nenhum horário bloqueado pontualmente.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use o botão "Bloquear Horário" acima para cancelar ou fechar um horário específico do dia.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Horário')),
                  DataColumn(label: Text('Motivo')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: _bloqueios.map((b) {
                  return DataRow(cells: [
                    DataCell(Text(b.dataTexto)),
                    DataCell(Text('${b.horaInicioTexto} às ${b.horaFimTexto}')),
                    DataCell(Text(b.motivo ?? 'Bloqueio administrativo')),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                        tooltip: 'Desbloquear horário',
                        onPressed: () => _excluirBloqueio(b),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
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
              DataColumn(label: Text('Dia')),
              DataColumn(label: Text('Início')),
              DataColumn(label: Text('Fim')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: _blocos.map((b) {
              return DataRow(cells: [
                DataCell(Text(b.nomeDia)),
                DataCell(Text(b.inicioCurto)),
                DataCell(Text(b.fimCurto)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: b.ativo,
                      activeColor: PainelCores.vinho,
                      onChanged: (valor) => _alternarAtivo(b, valor),
                    ),
                    StatusChip(ativo: b.ativo),
                  ],
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar',
                      onPressed: () => _abrirFormulario(bloco: b),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade700),
                      tooltip: 'Excluir',
                      onPressed: () => _excluir(b),
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
      itemCount: _blocos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoBloco(_blocos[i]),
    );
  }

  Widget _cartaoBloco(DisponibilidadeModel b) {
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
                    b.nomeDia,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: PainelCores.vinho,
                    ),
                  ),
                ),
                StatusChip(ativo: b.ativo),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${b.inicioCurto} às ${b.fimCurto}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => _abrirFormulario(bloco: b),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade700),
                  tooltip: 'Excluir',
                  onPressed: () => _excluir(b),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioBloqueio extends StatefulWidget {
  const _FormularioBloqueio();

  @override
  State<_FormularioBloqueio> createState() => _FormularioBloqueioState();
}

class _FormularioBloqueioState extends State<_FormularioBloqueio> {
  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();
  final _inicioController = TextEditingController();
  final _fimController = TextEditingController();
  final _motivoController = TextEditingController(text: 'Indisponibilidade / Pausa');

  DateTime _data = DateTime.now();
  TimeOfDay _inicio = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _fim = const TimeOfDay(hour: 15, minute: 0);
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _dataController.text =
        '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}';
    _inicioController.text = _formatarHora(_inicio);
    _fimController.text = _formatarHora(_fim);
  }

  @override
  void dispose() {
    _dataController.dispose();
    _inicioController.dispose();
    _fimController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (escolhida != null) {
      setState(() {
        _data = escolhida;
        _dataController.text =
            '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}';
      });
    }
  }

  Future<void> _escolherHorario({required bool inicio}) async {
    final atual = inicio ? _inicio : _fim;
    final escolhido = await showTimePicker(
      context: context,
      initialTime: atual,
    );
    if (escolhido != null) {
      setState(() {
        if (inicio) {
          _inicio = escolhido;
          _inicioController.text = _formatarHora(escolhido);
        } else {
          _fim = escolhido;
          _fimController.text = _formatarHora(escolhido);
        }
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_minutos(_fim) <= _minutos(_inicio)) {
      setState(() => _erro = 'O horário de fim deve ser posterior ao início.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final dataIso =
        '${_data.year}-${_data.month.toString().padLeft(2, '0')}-${_data.day.toString().padLeft(2, '0')}';

    final corpo = {
      'data': dataIso,
      'hora_inicio': '${_formatarHora(_inicio)}:00',
      'hora_fim': '${_formatarHora(_fim)}:00',
      'motivo': _motivoController.text.trim(),
    };

    try {
      await ApiClient.instancia.post('/bloqueios', corpo);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = e.mensagem;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Erro ao salvar o bloqueio.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bloquear Horário / Intervalo'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bloqueie um horário específico do dia para que clientes não possam agendar nele.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dataController,
                readOnly: true,
                onTap: _escolherData,
                decoration: decoracaoFormulario('Data').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _inicioController,
                      readOnly: true,
                      onTap: () => _escolherHorario(inicio: true),
                      decoration: decoracaoFormulario('Início').copyWith(
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fimController,
                      readOnly: true,
                      onTap: () => _escolherHorario(inicio: false),
                      decoration: decoracaoFormulario('Fim').copyWith(
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motivoController,
                decoration: decoracaoFormulario('Motivo / Observação'),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_erro!, style: TextStyle(color: Colors.red.shade700)),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirmar Bloqueio'),
        ),
      ],
    );
  }
}

class _FormularioDisponibilidade extends StatefulWidget {
  final DisponibilidadeModel? bloco;

  const _FormularioDisponibilidade({this.bloco});

  @override
  State<_FormularioDisponibilidade> createState() =>
      _FormularioDisponibilidadeState();
}

class _FormularioDisponibilidadeState
    extends State<_FormularioDisponibilidade> {
  final _formKey = GlobalKey<FormState>();
  late int? _dia;
  TimeOfDay? _inicio;
  TimeOfDay? _fim;
  bool _ativo = true;
  bool _salvando = false;
  String? _erro;

  final _inicioController = TextEditingController();
  final _fimController = TextEditingController();

  bool get _editando => widget.bloco != null;

  @override
  void initState() {
    super.initState();
    final b = widget.bloco;
    if (b != null) {
      _dia = b.diaSemana;
      _inicio = _lerHora(b.horaInicio);
      _fim = _lerHora(b.horaFim);
      _ativo = b.ativo;
      _inicioController.text = _formatarHora(_inicio!);
      _fimController.text = _formatarHora(_fim!);
    } else {
      _dia = 0;
      _inicio = const TimeOfDay(hour: 8, minute: 0);
      _fim = const TimeOfDay(hour: 18, minute: 0);
      _inicioController.text = _formatarHora(_inicio!);
      _fimController.text = _formatarHora(_fim!);
    }
  }

  @override
  void dispose() {
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  Future<void> _escolherHorario({required bool inicio}) async {
    final atual = inicio ? _inicio : _fim;
    final escolhido = await showTimePicker(
      context: context,
      initialTime: atual ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (escolhido == null) return;
    setState(() {
      if (inicio) {
        _inicio = escolhido;
        _inicioController.text = _formatarHora(escolhido);
      } else {
        _fim = escolhido;
        _fimController.text = _formatarHora(escolhido);
      }
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final corpo = <String, dynamic>{
      'dia_semana': _dia,
      'hora_inicio': '${_formatarHora(_inicio!)}:00',
      'hora_fim': '${_formatarHora(_fim!)}:00',
      'ativo': _ativo,
    };

    try {
      if (_editando) {
        await ApiClient.instancia
            .patch('/disponibilidades/${widget.bloco!.id}', corpo);
      } else {
        await ApiClient.instancia.post('/disponibilidades', corpo);
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
      title: Text(_editando ? 'Editar horário' : 'Novo horário'),
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
                  DropdownButtonFormField<int>(
                    value: _dia,
                    isExpanded: true,
                    decoration: decoracaoFormulario('Dia da semana'),
                    items: List.generate(
                      7,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(_nomesDias[i]),
                      ),
                    ),
                    onChanged:
                        _salvando ? null : (v) => setState(() => _dia = v),
                    validator: (v) => v == null ? 'Escolha o dia' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _inicioController,
                    readOnly: true,
                    enabled: !_salvando,
                    onTap: () => _escolherHorario(inicio: true),
                    decoration: decoracaoFormulario('Início').copyWith(
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    validator: (valor) => (valor ?? '').isEmpty
                        ? 'Informe o horário de início'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fimController,
                    readOnly: true,
                    enabled: !_salvando,
                    onTap: () => _escolherHorario(inicio: false),
                    decoration: decoracaoFormulario('Fim').copyWith(
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    validator: (valor) {
                      if ((valor ?? '').isEmpty) {
                        return 'Informe o horário de fim';
                      }
                      if (_inicio != null &&
                          _fim != null &&
                          _minutos(_fim!) <= _minutos(_inicio!)) {
                        return 'O fim deve ser depois do início';
                      }
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
