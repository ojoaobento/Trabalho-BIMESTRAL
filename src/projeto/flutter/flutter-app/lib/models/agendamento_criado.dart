class AgendamentoCriado {
  final int id;
  final DateTime inicio;
  final DateTime fim;
  final String status;
  final String servicoNome;

  /// Calculado pelo servidor (status e antecedência mínima).
  final bool podeCancelar;

  AgendamentoCriado({
    required this.id,
    required this.inicio,
    required this.fim,
    required this.status,
    required this.servicoNome,
    this.podeCancelar = false,
  });

  factory AgendamentoCriado.fromJson(Map<String, dynamic> json) {
    return AgendamentoCriado(
      id: json['id'],
      inicio: DateTime.parse(json['dt_inicio']),
      fim: DateTime.parse(json['dt_fim']),
      status: json['status'],
      servicoNome: json['servico']?['nome'] ?? '',
      podeCancelar: json['pode_cancelar'] == true,
    );
  } 
}