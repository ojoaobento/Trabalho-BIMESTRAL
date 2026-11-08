import 'package:flutter/material.dart';

import 'package:main/screens/admin_dashboard.dart';
import 'package:main/services/api_client.dart';

class Adminlogin extends StatefulWidget {
  const Adminlogin({super.key});

  @override
  State<Adminlogin> createState() => _AdminloginState();
}

class _AdminloginState extends State<Adminlogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _ocultarSenha = true;

  static const Color vinho = Color(0xFF8E2348);
  static const Color vinhoEscuro = Color(0xFF5E1230);
  static const Color rosaClaro = Color(0xFFFFEEF3);
  static const Color bordaRosa = Color(0xFFF1DDE5);
  static const Color fundo = Color(0xFFFFF8FA);
  static const Color texto = Color(0xFF4A1026);
  static const Color suave = Color(0xFF976D7B);

  /// A partir dessa largura, mostra o painel da marca ao lado do formulário.
  static const double _larguraDesktop = 900;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (_isLoading) return;
    if (_emailController.text.trim().isEmpty ||
        _senhaController.text.isEmpty) {
      _mostrarMensagem('Preencha todos os campos');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await ApiClient.instancia.login(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    final larga = MediaQuery.of(context).size.width > 480;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: vinho,
          width: larga ? 420 : null,
          margin: larga ? null : const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(mensagem)),
            ],
          ),
        ),
      );
  }

  // ---------- visual ----------

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
    Widget? sufixo,
  }) {
    OutlineInputBorder borda(Color cor, {double largura = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: suave),
      floatingLabelStyle: const TextStyle(color: vinho),
      prefixIcon: Icon(icone, color: vinho, size: 20),
      suffixIcon: sufixo,
      filled: true,
      fillColor: rosaClaro,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: borda(bordaRosa),
      enabledBorder: borda(bordaRosa),
      focusedBorder: borda(vinho, largura: 1.6),
    );
  }

  Widget _logo(double tamanho, {bool claro = false}) {
    final escala = tamanho / 110;
    final cor = claro ? Colors.white : vinho;

    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: claro ? Colors.white.withOpacity(.12) : rosaClaro,
        shape: BoxShape.circle,
        border: Border.all(color: cor, width: 2),
        boxShadow: [
          BoxShadow(
            color: (claro ? Colors.black : vinho).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa_outlined, size: 42 * escala, color: cor),
          SizedBox(height: 4 * escala),
          Text(
            'CLEUSA',
            style: TextStyle(
              fontSize: 16 * escala,
              fontWeight: FontWeight.bold,
              letterSpacing: 2 * escala,
              color: cor,
            ),
          ),
          Text(
            'STUDIO',
            style: TextStyle(
              fontSize: 8 * escala,
              letterSpacing: 3 * escala,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  /// Painel lateral (só em telas largas): fundo vinho com a marca.
  Widget _painelMarca() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [vinho, vinhoEscuro],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _circulo(260, .07),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _circulo(340, .06),
          ),
          Positioned(
            bottom: 120,
            left: 40,
            child: _circulo(90, .08),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logo(130, claro: true),
                    const SizedBox(height: 32),
                    const Text(
                      'Studio Cleusa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ESTÉTICA & BELEZA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(.75),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Gerencie agendamentos, serviços e usuários em um só lugar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.white.withOpacity(.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circulo(double tamanho, double opacidade) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacidade),
      ),
    );
  }

  /// Cartão com o formulário. [mostrarLogo] é true quando não há painel
  /// lateral (celular e telas médias).
  Widget _cartaoFormulario({
    required bool mostrarLogo,
    required bool compacto,
  }) {
    final espaco = compacto ? 16.0 : 20.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compacto ? 20 : 28,
        compacto ? 24 : 32,
        compacto ? 20 : 28,
        compacto ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bordaRosa),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mostrarLogo) ...[
              Center(child: _logo(compacto ? 84 : 104)),
              SizedBox(height: compacto ? 18 : 24),
            ],
            const Text(
              'Bem-vinda de volta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: texto,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entre para acessar o painel do studio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: suave),
            ),
            SizedBox(height: espaco + 8),
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              style: const TextStyle(color: texto),
              decoration: _decoracaoCampo(
                label: 'E-mail',
                icone: Icons.email_outlined,
              ),
            ),
            SizedBox(height: espaco - 4),
            TextField(
              controller: _senhaController,
              enabled: !_isLoading,
              obscureText: _ocultarSenha,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _fazerLogin(),
              style: const TextStyle(color: texto),
              decoration: _decoracaoCampo(
                label: 'Senha',
                icone: Icons.lock_outline,
                sufixo: IconButton(
                  tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _ocultarSenha
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: suave,
                  ),
                  onPressed: () =>
                      setState(() => _ocultarSenha = !_ocultarSenha),
                ),
              ),
            ),
            SizedBox(height: espaco + 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _fazerLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: vinho,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: vinho.withOpacity(.55),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: espaco),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 13, color: suave),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Acesso restrito à equipe do studio',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: suave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Área do formulário: rola quando falta espaço e centraliza quando sobra.
  Widget _areaFormulario({required bool mostrarLogo}) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto =
              constraints.maxHeight < 620 || constraints.maxWidth < 360;
          final margem = constraints.maxWidth < 420 ? 16.0 : 24.0;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(margem),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - margem * 2,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _cartaoFormulario(
                    mostrarLogo: mostrarLogo,
                    compacto: compacto,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cursor e seleção de texto na cor do painel (sem o roxo padrão).
    final tema = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: vinho,
            surfaceTint: Colors.transparent,
          ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: vinho,
        selectionColor: vinho.withOpacity(.2),
        selectionHandleColor: vinho,
      ),
    );

    return Theme(
      data: tema,
      child: Scaffold(
        backgroundColor: fundo,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final largo = constraints.maxWidth >= _larguraDesktop;

            if (!largo) {
              return _areaFormulario(mostrarLogo: true);
            }

            return Row(
              children: [
                Expanded(flex: 5, child: _painelMarca()),
                Expanded(
                  flex: 4,
                  child: _areaFormulario(mostrarLogo: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}