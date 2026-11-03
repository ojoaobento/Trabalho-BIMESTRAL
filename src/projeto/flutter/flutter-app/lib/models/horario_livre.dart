class HorarioLivre {
  final String horario;
  final int minutosLivres;

  const HorarioLivre({
    required this.horario,
    required this.minutosLivres,
  });

  factory HorarioLivre.fromJson(Map<String, dynamic> json) {
    return HorarioLivre(
      horario: (json['horario'] as String).substring(0, 5),
      minutosLivres: json['minutos_livres'] as int,
    );
  }
}