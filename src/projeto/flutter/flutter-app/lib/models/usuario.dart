class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String senhaHash;
  final bool ativo;

  Usuario({
this.id,
required this.nome,
required this.email,
required this.senhaHash,
this.ativo = true,
DateTime? dtCadastro,
}) : dtCadastro = dtCadastro ?? DateTime.now();
}