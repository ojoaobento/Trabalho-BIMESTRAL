
import 'package:flutter/material.dart';
import 'package:main/data/agendamento_repository.dart';
import 'package:main/data/api_service.dart';
import 'package:main/models/horario_livre.dart';
import 'package:main/ui/screens/servicos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const corPrincipal = Color(0xFF8E2348);
  static const corFundo = Color(0xFFFFF8FA);
  static const corTexto = Color(0xFF4A1026);
  static const corSuave = Color(0xFFFFEEF3);
  static const corBorda = Color(0xFFF1DDE5);

  final _repositorio = AgendamentoRepository();

  late DateTime dataSelecionada;

  HorarioLivre? horarioSelecionado;

  List<HorarioLivre> _horarios = [];

  bool _carregando = true;
  String? _erro;

  int _requisicao = 0;

  HorarioLivre? _proximoHoje;
  bool _hojeCarregado = false;

  @override
  void initState() {
    super.initState();

    dataSelecionada = DateUtils.dateOnly(DateTime.now());

    _carregarHorarios();
  }

  @override
  void dispose() {
    _requisicao++;
    super.dispose();
  }

  Future<void> _carregarHorarios() async {
    final requisicao = ++_requisicao;
    final data = dataSelecionada;

    setState(() {
      _carregando = true;
      _erro = null;
      horarioSelecionado = null;
    });

    try {
      final resultado = await _repositorio.horariosLivres(data);

      final lista = _removerPassados(resultado, data);

      if (!mounted || requisicao != _requisicao) return;

      setState(() {
        _horarios = lista;
        _carregando = false;

        if (DateUtils.isSameDay(data, DateTime.now())) {
          _proximoHoje = lista.isEmpty ? null : lista.first;
          _hojeCarregado = true;
        }
      });
    } on ApiException catch (e) {
      if (!mounted || requisicao != _requisicao) return;

      setState(() {
        _erro = e.mensagem;
        _carregando = false;

        if (DateUtils.isSameDay(data, DateTime.now())) {
          _proximoHoje = null;
          _hojeCarregado = true;
        }
      });
    } catch (e) {
      if (!mounted || requisicao != _requisicao) return;

      debugPrint('Erro ao carregar horários: $e');

      setState(() {
        _erro = 'Não foi possível carregar os horários.';
        _carregando = false;

        if (DateUtils.isSameDay(data, DateTime.now())) {
          _proximoHoje = null;
          _hojeCarregado = true;
        }
      });
    }
  }

  List<HorarioLivre> _removerPassados(
    List<HorarioLivre> lista,
    DateTime data,
  ) {
    final agora = DateTime.now();

    if (!DateUtils.isSameDay(data, agora)) {
      return lista;
    }

    final minutosAgora = agora.hour * 60 + agora.minute;

    return lista.where((h) {
      return _minutos(h.horario) > minutosAgora;
    }).toList();
  }

  int _minutos(String horario) {
    final partes = horario.split(':');

    return int.parse(partes[0]) * 60 +
        int.parse(partes[1]);
  }

  void _selecionarData(DateTime data) {
    final dia = DateUtils.dateOnly(data);

    if (DateUtils.isSameDay(dia, dataSelecionada)) return;

    setState(() {
      dataSelecionada = dia;
    });

    _carregarHorarios();
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
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: corTexto,
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (!_carregando &&
                      _erro == null &&
                      _horarios.isNotEmpty)
                    Text(
                      '●  ${_horarios.length == 1 ? '1 horário livre' : '${_horarios.length} horários livres'}',
                      style: const TextStyle(color: corPrincipal),
                    ),

                  const SizedBox(height: 20),

                  _conteudoHorarios(),
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
            '1. Horário  •  2. Serviço  •  3. Seus dados  •  4. Confirmar  •  5. Status',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: corPrincipal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardDestaque() {
    final proximo = _proximoHoje;

    final String titulo;
    String? janela;

    if (!_hojeCarregado) {
      titulo = 'Buscando horários...';
    } else if (_erro != null &&
        DateUtils.isSameDay(dataSelecionada, DateTime.now())) {
      titulo = 'Indisponível no momento';
    } else if (proximo == null) {
      titulo = 'Sem horários livres hoje';
    } else {
      titulo = 'Hoje, ${proximo.horario}';
    }

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
            style: TextStyle(
              color: Color(0xFFFFD9E5),
            ),
          ),

          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (janela != null)
            Text(
              janela,
              style: const TextStyle(color: Colors.white70),
            ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: proximo == null
                ? null
                : _escolherProximoHorario,
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

  void _escolherProximoHorario() {
    final proximo = _proximoHoje;

    if (proximo == null) return;

    final hoje = DateUtils.dateOnly(DateTime.now());

    _abrirServicos(
      data: hoje,
      horario: proximo,
    );
  }

  void _abrirServicos({
    required DateTime data,
    required HorarioLivre horario,
  }) {
    Navigator.of(context).push(
      _InstantPageRoute(
        nome: 'servicos',
        builder: (_) => ServicosPage(
          data: data,
          horario: horario.horario,
          minutosLivres: horario.minutosLivres,
        ),
      ),
    );
  }

  Widget _calendario() {
    final base = dataSelecionada;

    final primeiroDia = DateTime(
      base.year,
      base.month,
      base.day - (base.weekday - 1),
    );

    final diasDaSemana = List.generate(
      7,
      (index) => DateTime(
        primeiroDia.year,
        primeiroDia.month,
        primeiroDia.day + index,
      ),
    );

    final hojeData = DateUtils.dateOnly(DateTime.now());

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
              icon: const Icon(
                Icons.calendar_month_outlined,
                size: 16,
              ),
              label: const Text(
                'Ver calendário completo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: diasDaSemana.map((dia) {
            final selecionado = DateUtils.isSameDay(
              dia,
              dataSelecionada,
            );

            final ehHoje = DateUtils.isSameDay(
              dia,
              hojeData,
            );

            final passado = dia.isBefore(hojeData);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: passado ? .4 : 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: passado
                        ? null
                        : () => _selecionarData(dia),
                    child: Ink(
                      height: 70,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? corPrincipal
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selecionado
                              ? corPrincipal
                              : corBorda,
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
                              color: selecionado
                                  ? Colors.white
                                  : corTexto,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            ehHoje ? 'Hoje' : '',
                            style: TextStyle(
                              fontSize: 8,
                              color: selecionado
                                  ? Colors.white
                                  : corPrincipal,
                            ),
                          ),
                        ],
                      ),
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
    final hoje = DateUtils.dateOnly(DateTime.now());

    final dataInicial = dataSelecionada.isBefore(hoje)
        ? hoje
        : dataSelecionada;

    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: corPrincipal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: corTexto,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || dataEscolhida == null) return;

    _selecionarData(dataEscolhida);
  }

  Widget _conteudoHorarios() {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            color: corPrincipal,
          ),
        ),
      );
    }

    if (_erro != null) {
      return _cartaoMensagem(
        _erro!,
        acao: TextButton(
          onPressed: _carregarHorarios,
          style: TextButton.styleFrom(
            foregroundColor: corPrincipal,
          ),
          child: const Text('Tentar de novo'),
        ),
      );
    }

    if (_horarios.isEmpty) {
      return _cartaoMensagem(
        'Não há horários livres neste dia. Escolha outra data.',
      );
    }

    final manha = _horarios
        .where((h) => _minutos(h.horario) < 12 * 60)
        .toList();

    final tarde = _horarios
        .where((h) => _minutos(h.horario) >= 12 * 60)
        .toList();

    return Column(
      children: [
        if (manha.isNotEmpty)
          _secaoDeHorarios('Manhã', manha),

        if (tarde.isNotEmpty)
          _secaoDeHorarios('Tarde', tarde),
      ],
    );
  }

  Widget _cartaoMensagem(
    String texto, {
    Widget? acao,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda),
      ),
      child: Column(
        children: [
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: corTexto),
          ),

          if (acao != null) acao,
        ],
      ),
    );
  }

  Widget _secaoDeHorarios(
    String titulo,
    List<HorarioLivre> lista,
  ) {
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
            children: lista.map((h) {
              final selecionado =
                  h.horario == horarioSelecionado?.horario;

              return ChoiceChip(
                label: Text(h.horario),
                selected: selecionado,
                showCheckmark: false,
                selectedColor: corSuave,
                side: BorderSide(
                  color: selecionado
                      ? corPrincipal
                      : corBorda,
                ),
                onSelected: (_) {
                  setState(() {
                    horarioSelecionado = h;
                  });
                },
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
    const siglas = [
      'SEG',
      'TER',
      'QUA',
      'QUI',
      'SEX',
      'SÁB',
      'DOM',
    ];

    return siglas[data.weekday - 1];
  }

  Widget _rodape() {
    final selecionado = horarioSelecionado;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selecionado == null
                ? 'Selecione um horário para continuar'
                : 'Selecionado: ${_formatarData(dataSelecionada)} · ${selecionado.horario}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selecionado == null
                  ? null
                  : () => _abrirServicos(
                        data: dataSelecionada,
                        horario: selecionado,
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
  _InstantPageRoute({
    required WidgetBuilder builder,
    String? nome,
  }) : super(
          settings: RouteSettings(name: nome),
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}
