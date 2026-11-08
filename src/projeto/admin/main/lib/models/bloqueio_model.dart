class BloqueioModel {
  final int id;
  final DateTime dtInicio;
  final DateTime dtFim;
  final String? motivo;
  final int? criadoPor;
  final DateTime criadoEm;

  const BloqueioModel({
    required this.id,
    required this.dtInicio,
    required this.dtFim,
    this.motivo,
    this.criadoPor,
    required this.criadoEm,
  });

  factory BloqueioModel.fromJson(Map<String, dynamic> json) {
    return BloqueioModel(
      id: json['id'] as int,
      dtInicio: DateTime.parse(json['dt_inicio'] as String).toLocal(),
      dtFim: DateTime.parse(json['dt_fim'] as String).toLocal(),
      motivo: json['motivo'] as String?,
      criadoPor: json['criado_por'] as int?,
      criadoEm: DateTime.parse(json['criado_em'] as String).toLocal(),
    );
  }

  String get dataTexto {
    final d = dtInicio;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get horaInicioTexto {
    final d = dtInicio;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get horaFimTexto {
    final d = dtFim;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

