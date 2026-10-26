class CategoriaModel {
  final int id;
  final String nome;
  final bool ativo;

  const CategoriaModel({
    required this.id,
    required this.nome,
    required this.ativo,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as int,
      nome: json['nome'] as String,
      ativo: (json['ativo'] as bool?) ?? true,
    );
  }
}