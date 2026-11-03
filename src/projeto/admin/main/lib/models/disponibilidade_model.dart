class DisponibilidadeModel {
  final int id;
  final int diaSemana;
  final String horaInicio;
  final String horaFim;
  final bool ativo;

  DisponibilidadeModel({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
    required this.ativo,
  });

  factory DisponibilidadeModel.fromJson(Map<String, dynamic> json) {
    return DisponibilidadeModel(
      id: json['id'],
      diaSemana: json['dia_semana'],
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      ativo: json['ativo'] ?? true,
    );
  }

  static const _dias = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  String get nomeDia => _dias[diaSemana];

  String get inicioCurto => horaInicio.substring(0, 5);
  String get fimCurto => horaFim.substring(0, 5);
}