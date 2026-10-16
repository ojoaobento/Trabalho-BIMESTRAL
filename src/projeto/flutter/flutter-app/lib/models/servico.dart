class Servico {
  final int? id;
  final int categoriaId;  
  final String nome;
  final String descricao;
  final double preco;
  final int duracaoMinutos;
  final bool ativo;

  Servico({
    this.id,
    required this.categoriaId,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.duracaoMinutos,
    this.ativo = true,
  });
}