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

  static const Color vinho = Color(0xFF8E2348);
  static const Color rosaClaro = Color(0xFFFFEEF3);
  static const Color bordaRosa = Color(0xFFF1DDE5);

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
      _mostrarMensagem('Preencha todos os campos', vinho);
      return;
    }

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
      _mostrarMensagem(e.mensagem, vinho); 
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Erro inesperado. Tente novamente.', vinho);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarMensagem(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: vinho),
      floatingLabelStyle: const TextStyle(color: vinho),
      prefixIcon: Icon(icone, color: vinho),
      filled: true,
      fillColor: rosaClaro,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: bordaRosa),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: bordaRosa),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: vinho, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FA),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: rosaClaro,
                    shape: BoxShape.circle,
                    border: Border.all(color: vinho, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: vinho.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.spa_outlined, size: 42, color: vinho),
                      SizedBox(height: 4),
                      Text(
                        'CLEUSA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: vinho,
                        ),
                      ),
                      Text(
                        'STUDIO',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 3,
                          color: vinho,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracaoCampo(
                    label: 'E-mail',
                    icone: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _fazerLogin(), 
                  decoration: _decoracaoCampo(
                    label: 'Senha',
                    icone: Icons.lock_outline,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: vinho),
                        )
                      : ElevatedButton(
                          onPressed: _fazerLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vinho,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}