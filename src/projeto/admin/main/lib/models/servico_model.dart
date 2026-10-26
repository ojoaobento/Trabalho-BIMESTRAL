class ServicoModel {
  final int id;
  final int categoriaId;
  final String nome;
  final String? descricao;

  final String preco;
  final int duracaoMinutos;
  final bool ativo;

  const ServicoModel({
    required this.id,
    required this.categoriaId,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.duracaoMinutos,
    required this.ativo,
  });

  factory ServicoModel.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'];
    final categoriaId =
        json['categoria_id'] ?? (categoria is Map ? categoria['id'] : null);

    return ServicoModel(
      id: json['id'] as int,
      categoriaId: categoriaId as int,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      preco: json['preco'].toString(),
      duracaoMinutos: json['duracao_minutos'] as int,
      ativo: (json['ativo'] as bool?) ?? true,
    );
  }

  String get precoFormatado {
    final valor = double.tryParse(preco) ?? 0;
    final texto = valor.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $texto';
  }
}