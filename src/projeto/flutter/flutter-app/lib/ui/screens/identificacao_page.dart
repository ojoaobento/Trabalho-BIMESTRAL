import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:main/data/sessao_cliente.dart';
import 'package:main/models/servico.dart';
import 'package:main/ui/screens/revisao_page.dart';

class IdentificacaoPage extends StatefulWidget {
  const IdentificacaoPage({
    super.key,
    required this.data,
    required this.horario,
    required this.servico,
  });

  final DateTime data;
  final String horario;
  final Servico servico;

  @override
  State<IdentificacaoPage> createState() => _IdentificacaoPageState();
}

class _IdentificacaoPageState extends State<IdentificacaoPage> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corBorda = Color(0xFFF1DDE5);

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _autorizouDados = false;
  bool _autorizouEmail = false;
  bool _dadosDaConta = false;

  @override
  void initState() {
    super.initState();
    _preencherComSessao();
  }

  /// Se a cliente já entrou em "Meus agendamentos" neste aparelho, usa os
  /// dados guardados para preencher o formulário.
  Future<void> _preencherComSessao() async {
    final sessao = await SessaoCliente.carregar();

    if (!mounted || sessao == null) return;

    // Não sobrescreve o que ela já tenha começado a digitar.
    if (_nomeController.text.isNotEmpty ||
        _telefoneController.text.isNotEmpty ||
        _emailController.text.isNotEmpty) {
      return;
    }

    setState(() {
      _nomeController.text = sessao.nome ?? '';
      _telefoneController.text = _formatarTelefone(sessao.telefone);
      _emailController.text = sessao.email;
      _dadosDaConta = true;
    });
  }

  void _usarOutrosDados() {
    setState(() {
      _nomeController.clear();
      _telefoneController.clear();
      _emailController.clear();
      _dadosDaConta = false;
    });

    _formKey.currentState?.reset();
  }

  String _formatarTelefone(String valor) {
    var digitos = valor.replaceAll(RegExp(r'\D'), '');

    if (digitos.length > 11) digitos = digitos.substring(0, 11);

    final buffer = StringBuffer();

    for (var i = 0; i < digitos.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');

      buffer.write(digitos[i]);
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_autorizouDados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autorize o uso dos dados para continuar.'),
        ),
      );
      return;
    }

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();

    final telefone = _telefoneController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    Navigator.push(
      context,
      _InstantPageRoute(
        builder: (_) => RevisaoPage(
          data: widget.data,
          horario: widget.horario,
          servico: widget.servico,
          nome: nome,
          whatsApp: telefone,
          email: email,
          aceitaLembretes: _autorizouEmail,
          consentimento: _autorizouDados,
        ),
      ),
    );
  }

  void _continuarComGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'O login com Google ainda não está disponível.',
        ),
      ),
    );
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
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(13, 16, 13, 22),
                  children: [
                    _titulo(),
                    const SizedBox(height: 15),
                    if (_dadosDaConta) ...[
                      _avisoDadosDaConta(),
                      const SizedBox(height: 12),
                    ],
                    _clienteAgendado(),
                    const SizedBox(height: 18),
                    const Text(
                      'Quase lá! Como podemos te\navisar?',
                      style: TextStyle(
                        fontSize: 21,
                        height: 1.12,
                        fontWeight: FontWeight.bold,
                        color: _corTexto,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sem senha e sem cadastro longo. Apenas o essencial para garantir seu horário.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF976D7B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _botaoGoogle(),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: _corBorda)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OU PREENCHA ABAIXO',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF976D7B),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: _corBorda)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _campo(
                      'Nome completo *',
                      _nomeController,
                      capitalizacao: TextCapitalization.words,
                      validador: (valor) {
                        final nome = (valor ?? '').trim();

                        if (nome.length < 2) {
                          return 'Informe seu nome completo';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 11),
                    _campo(
                      'Telefone com DDD *',
                      _telefoneController,
                      prefixo: 'BR',
                      teclado: TextInputType.phone,
                      formatadores: [_TelefoneFormatter()],
                      validador: (valor) {
                        final digitos = (valor ?? '').replaceAll(
                          RegExp(r'\D'),
                          '',
                        );

                        // DDD válido (sem zero) + celular começando com 9.
                        if (!RegExp(r'^[1-9]{2}9\d{8}$').hasMatch(digitos)) {
                          return 'Informe um telefone válido com DDD (ex.: 44 9XXXX-XXXX)';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 11),
                    _campo(
                      'E-mail para confirmação *',
                      _emailController,
                      teclado: TextInputType.emailAddress,
                      validador: (valor) {
                        final email = (valor ?? '').trim();

                        final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email);

                        return valido ? null : 'Informe um e-mail válido';
                      },
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: _corPrincipal,
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Enviaremos a confirmação e o lembrete 24h antes por e-mail, caso você autorize.',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF976D7B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    CheckboxListTile(
                      value: _autorizouDados,
                      onChanged: (valor) {
                        setState(() {
                          _autorizouDados = valor ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _corPrincipal,
                      title: const Text(
                        'Autorizo o uso dos meus dados para agendamento conforme a LGPD. *',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF6F5360),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: _autorizouEmail,
                      onChanged: (valor) {
                        setState(() {
                          _autorizouEmail = valor ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _corPrincipal,
                      title: const Text(
                        'Autorizo o envio de confirmações e lembretes por e-mail.',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF6F5360),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _rodape(),
          ],
        ),
      ),
    );
  }

  Widget _avisoDadosDaConta() {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 14, color: _corPrincipal),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Dados preenchidos da sua conta.',
            style: TextStyle(fontSize: 10, color: Color(0xFF976D7B)),
          ),
        ),
        TextButton(
          onPressed: _usarOutrosDados,
          style: TextButton.styleFrom(
            foregroundColor: _corPrincipal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 28),
          ),
          child: const Text(
            'Usar outros dados',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
              Text(
                '1. Horário',
                style: TextStyle(fontSize: 10, color: _corPrincipal),
              ),
              Text(
                '2. Serviço',
                style: TextStyle(fontSize: 10, color: _corPrincipal),
              ),
              Text(
                '3. Seus dados',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _corPrincipal,
                ),
              ),
              Text(
                '4. Confirmar',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
              Text(
                '5. Status',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Expanded(
                child: Divider(color: _corPrincipal, thickness: 3),
              ),
              Expanded(
                child: Container(height: 3, color: _corPrincipal),
              ),
              Expanded(
                child: Container(height: 3, color: _corPrincipal),
              ),
              const Expanded(
                child: Divider(color: _corBorda, thickness: 3),
              ),
              const Expanded(
                child: Divider(color: _corBorda, thickness: 3),
              ),
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
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: _corBorda),
          ),
          icon: const Icon(Icons.chevron_left, size: 18),
          color: _corTexto,
        ),
        const SizedBox(width: 8),
        const Text(
          'IDENTIFICAÇÃO DO CLIENTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _corPrincipal,
          ),
        ),
      ],
    );
  }

  Widget _clienteAgendado() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nomeController,
      builder: (context, nome, _) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _telefoneController,
          builder: (context, telefone, _) {
            return _clienteAgendadoConteudo();
          },
        );
      },
    );
  }

  String _iniciais() {
    final partes = _nomeController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.isEmpty) return '?';

    if (partes.length == 1) {
      return partes.first[0].toUpperCase();
    }

    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  Widget _clienteAgendadoConteudo() {
    if (_nomeController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _corPrincipal,
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _corPrincipal,
            child: Text(
              _iniciais(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agendando como ${_nomeController.text.trim()}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                if (_telefoneController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _telefoneController.text,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF976D7B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoGoogle() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _continuarComGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: _corTexto,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          side: const BorderSide(color: _corBorda),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: SvgPicture.asset(
          'assets/icons/google_g.svg',
          width: 18,
          height: 18,
        ),
        label: const Text(
          'Continuar com o Google',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _campo(
    String titulo,
    TextEditingController controller, {
    String? prefixo,
    TextInputType? teclado,
    TextCapitalization capitalizacao = TextCapitalization.none,
    List<TextInputFormatter>? formatadores,
    String? Function(String?)? validador,
  }) {
    OutlineInputBorder borda(Color cor) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: cor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _corTexto,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: teclado,
          textCapitalization: capitalizacao,
          inputFormatters: formatadores,
          validator: validador,
          style: const TextStyle(
            fontSize: 11,
            color: _corTexto,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            prefixText: prefixo == null ? null : '$prefixo   ',
            prefixStyle: const TextStyle(
              fontSize: 10,
              color: _corTexto,
            ),
            errorStyle: const TextStyle(fontSize: 9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: borda(_corBorda),
            enabledBorder: borda(_corBorda),
            focusedBorder: borda(_corPrincipal),
            errorBorder: borda(const Color(0xFFB3261E)),
            focusedErrorBorder: borda(const Color(0xFFB3261E)),
          ),
        ),
      ],
    );
  }

  Widget _rodape() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identificação rápida',
                  style: TextStyle(fontSize: 9, color: Colors.black45),
                ),
                Text(
                  'Seus dados ficam protegidos',
                  style: TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _continuar,
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
}

class _TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    var digitos = novo.text.replaceAll(RegExp(r'\D'), '');

    if (digitos.length > 11) {
      digitos = digitos.substring(0, 11);
    }

    const posicaoHifen = 7;
    final buffer = StringBuffer();

    for (var i = 0; i < digitos.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == posicaoHifen) buffer.write('-');

      buffer.write(digitos[i]);
    }

    final texto = buffer.toString();

    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class _InstantPageRoute<T> extends PageRouteBuilder<T> {
  _InstantPageRoute({
    required WidgetBuilder builder,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}