class Cliente {
  final int? id;
  final String nome;
  final String telefone;
  final String? email;
  final bool aceitaLembretes;
  final DateTime? consentimentoEm;
  final DateTime? dtCadastro;

  Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    this.email,
    required this.aceitaLembretes,
    this.consentimentoEm,
    this.dtCadastro,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nome: json['nome'],
      telefone: json['telefone'],
      email: json['email'],
      aceitaLembretes: json['aceita_lembretes'] ?? false,
      consentimentoEm: json['consentimento_em'] != null
          ? DateTime.parse(json['consentimento_em'])
          : null,
      dtCadastro: json['dt_cadastro'] != null
          ? DateTime.parse(json['dt_cadastro'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'aceita_lembretes': aceitaLembretes,
      'consentimento_em': consentimentoEm?.toIso8601String(),
      'dt_cadastro': dtCadastro?.toIso8601String(),
    };
  }
}