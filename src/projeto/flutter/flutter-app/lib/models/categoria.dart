class Categoria {
  final int? id;
  final String nome;
  final bool ativo;

  Categoria({
    this.id,
    required this.nome,
    this.ativo = true,
  });
}