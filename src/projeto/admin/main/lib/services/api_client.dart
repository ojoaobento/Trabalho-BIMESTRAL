import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode; 
  final String mensagem;

  ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => mensagem;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instancia = ApiClient._();

  static const String baseUrl = 'http://127.0.0.1:8000';

  String? _token;
  bool get autenticado => _token != null;

  void Function()? aoExpirarSessao;

  Future<void> login(String email, String senha) async {
    try {
      final resposta = await http.post(
        Uri.parse('$baseUrl/auth/login'),
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

  Future<dynamic> _executar(Future<http.Response> Function() chamada) async {
    try {
      return _tratar(await chamada());
    } on http.ClientException {
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


  dynamic _decodificar(http.Response resposta) {
    if (resposta.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  String _mensagemDeErro(dynamic dados) {
    if (dados is Map && dados['detail'] != null) {
      final detail = dados['detail'];
      if (detail is String) return detail; 
      if (detail is List && detail.isNotEmpty && detail.first is Map) {
        final primeiro = detail.first as Map;
        final local = primeiro['loc'] is List ? (primeiro['loc'] as List).last : 'campo';
        return '$local: ${primeiro['msg']}';
      }
    }
    return 'Erro inesperado. Tente novamente.';
  }
}