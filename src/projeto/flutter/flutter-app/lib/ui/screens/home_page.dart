import 'package:flutter/material.dart';
import 'package:main/ui/screens/servicos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _horarioDestaque = '14:30';

  String horarioSelecionado = '14:30';
  late DateTime dataSelecionada;
  final horarios = const [
    '09:00',
    '10:30',
    '14:30',
    '16:00',
    '17:00',
    '18:30',
    '19:30',
  ];

  static const corPrincipal = Color(0xFF8E2348);
  static const corFundo = Color(0xFFFFF8FA);
  static const corTexto = Color(0xFF4A1026);
  static const corSuave = Color(0xFFFFEEF3);
  static const corBorda = Color(0xFFF1DDE5);

  @override
  void initState() {
    super.initState();
    dataSelecionada = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        child: Column(
          children: [
            _cabecalho(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'ESTÉTICA & BELEZA',
                    style: TextStyle(
                      color: corPrincipal,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha o melhor\nhorário para você',
                    style: TextStyle(
                      fontSize: 29,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _cardDestaque(),
                  const SizedBox(height: 28),
                  _calendario(),
                  const SizedBox(height: 28),
                  Text(
                    'Horários livres para ${_formatarData(dataSelecionada)}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '●  7 horários livres',
                    style: TextStyle(color: corPrincipal),
                  ),
                  const SizedBox(height: 20),
                  _secaoDeHorarios('Manhã', horarios.take(2).toList()),
                  _secaoDeHorarios('Tarde', horarios.skip(2).toList()),
                ],
              ),
            ),
            _rodape(),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: corSuave,
                foregroundColor: corPrincipal,
                child: Icon(Icons.spa_outlined),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Studio Cleusa',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: corTexto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '1. Horário  •  2. Serviço  •  3. Seus dados  •  4. Confirmar  •  5. Status do agendamento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: corPrincipal),
          ),
        ],
      ),
    );
  }

  Widget _cardDestaque() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corPrincipal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISPONÍVEL AGORA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Próximo horário livre:',
            style: TextStyle(color: Color(0xFFFFD9E5)),
          ),
          const Text(
            'Hoje, 14:30',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('Janela de 2h30', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _escolherProximoHorario,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: corPrincipal,
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Escolher este horário'),
          ),
        ],
      ),
    );
  }

  /// Seleciona o horário exibido no destaque para a data atual e avança para
  /// a etapa de escolha do serviço.
  void _escolherProximoHorario() {
    final hoje = DateTime.now();
    final dataDeHoje = DateTime(hoje.year, hoje.month, hoje.day);

    setState(() {
      dataSelecionada = dataDeHoje;
      horarioSelecionado = _horarioDestaque;
    });

    _abrirServicos(data: dataDeHoje, horario: _horarioDestaque);
  }

  void _abrirServicos({required DateTime data, required String horario}) {
    Navigator.of(context).push(
      _InstantPageRoute(
        builder: (_) => ServicosPage(data: data, horario: horario),
      ),
    );
  }

  Widget _calendario() {
    final primeiroDia = dataSelecionada.subtract(
      Duration(days: dataSelecionada.weekday - 1),
    );
    final diasDaSemana = List.generate(
      7,
      (index) => primeiroDia.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _tituloMes(dataSelecionada).toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: corTexto,
                letterSpacing: .3,
              ),
            ),
            TextButton.icon(
              onPressed: _abrirCalendarioCompleto,
              style: TextButton.styleFrom(
                foregroundColor: corPrincipal,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text(
                'Ver calendário completo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: diasDaSemana.map((dia) {
            final selecionado = DateUtils.isSameDay(dia, dataSelecionada);
            final hoje = DateUtils.isSameDay(dia, DateTime.now());
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => dataSelecionada = dia),
                  child: Ink(
                    height: 70,
                    decoration: BoxDecoration(
                      color: selecionado ? corPrincipal : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selecionado ? corPrincipal : corBorda,
                        width: selecionado ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _siglaSemana(dia),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: selecionado
                                ? Colors.white
                                : const Color(0xFF9A8A90),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dia.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selecionado ? Colors.white : corTexto,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hoje ? 'Hoje' : '5 vagas',
                          style: TextStyle(
                            fontSize: 8,
                            color: selecionado ? Colors.white : corPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _abrirCalendarioCompleto() async {
    final dataTemporaria = ValueNotifier<DateTime>(dataSelecionada);

    try {
      final dataEscolhida = await showGeneralDialog<DateTime>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context)
            .modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: Duration.zero,
        pageBuilder: (contextoDoDialogo, _, _) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<DateTime>(
                  valueListenable: dataTemporaria,
                  builder: (context, data, _) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tituloMes(data),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: corTexto,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(contextoDoDialogo),
                        style: TextButton.styleFrom(foregroundColor: corTexto),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
                const Divider(color: corBorda),
                CalendarDatePicker(
                  initialDate: dataSelecionada,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  onDateChanged: (data) => dataTemporaria.value = data,
                ),
                const Text(
                  'Toque em um dia para atualizar a grade de horários disponíveis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<DateTime>(
                  valueListenable: dataTemporaria,
                  builder: (context, data, _) => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(contextoDoDialogo, data),
                      style: FilledButton.styleFrom(
                        backgroundColor: corPrincipal,
                      ),
                      child: Text('Selecionar dia ${data.day}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted || dataEscolhida == null) return;
      setState(() => dataSelecionada = dataEscolhida);
    } finally {
      dataTemporaria.dispose();
    }
  }

  Widget _secaoDeHorarios(String titulo, List<String> lista) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                titulo == 'Manhã'
                    ? Icons.wb_sunny_outlined
                    : Icons.wb_twilight_outlined,
                color: corPrincipal,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: corTexto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: lista.map((horario) {
              final selecionado = horario == horarioSelecionado;
              return ChoiceChip(
                label: Text(horario),
                selected: selecionado,
                showCheckmark: false,
                selectedColor: corSuave,
                side: BorderSide(color: selecionado ? corPrincipal : corBorda),
                onSelected: (_) => setState(() => horarioSelecionado = horario),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    const diasDaSemana = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${diasDaSemana[data.weekday - 1]}, ${data.day} de ${meses[data.month - 1]}';
  }

  String _tituloMes(DateTime data) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${meses[data.month - 1]} ${data.year}';
  }

  String _siglaSemana(DateTime data) {
    const siglas = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    return siglas[data.weekday - 1];
  }

  Widget _rodape() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selecionado: ${_formatarData(dataSelecionada)} · $horarioSelecionado',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _abrirServicos(
                data: dataSelecionada,
                horario: horarioSelecionado,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: corPrincipal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstantPageRoute<T> extends PageRouteBuilder<T> {
  _InstantPageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
}
