import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:main/core/config/api_config.dart';

/// Serviço responsável por fazer as requisições para a API.
///
/// As outras partes do app devem usar esta classe, em vez de repetir URLs
/// e configurações HTTP nas telas.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Faz uma requisição GET e devolve o JSON convertido para Map.
  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      final response = await _client.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'A API respondeu com o status ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const ApiException(
          'A resposta da API não está no formato esperado.',
        );
      }

      return body;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Não foi possível conectar à API. Verifique se ela está em execução.',
      );
    }
  }

  /// Exemplo de chamada para o endpoint atual do backend: GET /.
  Future<String> buscarMensagemInicial() async {
    final resposta = await get('/');
    return resposta['mensagem'] as String? ?? 'API funcionando.';
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
