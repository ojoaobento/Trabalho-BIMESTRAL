import 'package:shared_preferences/shared_preferences.dart';

/// Sessão da cliente guardada no aparelho (token + dados usados no acesso).
///
/// Instale a dependência com:  flutter pub add shared_preferences
class SessaoCliente {
  const SessaoCliente({
    required this.token,
    required this.email,
    required this.telefone,
    this.nome,
  });

  final String token;
  final String email;
  final String telefone;

  /// Pode ser nulo em sessões salvas antes dessa versão; é preenchido na
  /// próxima vez que a cliente abrir "Meus agendamentos".
  final String? nome;

  static const _chaveToken = 'cliente_token';
  static const _chaveEmail = 'cliente_email';
  static const _chaveTelefone = 'cliente_telefone';
  static const _chaveNome = 'cliente_nome';

  static Future<SessaoCliente?> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_chaveToken);
      final email = prefs.getString(_chaveEmail);
      final telefone = prefs.getString(_chaveTelefone);

      if (token == null || email == null || telefone == null) return null;

      return SessaoCliente(
        token: token,
        email: email,
        telefone: telefone,
        nome: prefs.getString(_chaveNome),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> salvar() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_chaveToken, token);
      await prefs.setString(_chaveEmail, email);
      await prefs.setString(_chaveTelefone, telefone);

      if (nome != null && nome!.trim().isNotEmpty) {
        await prefs.setString(_chaveNome, nome!.trim());
      } else {
        await prefs.remove(_chaveNome);
      }
    } catch (_) {
      // Sem armazenamento: a cliente só precisará pedir o código de novo.
    }
  }

  static Future<void> limpar() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_chaveToken);
      await prefs.remove(_chaveEmail);
      await prefs.remove(_chaveTelefone);
      await prefs.remove(_chaveNome);
    } catch (_) {}
  }
}