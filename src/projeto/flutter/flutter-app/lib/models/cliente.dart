class Cliente {
  final int? id;
  final String nome;
  final String telefone;
  final String email;
  final bool aceitasLembretes;
  final DateTime? consentimentoEm;
  final DateTime dtCadastro;

  Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    this.aceitasLembretes = false,
    this.consentimentoEm,
    DateTime? dtCadastro,
  }) : dtCadastro = dtCadastro ??DateTime.now();
}