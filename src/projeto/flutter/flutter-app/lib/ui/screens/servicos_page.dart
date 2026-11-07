import 'package:flutter/material.dart';
import 'package:main/data/agendamento_repository.dart';
import 'package:main/data/api_service.dart';
import 'package:main/data/sessao_cliente.dart';
import 'package:main/models/servico.dart';
import 'package:main/models/categoria.dart';
import 'package:main/ui/screens/identificacao_page.dart';
import 'package:main/ui/screens/revisao_page.dart';

class ServicosPage extends StatefulWidget {
  const ServicosPage({
    super.key,
    required this.data,
    required this.horario,
    required this.minutosLivres,
  });

  final DateTime data;
  final String horario;
  final int minutosLivres;

  @override
  State<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends State<ServicosPage> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corBorda = Color(0xFFF1DDE5);

  final _repositorio = AgendamentoRepository();

  List<Servico> _servicos = const [];
  List<Categoria> _categorias = const [];

  int? _categoriaFiltro;
  Servico? _servicoSelecionado;

  bool _carregando = true;
  bool _abrindo = false;
  String? _erro;

  String _formatarPreco(num valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarDuracao(int minutos) {
    final horas = minutos ~/ 60;
    final resto = minutos % 60;

    if (horas == 0) return '$resto min';
    if (resto == 0) return '${horas}h';

    return '${horas}h${resto.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await Future.wait<Object>([
        _repositorio.servicosAtivos(),
        _repositorio.categorias(),
      ]);

      if (!mounted) return;

      setState(() {
        _servicos = resultado[0] as List<Servico>;
        _categorias = resultado[1] as List<Categoria>;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    }
  }

  bool _cabe(Servico servico) {
    return servico.duracaoMinutos <= widget.minutosLivres;
  }

  /// Logada (sessão com nome guardada no aparelho): vai direto para a
  /// revisão (etapa 4). Senão, segue para "Seus dados" (etapa 3).
Future<void> _continuar(Servico servico) async {
  if (_abrindo) return;

  setState(() => _abrindo = true);

  SessaoCliente? sessao;

  try {
    sessao = await SessaoCliente.carregar();
  } catch (e) {
    debugPrint('Erro ao ler sessão: $e');
  }

  if (!mounted) return;

  setState(() => _abrindo = false);

  final nome = (sessao?.nome ?? '').trim();

  final Widget destino;

  if (sessao != null && nome.isNotEmpty) {
    destino = RevisaoPage(
      data: widget.data,
      horario: widget.horario,
      servico: servico,
      nome: nome,
      whatsApp: sessao.telefone,
      email: sessao.email,
      aceitaLembretes: true,
      consentimento: true,
    );
  } else {
    destino = IdentificacaoPage(
      data: widget.data,
      horario: widget.horario,
      servico: servico,
    );
  }

  Navigator.push(
    context,
    _InstantPageRoute(builder: (_) => destino),
  );
}

  @override
  Widget build(BuildContext context) {
    final servicosFiltrados = _categoriaFiltro == null
        ? _servicos
        : _servicos.where((s) => s.categoriaId == _categoriaFiltro).toList();

    return Scaffold(
      backgroundColor: _corFundo,
      body: SafeArea(
        child: Column(
          children: [
            _progresso(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
                children: [
                  _horarioEscolhido(),
                  const SizedBox(height: 16),
                  const Text(
                    'Serviços disponíveis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _corTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Sua janela livre neste horário é de ${_formatarDuracao(widget.minutosLivres)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _corPrincipal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._conteudo(servicosFiltrados),
                ],
              ),
            ),
            _rodape(),
          ],
        ),
      ),
    );
  }

