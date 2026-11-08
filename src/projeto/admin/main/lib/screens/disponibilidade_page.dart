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

const _diasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String _formatarHora(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _lerHora(String texto) => TimeOfDay(
      hour: int.parse(texto.substring(0, 2)),
      minute: int.parse(texto.substring(3, 5)),
    );

int _minutos(TimeOfDay t) => t.hour * 60 + t.minute;

String _formatarDataCampo(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';


Widget _temaSeletor(BuildContext context, Widget? child) {
  final base = Theme.of(context);
  const vinho = PainelCores.vinho;

  return Theme(
    data: base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: vinho,
        onPrimary: Colors.white,
        surface: Colors.white,
        surfaceTint: Colors.transparent,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: vinho),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        headerBackgroundColor: vinho,
        headerForegroundColor: Colors.white,
        todayBorder: const BorderSide(color: vinho),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected) ? Colors.white : vinho,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected) ? vinho : Colors.transparent,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected) ? vinho : Colors.transparent,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        dialHandColor: vinho,
        dialBackgroundColor: const Color(0xFFFFF0F4),
        entryModeIconColor: vinho,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? vinho.withValues(alpha: 0.12)
              : Colors.grey.shade100,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? vinho
              : Colors.grey.shade800,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? vinho.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? vinho
              : Colors.grey.shade700,
        ),
      ),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

String _duracaoTexto(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  if (h == 0) return '${m}min';
  if (m == 0) return '${h}h';
  return '${h}h${m.toString().padLeft(2, '0')}min';
}


const _corFundo = Color(0xFFFFF8FA);
const _corTexto = Color(0xFF4A1026);
const _corSuave = Color(0xFF976D7B);
const _corBorda = Color(0xFFF1DDE5);
const _corErro = Color(0xFFB3261E);
const _corErroFundo = Color(0xFFFDE7E9);

OutlineInputBorder _borda(Color cor, {double largura = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: cor, width: largura),
  );
}

InputDecoration _decoracaoForm({String? dica, IconData? icone}) {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: _corFundo,
    hintText: dica,
    hintStyle: TextStyle(color: _corSuave.withValues(alpha: .6), fontSize: 14),
    prefixIcon:
        icone == null ? null : Icon(icone, size: 18, color: PainelCores.vinho),
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

Widget _chipOpcao({
  required String rotulo,
  required bool selecionado,
  required VoidCallback? onTap,
  IconData? icone,
}) {
  return ChoiceChip(
    showCheckmark: false,
    selected: selecionado,
    onSelected: onTap == null ? null : (_) => onTap(),
    selectedColor: PainelCores.vinho.withValues(alpha: 0.12),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    side: BorderSide(
      color: selecionado ? PainelCores.vinho : _corBorda,
      width: selecionado ? 1.4 : 1,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    visualDensity: VisualDensity.compact,
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          Icon(
            icone,
            size: 15,
            color: selecionado ? PainelCores.vinho : _corSuave,
          ),
          const SizedBox(width: 5),
        ],
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
            color: selecionado ? PainelCores.vinho : _corTexto,
          ),
        ),
      ],
    ),
  );
}

class _BannerErro extends StatelessWidget {
  final String mensagem;

  const _BannerErro(this.mensagem);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Icon(Icons.error_outline, size: 18, color: _corErro),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(fontSize: 13, color: _corErro),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlocoSwitch extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool valor;
  final ValueChanged<bool>? onChanged;

  const _BlocoSwitch({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
      decoration: BoxDecoration(
        color: _corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _corBorda),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _corTexto,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 12, color: _corSuave),
                ),
              ],
            ),
          ),
          Switch(
            value: valor,
            activeThumbColor: Colors.white,
            activeTrackColor: PainelCores.vinho,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _corBorda,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CabecalhoDialogo extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final Color corFundoIcone;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onFechar;

  const _CabecalhoDialogo({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onFechar,
    this.corIcone = PainelCores.vinho,
    this.corFundoIcone = const Color(0xFFFFEEF3),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: corFundoIcone,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: corIcone, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 12, color: _corSuave),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: onFechar,
            icon: const Icon(Icons.close_rounded, color: _corSuave),
          ),
        ],
      ),
    );
  }
}

class _RodapeDialogo extends StatelessWidget {
  final bool salvando;
  final String rotuloSalvar;
  final VoidCallback onSalvar;
  final VoidCallback onCancelar;

