import 'dart:convert';

import 'package:http/http.dart' as http;

/// Erro devolvido pela API (ou falha de conexão), com uma mensagem pronta para a tela.
class ApiException implements Exception {
  final int statusCode; // 0 = sem conexão
  final String mensagem;

  ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => mensagem;
}

/// Único ponto de contato com a API: guarda o token e monta todas as requisições.
/// Uso: await ApiClient.instancia.login(email, senha);
///      final lista = await ApiClient.instancia.get('/categorias');
class ApiClient {
  ApiClient._();
  static final ApiClient instancia = ApiClient._();

  // Flutter web/desktop no mesmo PC: 127.0.0.1
  // Emulador Android: http://10.0.2.2:8000
  // Celular de verdade: o IP do PC na rede (ex.: http://192.168.0.10:8000)
  static const String baseUrl = 'http://127.0.0.1:8000';

  String? _token;
  bool get autenticado => _token != null;

  /// A API respondeu 401 (token vencido): a tela deve voltar para o login.
  void Function()? aoExpirarSessao;

  // ---------- autenticação ----------
  Future<void> login(String email, String senha) async {
    try {
      final resposta = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        // Map vira formulário (application/x-www-form-urlencoded), como a API espera
        body: {'username': email, 'password': senha},
      );
      final dados = _decodificar(resposta);
      if (resposta.statusCode != 200) {
        throw ApiException(resposta.statusCode, _mensagemDeErro(dados));
      }
      _token = dados['access_token'] as String;
    } on http.ClientException {
      throw ApiException(0, 'Sem conexão com o servidor.');
    }
  }

  void sair() => _token = null;

  // ---------- requisições ----------
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String caminho, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$caminho').replace(queryParameters: query);

  Future<dynamic> get(String caminho, {Map<String, String>? query}) =>
      _executar(() => http.get(_uri(caminho, query), headers: _headers));

  Future<dynamic> post(String caminho, Map<String, dynamic> corpo) => _executar(
      () => http.post(_uri(caminho), headers: _headers, body: jsonEncode(corpo)));

  Future<dynamic> patch(String caminho, Map<String, dynamic> corpo) => _executar(
      () => http.patch(_uri(caminho), headers: _headers, body: jsonEncode(corpo)));

  Future<dynamic> delete(String caminho) =>
      _executar(() => http.delete(_uri(caminho), headers: _headers));

  // ---------- apoio ----------
  Future<dynamic> _executar(Future<http.Response> Function() chamada) async {
    try {
      return _tratar(await chamada());
    } on http.ClientException {
      // Servidor desligado, rede fora do ar ou (no Flutter web) CORS não liberado
      throw ApiException(0, 'Sem conexão com o servidor.');
    }
  }

  dynamic _tratar(http.Response resposta) {
    final dados = _decodificar(resposta);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;

    if (resposta.statusCode == 401) {
      _token = null;
      aoExpirarSessao?.call();
    }
    throw ApiException(resposta.statusCode, _mensagemDeErro(dados));
  }

  /// utf8.decode(bodyBytes) em vez de resposta.body: a API não manda o charset,
  /// e o 'body' leria os acentos errado ("invÃ¡lidos").
  dynamic _decodificar(http.Response resposta) {
    if (resposta.bodyBytes.isEmpty) return null; // 204 não tem corpo
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  String _mensagemDeErro(dynamic dados) {
    if (dados is Map && dados['detail'] != null) {
      final detail = dados['detail'];
      if (detail is String) return detail; // 400, 401, 404, 409...
      if (detail is List && detail.isNotEmpty && detail.first is Map) {
        // 422: lista de erros de validação
        final primeiro = detail.first as Map;
        final local = primeiro['loc'] is List ? (primeiro['loc'] as List).last : 'campo';
        return '$local: ${primeiro['msg']}';
      }
    }
    return 'Erro inesperado. Tente novamente.';
  }
}