  List<Widget> _conteudo(List<Servico> servicosFiltrados) {
    if (_carregando) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: _corPrincipal),
          ),
        ),
      ];
    }

    if (_erro != null) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _corBorda),
          ),
          child: Column(
            children: [
              Text(_erro!, textAlign: TextAlign.center),
              TextButton(
                onPressed: _carregar,
                style: TextButton.styleFrom(
                  foregroundColor: _corPrincipal,
                ),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ];
    }

    if (_servicos.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('Nenhum serviço disponível no momento.'),
          ),
        ),
      ];
    }

    return [
      _filtros(),
      const SizedBox(height: 14),
      ...servicosFiltrados.map(_cardServico),
    ];
  }

  Widget _progresso() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1. Horário', style: TextStyle(fontSize: 10, color: _corPrincipal)),
              Text(
                '2. Serviço',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _corPrincipal,
                ),
              ),
              Text('3. Seus dados', style: TextStyle(fontSize: 10, color: Colors.black45)),
              Text('4. Confirmar', style: TextStyle(fontSize: 10, color: Colors.black45)),
              Text('5. Status', style: TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Expanded(child: Divider(color: _corPrincipal, thickness: 3)),
              Expanded(child: Container(height: 3, color: _corPrincipal)),
              const Expanded(child: Divider(color: _corBorda, thickness: 3)),
              const Expanded(child: Divider(color: _corBorda, thickness: 3)),
              const Expanded(child: Divider(color: _corBorda, thickness: 3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _horarioEscolhido() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _corBorda),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left),
            color: _corTexto,
          ),
          const Icon(Icons.schedule_outlined, size: 18, color: _corPrincipal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horário escolhido:',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
                Text(
                  _dataCurta(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _corPrincipal,
              backgroundColor: const Color(0xFFFFEEF3),
            ),
            child: const Text(
              'Alterar',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    final categoriasComServico = _categorias
        .where((c) => _servicos.any((s) => s.categoriaId == c.id))
        .toList();

    Widget chip(String rotulo, int quantidade, int? id) {
      final selecionado = _categoriaFiltro == id;

      return ChoiceChip(
        label: Text(
          '$rotulo ($quantidade)',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        selected: selecionado,
        showCheckmark: false,
        selectedColor: _corPrincipal,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selecionado ? _corPrincipal : _corBorda,
        ),
        labelStyle: TextStyle(
          color: selecionado ? Colors.white : _corTexto,
        ),
        onSelected: (_) => setState(() => _categoriaFiltro = id),
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        chip('Todos', _servicos.length, null),
        ...categoriasComServico.map(
          (c) => chip(
            c.nome,
            _servicos.where((s) => s.categoriaId == c.id).length,
            c.id,
          ),
        ),
      ],
    );
  }

  Widget _cardServico(Servico servico) {
    final selecionado = _servicoSelecionado == servico;
    final cabe = _cabe(servico);

    return Opacity(
      opacity: cabe ? 1 : .5,
      child: InkWell(
        onTap: cabe
            ? () => setState(() => _servicoSelecionado = servico)
            : null,
        borderRadius: BorderRadius.circular(13),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selecionado ? _corPrincipal : _corBorda,
              width: selecionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servico.nome,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _corTexto,
                      ),
                    ),
                    if ((servico.descricao ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        servico.descricao ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.15,
                          color: Color(0xFF9A6C7C),
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: _corPrincipal,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${servico.duracaoMinutos} min',
                          style: const TextStyle(
                            fontSize: 10,
                            color: _corTexto,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 9),
                          child: Text(
                            '•',
                            style: TextStyle(color: _corPrincipal),
                          ),
                        ),
                        Text(
                          cabe ? 'Cabe no horário' : 'Não cabe neste horário',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cabe
                                ? const Color(0xFF16836D)
                                : const Color(0xFFB3261E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatarPreco(servico.preco),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _corTexto,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    selecionado
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selecionado ? _corPrincipal : _corBorda,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rodape() {
    final servico = _servicoSelecionado;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico == null
                      ? 'Nenhum serviço selecionado'
                      : '1 serviço selecionado',
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
                Text(
                  'Total: ${_formatarPreco(servico?.preco ?? 0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: (servico == null || _abrindo)
                ? null
                : () => _continuar(servico),
            style: FilledButton.styleFrom(
              backgroundColor: _corPrincipal,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
            ),
            label: const Text('Continuar'),
            icon: const Icon(Icons.arrow_forward, size: 16),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }

  String _dataCurta() {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    const meses = [
      'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.',
      'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.',
    ];

    return '${dias[widget.data.weekday - 1]} ${widget.data.day} de ${meses[widget.data.month - 1]} às ${widget.horario}';
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