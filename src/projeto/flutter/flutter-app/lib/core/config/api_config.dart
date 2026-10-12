/// Centraliza o endereço do backend.
///
/// Para trocar a URL sem editar o código, execute o app com:
/// flutter run --dart-define=API_BASE_URL=http://SEU_IP:8000
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
