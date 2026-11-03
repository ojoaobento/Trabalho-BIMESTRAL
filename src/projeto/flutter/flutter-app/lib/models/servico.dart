class Servico {
  final int id;
  final int categoriaId;
  final String nome;
  final String? descricao;
  final double preco;
  final int duracaoMinutos;

  const Servico({
    required this.id,
    required this.categoriaId,
    required this.nome,
    this.descricao,
    required this.preco,
    required this.duracaoMinutos,
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'] as int,
      categoriaId: json['categoria_id'] as int,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      preco: double.parse(json['preco'].toString()),
      duracaoMinutos: json['duracao_minutos'] as int,
    );
  }
}