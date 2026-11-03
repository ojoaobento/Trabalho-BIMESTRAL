import 'package:main/models/cliente_model.dart';
import 'package:main/models/servico_model.dart';

enum StatusAgendamento {
  reservado('reservado', 'Reservado'),
  pendente('pendente', 'Pendente'),
  confirmado('confirmado', 'Confirmado'),
  cancelado('cancelado', 'Cancelado'),
  concluido('concluido', 'Concluído'),
  faltou('faltou', 'Faltou');

  final String valor;

  final String rotulo;

  const StatusAgendamento(this.valor, this.rotulo);

  static StatusAgendamento fromValor(String valor) =>
      StatusAgendamento.values.firstWhere((s) => s.valor == valor);

  List<StatusAgendamento> get proximos {
    switch (this) {
      case StatusAgendamento.reservado:
        return [StatusAgendamento.pendente, StatusAgendamento.cancelado];
      case StatusAgendamento.pendente:
        return [StatusAgendamento.confirmado, StatusAgendamento.cancelado];
      case StatusAgendamento.confirmado:
        return [
          StatusAgendamento.concluido,
          StatusAgendamento.faltou,
          StatusAgendamento.cancelado,
        ];
      default:
        return const [];
    }
  }
}

class AgendamentoModel {
  final int id;
  final DateTime dtInicio;
  final DateTime dtFim;
  final StatusAgendamento status;
  final double valorCobrado;
  final String? observacoes;
  final DateTime? reservaExpiraEm;
  final DateTime? dtCadastro;
  final ClienteModel? cliente;
  final ServicoModel? servico;

  AgendamentoModel({
    required this.id,
    required this.dtInicio,
    required this.dtFim,
    required this.status,
    required this.valorCobrado,
    this.observacoes,
    this.reservaExpiraEm,
    this.dtCadastro,
    this.cliente,
    this.servico,
  });

  factory AgendamentoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoModel(
      id: json['id'],
      dtInicio: DateTime.parse(json['dt_inicio']),
      dtFim: DateTime.parse(json['dt_fim']),
      status: StatusAgendamento.fromValor(json['status']),
      valorCobrado: _paraDouble(json['valor_cobrado']),
      observacoes: json['observacoes'],
      reservaExpiraEm: json['reserva_expira_em'] != null
          ? DateTime.parse(json['reserva_expira_em'])
          : null,
      dtCadastro: json['dt_cadastro'] != null
          ? DateTime.parse(json['dt_cadastro'])
          : null,
      cliente: json['cliente'] != null
          ? ClienteModel.fromJson(json['cliente'])
          : null,
      servico: json['servico'] != null
          ? ServicoModel.fromJson(json['servico'])
          : null,
    );
  }

  static double _paraDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.parse(v.toString());
  }

  static String _dois(int n) => n.toString().padLeft(2, '0');

  String get dataTexto {
    final d = dtInicio.toLocal();
    return '${_dois(d.day)}/${_dois(d.month)}/${d.year}';
  }

  String get horaInicioTexto {
    final d = dtInicio.toLocal();
    return '${_dois(d.hour)}:${_dois(d.minute)}';
  }

  String get horaFimTexto {
    final d = dtFim.toLocal();
    return '${_dois(d.hour)}:${_dois(d.minute)}';
  }

  String get valorTexto {
    final partes = valorCobrado.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }

  bool get podeRemarcar =>
      status == StatusAgendamento.pendente ||
      status == StatusAgendamento.confirmado;
}