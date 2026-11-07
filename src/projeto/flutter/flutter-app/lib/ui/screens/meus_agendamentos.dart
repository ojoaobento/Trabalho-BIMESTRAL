import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:main/data/agendamento_repository.dart';
import 'package:main/data/api_service.dart';
import 'package:main/data/sessao_cliente.dart';
import 'package:main/models/agendamento_criado.dart';

enum _Etapa { iniciando, dados, codigo, lista }

/// Acesso da cliente:
/// - Primeira vez (ou sessão expirada): e-mail + telefone -> código -> lista.
/// - Depois: o token guardado no aparelho abre a lista direto.
///
/// [email] e [telefone] são opcionais e só pré-preenchem o formulário
/// (por exemplo, logo após concluir um agendamento).
class MeusAgendamentosPage extends StatefulWidget {
  const MeusAgendamentosPage({super.key, this.email, this.telefone});

  final String? email;
  final String? telefone;

  @override
  State<MeusAgendamentosPage> createState() => _MeusAgendamentosPageState();
}

class _MeusAgendamentosPageState extends State<MeusAgendamentosPage> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);

  final _repositorio = AgendamentoRepository();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _codigoController = TextEditingController();

  _Etapa _etapa = _Etapa.iniciando;
  List<AgendamentoCriado> _agendamentos = const [];
  String? _token;
  int? _cancelandoId;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _emailController.text = widget.email ?? '';
    _telefoneController.text =
        (widget.telefone ?? '').replaceAll(RegExp(r'\D'), '');

    _restaurarSessao();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _telefoneController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  String get _telefone =>
      _telefoneController.text.replaceAll(RegExp(r'\D'), '');

  bool get _emailValido =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email);

  /// DDD válido (2 dígitos, sem zero) + celular começando com 9 (11 dígitos).
  bool get _telefoneValido =>
      RegExp(r'^[1-9]{2}9\d{8}$').hasMatch(_telefone);

  // ---------- sessão ----------

  /// Tenta entrar direto com o token guardado no aparelho.
  Future<void> _restaurarSessao() async {
    final sessao = await SessaoCliente.carregar();

    if (!mounted) return;

    if (sessao == null) {
      setState(() => _etapa = _Etapa.dados);
      return;
    }

    // Veio de um agendamento feito com outro e-mail/telefone: não usa a
    // sessão guardada, para não mostrar a lista de outra pessoa.
    final pedidoEmail = (widget.email ?? '').trim().toLowerCase();
    final pedidoTelefone =
        (widget.telefone ?? '').replaceAll(RegExp(r'\D'), '');

    final outraPessoa =
        (pedidoEmail.isNotEmpty && pedidoEmail != sessao.email.toLowerCase()) ||
            (pedidoTelefone.isNotEmpty && pedidoTelefone != sessao.telefone);

    if (outraPessoa) {
      setState(() => _etapa = _Etapa.dados);
      return;
    }

    _emailController.text = sessao.email;
    _telefoneController.text = sessao.telefone;

    try {
      final acesso =
          await _repositorio.meusAgendamentosComToken(sessao.token);

      // Atualiza o nome guardado (sessões antigas ainda não tinham).
      await SessaoCliente(
        token: acesso.token,
        email: sessao.email,
        telefone: sessao.telefone,
        nome: acesso.nome ?? sessao.nome,
      ).salvar();

      if (!mounted) return;

      setState(() {
        _token = acesso.token;
        _agendamentos = acesso.agendamentos;
        _etapa = _Etapa.lista;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 403) {
        // Sessão vencida ou inválida: apaga e pede um novo código.
        await SessaoCliente.limpar();

        if (!mounted) return;

        setState(() => _etapa = _Etapa.dados);
      } else {
        // Sem conexão etc.: mantém a sessão guardada para a próxima vez.
        setState(() {
          _erro = e.mensagem;
          _etapa = _Etapa.dados;
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao restaurar sessão: $e');

      setState(() => _etapa = _Etapa.dados);
    }
  }

  // ---------- ações ----------

  Future<void> _solicitarCodigo() async {
    if (!_emailValido) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }

    if (!_telefoneValido) {
      setState(() => _erro =
          'Informe um telefone válido com DDD (ex.: 44 9XXXX-XXXX).');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await _repositorio.solicitarCodigo(email: _email, telefone: _telefone);

      if (!mounted) return;

      _codigoController.clear();

      setState(() {
        _etapa = _Etapa.codigo;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao solicitar código: $e');

      setState(() {
        _erro = 'Não foi possível enviar o código. Tente novamente.';
        _carregando = false;
      });
    }
  }

  /// Entra com o código recebido por e-mail e guarda a sessão no aparelho.
  Future<void> _entrar() async {
    final codigo = _codigoController.text.trim();

    if (codigo.length != 6) {
      setState(() => _erro = 'Informe o código de 6 dígitos.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final acesso = await _repositorio.meusAgendamentos(
        email: _email,
        telefone: _telefone,
        codigo: codigo,
      );

      await SessaoCliente(
        token: acesso.token,
        email: _email,
        telefone: _telefone,
        nome: acesso.nome,
      ).salvar();

      if (!mounted) return;

      setState(() {
        _token = acesso.token;
        _agendamentos = acesso.agendamentos;
        _etapa = _Etapa.lista;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao carregar agendamentos: $e');

      setState(() {
        _erro = 'Não foi possível carregar seus agendamentos.';
        _carregando = false;
      });
    }
  }

  /// "Puxar para atualizar": usa o token, sem precisar de código.
  Future<void> _atualizar() async {
    final token = _token;

    if (token == null) {
      await _sair();
      return;
    }

    try {
      final acesso = await _repositorio.meusAgendamentosComToken(token);

      if (!mounted) return;

      setState(() => _agendamentos = acesso.agendamentos);
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 403) {
        await _sair();

        if (!mounted) return;

        _avisar('Sua sessão expirou. Entre novamente.');
      } else {
        _avisar(e.mensagem);
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao atualizar agendamentos: $e');

      _avisar('Não foi possível atualizar agora.');
    }
  }

  /// Encerra a sessão neste aparelho e volta ao formulário.
  Future<void> _sair() async {
    await SessaoCliente.limpar();

    if (!mounted) return;

    setState(() {
      _etapa = _Etapa.dados;
      _token = null;
      _agendamentos = const [];
      _codigoController.clear();
      _erro = null;
      _carregando = false;
    });
  }

  void _voltarParaDados() {
    setState(() {
      _etapa = _Etapa.dados;
      _codigoController.clear();
      _erro = null;
    });
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  /// Pede confirmação e cancela o horário escolhido.
  Future<void> _cancelar(AgendamentoCriado a) async {
    final token = _token;

    if (token == null) {
      await _sair();
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar horário?'),
        content: Text(
          '${a.servicoNome}\n${_periodo(a)}\n\n'
          'O horário ficará livre para outras clientes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter horário'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            child: const Text('Cancelar horário'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    setState(() => _cancelandoId = a.id);

    try {
      final atualizado = await _repositorio.cancelarMeuAgendamento(
        token: token,
        agendamentoId: a.id,
      );

      if (!mounted) return;

      setState(() {
        _agendamentos = _agendamentos
            .map((x) => x.id == atualizado.id ? atualizado : x)
            .toList();
        _cancelandoId = null;
      });

      _avisar('Horário cancelado.');
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _cancelandoId = null);

      if (e.statusCode == 403) {
        await _sair();

        if (!mounted) return;

        _avisar('Sua sessão expirou. Entre novamente.');
      } else {
        _avisar(e.mensagem);
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao cancelar agendamento: $e');

      setState(() => _cancelandoId = null);

      _avisar('Não foi possível cancelar agora.');
    }
  }

  // ---------- estrutura ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      body: SafeArea(
        child: Column(
          children: [
            _cabecalho(),
            Expanded(
              child: switch (_etapa) {
                _Etapa.iniciando => const Center(
                    child: CircularProgressIndicator(color: _corPrincipal),
                  ),
                _Etapa.dados => _formularioDados(),
                _Etapa.codigo => _formularioCodigo(),
                _Etapa.lista => _lista(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left),
            color: _corTexto,
          ),
          const Text(
            'MEUS AGENDAMENTOS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _corPrincipal,
            ),
          ),
          const Spacer(),
          if (_etapa == _Etapa.lista)
            TextButton(
              onPressed: _sair,
              style: TextButton.styleFrom(foregroundColor: _corPrincipal),
              child: const Text('Sair'),
            ),
        ],
      ),
    );
  }

  // ---------- etapa 1: e-mail + telefone ----------

  Widget _formularioDados() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Acesse seus agendamentos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _corTexto,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Informe o e-mail e o telefone usados no agendamento. '
          'Enviaremos um código de acesso para o seu e-mail.',
          style: TextStyle(fontSize: 13, color: _corSuave),
        ),
        const SizedBox(height: 20),
        _campo(
          'E-mail',
          _emailController,
          teclado: TextInputType.emailAddress,
          dica: 'voce@email.com',
        ),
        const SizedBox(height: 14),
        _campo(
          'Telefone',
          _telefoneController,
          teclado: TextInputType.phone,
          formatadores: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          dica: 'DDD + número, só dígitos',
        ),
        _mensagemErro(),
        const SizedBox(height: 20),
        _botao('Enviar código', _solicitarCodigo),
      ],
    );
  }

  // ---------- etapa 2: código ----------

  Widget _formularioCodigo() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Digite o código',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _corTexto,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Se os dados estiverem corretos, enviamos um código de 6 dígitos '
          'para $_email. Ele vale por alguns minutos.',
          style: const TextStyle(fontSize: 13, color: _corSuave),
        ),
        const SizedBox(height: 20),
        _campo(
          'Código de acesso',
          _codigoController,
          teclado: TextInputType.number,
          formatadores: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          dica: '000000',
          centralizar: true,
        ),
        _mensagemErro(),
        const SizedBox(height: 20),
        _botao('Entrar', _entrar),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _carregando ? null : _solicitarCodigo,
            style: TextButton.styleFrom(foregroundColor: _corPrincipal),
            child: const Text('Reenviar código'),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: _carregando ? null : _voltarParaDados,
            style: TextButton.styleFrom(foregroundColor: _corSuave),
            child: const Text('Alterar e-mail ou telefone'),
          ),
        ),
      ],
    );
  }

  Widget _mensagemErro() {
    if (_erro == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _erro!,
        style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
      ),
    );
  }

  Widget _botao(String texto, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _carregando ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _corPrincipal,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: _carregando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(texto),
      ),
    );
  }

  Widget _campo(
    String titulo,
    TextEditingController controller, {
    TextInputType? teclado,
    List<TextInputFormatter>? formatadores,
    String? dica,
    bool centralizar = false,
  }) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cor),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _corTexto,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: teclado,
          inputFormatters: formatadores,
          textAlign: centralizar ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: centralizar ? 22 : 14,
            letterSpacing: centralizar ? 6 : 0,
            color: _corTexto,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: dica,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: borda(_corBorda),
            enabledBorder: borda(_corBorda),
            focusedBorder: borda(_corPrincipal),
          ),
        ),
      ],
    );
  }

  // ---------- etapa 3: lista ----------

  bool _ativo(AgendamentoCriado a, DateTime agora) {
    const encerrados = ['cancelado', 'concluido', 'faltou'];
    return a.fim.isAfter(agora) && !encerrados.contains(a.status.toLowerCase());
  }

  Widget _lista() {
    final agora = DateTime.now();

    final proximos = _agendamentos.where((a) => _ativo(a, agora)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

    final anteriores = _agendamentos.where((a) => !_ativo(a, agora)).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));

    return RefreshIndicator(
      color: _corPrincipal,
      onRefresh: _atualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Seus horários',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _corTexto,
            ),
          ),
          const SizedBox(height: 16),
          if (_agendamentos.isEmpty)
            _mensagem('Você ainda não tem agendamentos.'),
          if (proximos.isNotEmpty) ...[
            _titulo('Próximos'),
            ...proximos.map(_cartao),
          ],
          if (anteriores.isNotEmpty) ...[
            const SizedBox(height: 8),
            _titulo('Anteriores e cancelados'),
            ...anteriores.map(_cartao),
          ],
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: .8,
          color: _corPrincipal,
        ),
      ),
    );
  }

  Widget _mensagem(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _corBorda),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _corTexto),
      ),
    );
  }

  Widget _cartao(AgendamentoCriado a) {
    final visual = _statusVisual(a.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _corBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.servicoNome,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: visual.fundo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  visual.rotulo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: visual.texto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 15,
                color: _corPrincipal,
              ),
              const SizedBox(width: 6),
              Text(
                _periodo(a),
                style: const TextStyle(fontSize: 13, color: _corTexto),
              ),
            ],
          ),
          if (a.podeCancelar) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    _cancelandoId == null ? () => _cancelar(a) : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB3261E),
                  visualDensity: VisualDensity.compact,
                ),
                icon: _cancelandoId == a.id
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_busy_outlined, size: 16),
                label: Text(
                  _cancelandoId == a.id ? 'Cancelando...' : 'Cancelar horário',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({String rotulo, Color fundo, Color texto}) _statusVisual(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return (
          rotulo: 'Confirmado',
          fundo: const Color(0xFFE7F8F1),
          texto: const Color(0xFF16866C),
        );
      case 'cancelado':
        return (
          rotulo: 'Cancelado',
          fundo: const Color(0xFFFDE7E9),
          texto: const Color(0xFFB3261E),
        );
      case 'concluido':
        return (
          rotulo: 'Concluído',
          fundo: const Color(0xFFEFEFF4),
          texto: const Color(0xFF55556A),
        );
      case 'faltou':
        return (
          rotulo: 'Não compareceu',
          fundo: const Color(0xFFEFEFF4),
          texto: const Color(0xFF55556A),
        );
      default:
        return (
          rotulo: 'Aguardando aprovação',
          fundo: const Color(0xFFFFF1D9),
          texto: const Color(0xFF9B661E),
        );
    }
  }

  String _periodo(AgendamentoCriado a) {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const meses = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];

    String hm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';

    final d = a.inicio;
    return '${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]} · '
        '${hm(d)} às ${hm(a.fim)}';
  }
}