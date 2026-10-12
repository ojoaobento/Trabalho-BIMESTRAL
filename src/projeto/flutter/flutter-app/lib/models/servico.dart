class Servico {
  final int? id;
  final String nome;
  final double preco;
  final int duracaoMinutos;

  Servico({
    this.id,
    required this.nome,
    required this.preco,
    required this.duracaoMinutos,
  });
}