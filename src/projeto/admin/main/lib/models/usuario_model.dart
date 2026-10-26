class UsuarioModel{
  final int id;
  final String nome;
  final String email;
  final bool ativo;
  final DateTime? dt_cadastro;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email, 
    required this.ativo,
    this.dt_cadastro
  });

  
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      ativo: json['ativo'] ?? true,
      dt_cadastro: json['dt_cadastro'] != null 
          ? DateTime.parse(json['dt_cadastro']) 
          : null,
    );
  }

}


