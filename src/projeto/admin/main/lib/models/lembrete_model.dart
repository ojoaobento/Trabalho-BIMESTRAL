enum TipoLembrete {
  confirmacao('confirmacao'),
  lembrete24h('lembrete_24h');

  final String valor;
  const TipoLembrete(this.valor);

  static TipoLembrete fromString(String valor) {
    return TipoLembrete.values.firstWhere(
      (t) => t.valor == valor,
      orElse: () => throw ArgumentError('TipoLembrete inválido: $valor'),
    );
  }
}

class LembreteModel {
  final int id;
  final int agendamentoId;
  final int? servicoId;
  final DateTime enviarEm;
  final TipoLembrete tipo;
  final bool enviado;
  final DateTime? enviadoEm;

  const LembreteModel({
    required this.id,
    required this.agendamentoId,
    this.servicoId,
    required this.enviarEm,
    required this.tipo,
    required this.enviado,
    this.enviadoEm,
  });

  factory LembreteModel.fromJson(Map<String, dynamic> json) {
    return LembreteModel(
      id: json['id'] as int,
      agendamentoId: json['agendamento_id'] as int,
      servicoId: json['servico_id'] as int?,
      enviarEm: DateTime.parse(json['enviar_em'] as String),
      tipo: TipoLembrete.fromString(json['tipo'] as String),
      enviado: (json['enviado'] as bool?) ?? false,
      enviadoEm: json['enviado_em'] != null
          ? DateTime.parse(json['enviado_em'] as String)
          : null,
    );
  }
}