  const _RodapeDialogo({
    required this.salvando,
    required this.rotuloSalvar,
    required this.onSalvar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: salvando ? null : onCancelar,
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
              onPressed: salvando ? null : onSalvar,
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
              child: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      rotuloSalvar,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoPadrao extends StatelessWidget {
  final Widget cabecalho;
  final Widget corpo;
  final Widget rodape;

  const _DialogoPadrao({
    required this.cabecalho,
    required this.corpo,
    required this.rodape,
  });

  @override
  Widget build(BuildContext context) {
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
                cabecalho,
                const Divider(height: 1, color: _corBorda),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: corpo,
                ),
                rodape,
              ],
            ),
          ),
        ),
      ),
    );
  }
}


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
        ApiClient.instancia.get('/disponibilidades'),
        ApiClient.instancia.get('/bloqueios'),
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

  Future<bool> _confirmarExclusaoPersonalizada({
    required String titulo,
    required String mensagem,
    required String textoAcao,
  }) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
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
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE7E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFB3261E),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A1026),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    mensagem,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF795563),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF1DDE5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 19,
                          color: PainelCores.vinho,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Essa ação não poderá ser desfeita.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF795563),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PainelCores.vinho,
                            side: const BorderSide(
                              color: Color(0xFFF1DDE5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB3261E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                          ),
                          label: Text(
                            textoAcao,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return confirmou == true;
  }

  Future<void> _excluir(DisponibilidadeModel bloco) async {
    final confirmou = await _confirmarExclusaoPersonalizada(
      titulo: 'Excluir horário?',
      mensagem: 'Deseja realmente excluir o horário de '
          '${bloco.nomeDia}, das ${bloco.inicioCurto} às ${bloco.fimCurto}?',
      textoAcao: 'Excluir',
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
    final confirmou = await _confirmarExclusaoPersonalizada(
      titulo: 'Remover bloqueio?',
      mensagem: 'Deseja desbloquear o horário de ${b.dataTexto}, '
          'das ${b.horaInicioTexto} às ${b.horaFimTexto}?\n\n'
          'Esse horário voltará a ficar disponível para agendamento.',
      textoAcao: 'Desbloquear',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final estreito = constraints.maxWidth < _larguraMinimaTabela;

        final tabBar = TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: PainelCores.vinho,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: PainelCores.vinho,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_view_week, size: 18),
                  const SizedBox(width: 8),
                  Text('Semanais (${_blocos.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 18),
                  const SizedBox(width: 8),
                  Text('Bloqueados (${_bloqueios.length})'),
                ],
              ),
            ),
          ],
        );

        final botoes = Wrap(
          spacing: 8,
          runSpacing: 8,
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
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estreito) ...[
              tabBar,
              const SizedBox(height: 12),
              botoes,
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: tabBar),
                  const SizedBox(width: 16),
                  botoes,
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
      },
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Nenhum horário bloqueado pontualmente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use o botão "Bloquear Horário" acima para cancelar ou fechar um horário específico do dia.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _larguraMinimaTabela) {
          return _listaCardsBloqueios();
        }
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
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade700),
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
                      activeThumbColor: Colors.white,
                      activeTrackColor: PainelCores.vinho,
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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoBloco(_blocos[i]),
    );
  }

  Widget _cartaoBloco(DisponibilidadeModel b) {
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
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

  Widget _listaCardsBloqueios() {
    return ListView.separated(
      itemCount: _bloqueios.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _cartaoBloqueio(_bloqueios[i]),
    );
  }

  Widget _cartaoBloqueio(BloqueioModel b) {
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.dataTexto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: PainelCores.vinho,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${b.horaInicioTexto} às ${b.horaFimTexto}'),
                  const SizedBox(height: 4),
                  Text(
                    b.motivo ?? 'Bloqueio administrativo',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
              tooltip: 'Desbloquear horário',
              onPressed: () => _excluirBloqueio(b),
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
  static const _motivosRapidos = [
    'Almoço',
    'Folga',
    'Compromisso',
    'Indisponibilidade / Pausa',
  ];

  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();
  final _inicioController = TextEditingController();
  final _fimController = TextEditingController();
  final _motivoController =
      TextEditingController(text: 'Indisponibilidade / Pausa');

  late DateTime _data;
  TimeOfDay _inicio = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _fim = const TimeOfDay(hour: 15, minute: 0);
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _data = DateTime(agora.year, agora.month, agora.day);
    _dataController.text = _formatarDataCampo(_data);
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

  bool get _intervaloValido => _minutos(_fim) > _minutos(_inicio);

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: hoje.add(const Duration(days: 365)),
      builder: _temaSeletor,
    );
    if (escolhida != null) {
      setState(() {
        _data = escolhida;
        _dataController.text = _formatarDataCampo(_data);
      });
    }
  }

  Future<void> _escolherHorario({required bool inicio}) async {
    final atual = inicio ? _inicio : _fim;
    final escolhido = await showTimePicker(
      context: context,
      initialTime: atual,
      builder: (ctx, child) => _temaSeletor(
        ctx,
        MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (escolhido == null) return;
    setState(() {
      _erro = null;
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
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_intervaloValido) {
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

  Widget _campoData() {
    return _rotulado(
      'Data',
      TextFormField(
        controller: _dataController,
        readOnly: true,
        enabled: !_salvando,
        onTap: _escolherData,
        style: const TextStyle(fontSize: 14, color: _corTexto),
        decoration: _decoracaoForm(icone: Icons.calendar_today_outlined),
      ),
    );
  }

  Widget _campoHora(String rotulo, TextEditingController c, bool inicio) {
    return _rotulado(
      rotulo,
      TextFormField(
        controller: c,
        readOnly: true,
        enabled: !_salvando,
        onTap: () => _escolherHorario(inicio: inicio),
        style: const TextStyle(fontSize: 14, color: _corTexto),
        decoration: _decoracaoForm(icone: Icons.access_time),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telaEstreita = MediaQuery.of(context).size.width < 400;
    final motivoAtual = _motivoController.text.trim();

    return _DialogoPadrao(
      cabecalho: _CabecalhoDialogo(
        icone: Icons.block,
        corIcone: _corErro,
        corFundoIcone: _corErroFundo,
        titulo: 'Bloquear horário',
        subtitulo: 'Clientes não poderão agendar nesse intervalo.',
        onFechar: _salvando ? null : () => Navigator.pop(context, false),
      ),
      corpo: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campoData(),
            const SizedBox(height: 16),
            if (telaEstreita) ...[
              _campoHora('Início', _inicioController, true),
              const SizedBox(height: 16),
              _campoHora('Fim', _fimController, false),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _campoHora('Início', _inicioController, true)),
                  const SizedBox(width: 12),
                  Expanded(child: _campoHora('Fim', _fimController, false)),
                ],
              ),
            if (_intervaloValido)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Row(
                  children: [
                    const Icon(Icons.timelapse, size: 14, color: _corSuave),
                    const SizedBox(width: 6),
                    Text(
                      'Duração: ${_duracaoTexto(_minutos(_fim) - _minutos(_inicio))}',
                      style: const TextStyle(fontSize: 12, color: _corSuave),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _rotulado(
              'Motivo / Observação',
              TextFormField(
                controller: _motivoController,
                enabled: !_salvando,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14, color: _corTexto),
                decoration: _decoracaoForm(
                  dica: 'Ex.: Consulta médica',
                  icone: Icons.edit_note_rounded,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _motivosRapidos)
                  _chipOpcao(
                    rotulo: m,
                    selecionado: motivoAtual == m,
                    onTap: _salvando
                        ? null
                        : () => setState(() => _motivoController.text = m),
                  ),
              ],
            ),
            if (_erro != null) _BannerErro(_erro!),
          ],
        ),
      ),
      rodape: _RodapeDialogo(
        salvando: _salvando,
        rotuloSalvar: 'Confirmar bloqueio',
        onSalvar: _salvar,
        onCancelar: () => Navigator.pop(context, false),
      ),
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
  static const _atalhos = [
    _Atalho('Manhã', Icons.wb_sunny_outlined, TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 12, minute: 0)),
    _Atalho('Tarde', Icons.wb_twilight, TimeOfDay(hour: 13, minute: 0),
        TimeOfDay(hour: 18, minute: 0)),
    _Atalho('Dia todo', Icons.schedule, TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 18, minute: 0)),
  ];

  final _formKey = GlobalKey<FormState>();
  late int _dia;
  late TimeOfDay _inicio;
  late TimeOfDay _fim;
  bool _ativo = true;
  bool _salvando = false;
  String? _erro;

  final _inicioController = TextEditingController();
  final _fimController = TextEditingController();

  bool get _editando => widget.bloco != null;

  bool get _intervaloValido => _minutos(_fim) > _minutos(_inicio);

  @override
  void initState() {
    super.initState();
    final b = widget.bloco;
    if (b != null) {
      _dia = b.diaSemana;
      _inicio = _lerHora(b.horaInicio);
      _fim = _lerHora(b.horaFim);
      _ativo = b.ativo;
    } else {
      _dia = 0;
      _inicio = const TimeOfDay(hour: 8, minute: 0);
      _fim = const TimeOfDay(hour: 18, minute: 0);
    }
    _inicioController.text = _formatarHora(_inicio);
    _fimController.text = _formatarHora(_fim);
  }

  @override
  void dispose() {
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  void _aplicar(TimeOfDay inicio, TimeOfDay fim) {
    setState(() {
      _inicio = inicio;
      _fim = fim;
      _inicioController.text = _formatarHora(inicio);
      _fimController.text = _formatarHora(fim);
      _erro = null;
    });
    _formKey.currentState?.validate();
  }

  Future<void> _escolherHorario({required bool inicio}) async {
    final escolhido = await showTimePicker(
      context: context,
      initialTime: inicio ? _inicio : _fim,
      builder: (ctx, child) => _temaSeletor(
        ctx,
        MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (escolhido == null) return;
    if (inicio) {
      _aplicar(escolhido, _fim);
    } else {
      _aplicar(_inicio, escolhido);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final corpo = <String, dynamic>{
      'dia_semana': _dia,
      'hora_inicio': '${_formatarHora(_inicio)}:00',
      'hora_fim': '${_formatarHora(_fim)}:00',
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

  Widget _campoHora(String rotulo, TextEditingController c, bool inicio) {
    return _rotulado(
      rotulo,
      TextFormField(
        controller: c,
        readOnly: true,
        enabled: !_salvando,
        onTap: () => _escolherHorario(inicio: inicio),
        style: const TextStyle(fontSize: 14, color: _corTexto),
        decoration: _decoracaoForm(icone: Icons.access_time),
        validator: (valor) {
          if ((valor ?? '').isEmpty) {
            return inicio
                ? 'Informe o horário de início'
                : 'Informe o horário de fim';
          }
          if (!inicio && !_intervaloValido) {
            return 'O fim deve ser depois do início';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telaEstreita = MediaQuery.of(context).size.width < 400;

    return _DialogoPadrao(
      cabecalho: _CabecalhoDialogo(
        icone: _editando ? Icons.edit_calendar_outlined : Icons.event_available,
        titulo: _editando ? 'Editar horário' : 'Novo horário',
        subtitulo: _editando
            ? 'Atualize o bloco de atendimento semanal.'
            : 'Defina um bloco de atendimento semanal.',
        onFechar: _salvando ? null : () => Navigator.pop(context, false),
      ),
      corpo: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rotulado(
              'Dia da semana',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 7; i++)
                    _chipOpcao(
                      rotulo: _diasCurtos[i],
                      selecionado: _dia == i,
                      onTap: _salvando ? null : () => setState(() => _dia = i),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                _nomesDias[_dia],
                style: const TextStyle(fontSize: 12, color: _corSuave),
              ),
            ),
            const SizedBox(height: 16),
            _rotulado(
              'Atalhos',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _atalhos)
                    _chipOpcao(
                      rotulo: a.rotulo,
                      icone: a.icone,
                      selecionado: _inicio == a.inicio && _fim == a.fim,
                      onTap: _salvando ? null : () => _aplicar(a.inicio, a.fim),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (telaEstreita) ...[
              _campoHora('Início', _inicioController, true),
              const SizedBox(height: 16),
              _campoHora('Fim', _fimController, false),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _campoHora('Início', _inicioController, true)),
                  const SizedBox(width: 12),
                  Expanded(child: _campoHora('Fim', _fimController, false)),
                ],
              ),
            if (_intervaloValido)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Row(
                  children: [
                    const Icon(Icons.timelapse, size: 14, color: _corSuave),
                    const SizedBox(width: 6),
                    Text(
                      'Duração: ${_duracaoTexto(_minutos(_fim) - _minutos(_inicio))}',
                      style: const TextStyle(fontSize: 12, color: _corSuave),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _BlocoSwitch(
              titulo: 'Horário ativo',
              subtitulo: 'Disponível para as clientes agendarem.',
              valor: _ativo,
              onChanged: _salvando ? null : (v) => setState(() => _ativo = v),
            ),
            if (_erro != null) _BannerErro(_erro!),
          ],
        ),
      ),
      rodape: _RodapeDialogo(
        salvando: _salvando,
        rotuloSalvar: _editando ? 'Salvar alterações' : 'Criar horário',
        onSalvar: _salvar,
        onCancelar: () => Navigator.pop(context, false),
      ),
    );
  }
}

class _Atalho {
  final String rotulo;
  final IconData icone;
  final TimeOfDay inicio;
  final TimeOfDay fim;

  const _Atalho(this.rotulo, this.icone, this.inicio, this.fim);
}