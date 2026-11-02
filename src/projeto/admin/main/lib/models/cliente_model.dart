class ClienteModel {
  final int id;
  final String nome;
  final String telefone;
  final String? email;
  final bool aceitaLembretes;
  final DateTime? consentimentoEm;
  final DateTime? dtCadastro;

  ClienteModel({
    required this.id,
    required this.nome,
    required this.telefone,
    this.email,
    required this.aceitaLembretes,
    this.consentimentoEm,
    this.dtCadastro,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'],
      nome: json['nome'],
      telefone: json['telefone'],
      email: json['email'],
      aceitaLembretes: json['aceita_lembretes'] ?? true,
      consentimentoEm: json['consentimento_em'] != null
          ? DateTime.parse(json['consentimento_em'])
          : null,
      dtCadastro: json['dt_cadastro'] != null
          ? DateTime.parse(json['dt_cadastro'])
          : null,
    );
  }
}