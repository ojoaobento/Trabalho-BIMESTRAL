import 'package:flutter/material.dart';
import 'package:main/models/servico.dart';
import 'package:main/data/agendamento_repository.dart';
import 'package:main/data/api_service.dart';
import 'package:main/models/rascunho_cliente.dart';
import 'package:main/data/sessao_cliente.dart';
import 'package:main/ui/screens/status_page.dart';

class RevisaoPage extends StatefulWidget {
  const RevisaoPage({
    super.key,
    required this.data,
    required this.horario,
    required this.servico,
    required this.nome,
    required this.whatsApp,
    required this.email,
    required this.aceitaLembretes,
    required this.consentimento,
  });

  final DateTime data;
  final String horario;
  final Servico servico;
  final String nome;
  final String whatsApp;
  final String email;
  final bool aceitaLembretes;
  final bool consentimento;

  @override
  State<RevisaoPage> createState() => _RevisaoPageState();
}

class _RevisaoPageState extends State<RevisaoPage> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corBorda = Color(0xFFF1DDE5);

  final _repositorio = AgendamentoRepository();

  bool _enviando = false;

  String _formatarPreco(num valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Primeira vez: o servidor devolve um token e a cliente já fica "logada"
  Future<void> _guardarSessao(String? token) async {
    if (token == null || token.isEmpty) return;

    try {
      final existente = await SessaoCliente.carregar();

      // Não sobrescreve a sessão de outra cliente já logada neste aparelho.
      if (existente != null) return;

      await SessaoCliente(
        token: token,
        email: widget.email.trim(),
        telefone: widget.whatsApp.replaceAll(RegExp(r'\D'), ''),
        nome: widget.nome.trim(),
      ).salvar();
    } catch (e) {
      debugPrint('Erro ao guardar sessão: $e');
    }
  }

  Future<void> _confirmar() async {
    if (_enviando) return;

    setState(() {
      _enviando = true;
    });

    try {
      final criado = await _repositorio.criar(
        servicoId: widget.servico.id,
        data: widget.data,
        hora: widget.horario,
        nome: widget.nome,
        whatsApp: widget.whatsApp,
        email: widget.email,
        aceitaLembretes: widget.aceitaLembretes,
        consentimento: widget.consentimento,
      );

      await _guardarSessao(criado.tokenAcesso);

      // Agendamento criado: o rascunho dos dados não é mais necessário.
      RascunhoCliente.limpar();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SolicitacaoConfirmadaPage(
            agendamento: criado,
            whatsApp: widget.whatsApp,
            email: widget.email,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      debugPrint('Erro ao confirmar agendamento: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar o agendamento. Tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      body: SafeArea(
        child: Column(
          children: [
            _progresso(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(11, 16, 11, 18),
                children: [
                  _titulo(),
                  const SizedBox(height: 14),
                  _aviso(),
                  const SizedBox(height: 12),
                  _servico(),
                  const SizedBox(height: 9),
                  _dadosData(),
                  const SizedBox(height: 9),
                  _local(),
                  const SizedBox(height: 9),
                  _cliente(),
                ],
              ),
            ),
            _rodape(),
          ],
        ),
      ),
    );
  }

  Widget _progresso() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1. Horário', style: TextStyle(fontSize: 10, color: _corPrincipal)),
              Text('2. Serviço', style: TextStyle(fontSize: 10, color: _corPrincipal)),
              Text('3. Seus dados', style: TextStyle(fontSize: 10, color: _corPrincipal)),
              Text(
                '4. Confirmar',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _corPrincipal,
                ),
              ),
              Text('5. Status', style: TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Expanded(child: Divider(color: _corPrincipal, thickness: 3)),
              Expanded(child: Container(height: 3, color: _corPrincipal)),
              Expanded(child: Container(height: 3, color: _corPrincipal)),
              Expanded(child: Container(height: 3, color: _corPrincipal)),
              const Expanded(child: Divider(color: _corBorda, thickness: 3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _titulo() {
    return Row(
      children: [
        IconButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: _corBorda),
          ),
          icon: const Icon(Icons.chevron_left, size: 18),
          color: _corTexto,
        ),
        const SizedBox(width: 8),
        const Text(
          'REVISÃO FINAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _corPrincipal,
          ),
        ),
      ],
    );
  }

  Widget _aviso() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: _corPrincipal,
            child: Icon(Icons.info_outline, size: 13, color: Colors.white),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confira os dados antes de confirmar',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corPrincipal,
                  ),
                ),
                Text(
                  'O studio aprova a solicitação e avisa você por e-mail.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF9A6C7C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _servico() {
    final descricao = widget.servico.descricao ?? '';

    return _cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SERVIÇO ESCOLHIDO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _corPrincipal,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _enviando
                    ? null
                    : () => Navigator.of(context).popUntil(
                          ModalRoute.withName('servicos'),
                        ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: _corPrincipal,
                ),
                child: const Text(
                  'Editar',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            widget.servico.nome,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _corTexto,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            descricao.isEmpty
                ? 'Serviço selecionado para o seu horário.'
                : descricao,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF976D7B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dadosData() {
    return Row(
      children: [
        Expanded(
          child: _cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATA E HORÁRIO',
                  style: TextStyle(fontSize: 8, color: Color(0xFF9A6C7C)),
                ),
                const SizedBox(height: 4),
                Text(
                  _dataFormatada(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Término previsto: ${_fimPrevisto()}',
                  style: const TextStyle(fontSize: 8, color: Color(0xFF976D7B)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DURAÇÃO & VALOR',
                  style: TextStyle(fontSize: 8, color: Color(0xFF9A6C7C)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.servico.duracaoMinutos} min · ${_formatarPreco(widget.servico.preco)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pagamento no local',
                  style: TextStyle(fontSize: 8, color: Color(0xFF976D7B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _local() {
    return _cartao(
      child: const Row(
        children: [
          Icon(Icons.location_on_outlined, color: _corPrincipal, size: 17),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Studio Cleusa',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _corTexto,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Av. Brasil, 1420 – Sala 4 · Maringá, PR',
                style: TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cliente() {
    return _cartao(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agendado para:',
                  style: TextStyle(fontSize: 9, color: Color(0xFF9A6C7C)),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.nome,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatarTelefone(widget.whatsApp),
                  style: const TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _enviando ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: _corPrincipal,
            ),
            child: const Text(
              'Editar',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartao({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _corBorda),
      ),
      child: child,
    );
  }

  Widget _rodape() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _confirmar,
              style: FilledButton.styleFrom(
                backgroundColor: _corPrincipal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 16),
              label: Text(
                _enviando ? 'Confirmando...' : 'Confirmar agendamento',
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sem pagamento antecipado. Você paga diretamente no studio.',
            style: TextStyle(fontSize: 8, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  String _dataFormatada() {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const meses = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];

    return '${dias[widget.data.weekday - 1]} ${widget.data.day} de ${meses[widget.data.month - 1]} · ${widget.horario}';
  }

  String _fimPrevisto() {
    final partes = widget.horario.split(':');

    final inicioEmMinutos =
        int.parse(partes[0]) * 60 + int.parse(partes[1]);

    final fimEmMinutos =
        inicioEmMinutos + widget.servico.duracaoMinutos;

    final horas = (fimEmMinutos ~/ 60) % 24;
    final minutos = fimEmMinutos % 60;

    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }

  String _formatarTelefone(String telefone) {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');

    if (digitos.length != 11) return telefone;

    return '(${digitos.substring(0, 2)}) '
        '${digitos.substring(2, 7)}-'
        '${digitos.substring(7)}';
  }
}