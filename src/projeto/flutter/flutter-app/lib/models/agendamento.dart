import 'cliente.dart';
import 'servico.dart';

class Agendamento {
  final int? id;
  final Cliente cliente;
  final Servico servico;
  final int? confirmadoPor;
  final DateTime dtInicio;
  final DateTime dtFim;
  final DateTime? reservaExpiraEm;
  final String status;
  final double valorCobrado;
  final String? observacoes;
  final DateTime? dtCadastro;

  Agendamento({
    this.id,
    required this.cliente,
    required this.servico,
    this.confirmadoPor,
    required this.dtInicio,
    required this.dtFim,
    this.reservaExpiraEm,
    required this.status,
    required this.valorCobrado,
    this.observacoes,
    this.dtCadastro,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'],
      cliente: Cliente.fromJson(json['cliente']),
      servico: Servico.fromJson(json['servico']),
      confirmadoPor: json['confirmado_por'],
      dtInicio: DateTime.parse(json['dt_inicio']),
      dtFim: DateTime.parse(json['dt_fim']),
      reservaExpiraEm: json['reserva_expira_em'] != null
          ? DateTime.parse(json['reserva_expira_em'])
          : null,
      status: json['status'],
      valorCobrado: (json['valor_cobrado'] as num).toDouble(),
      observacoes: json['observacoes'],
      dtCadastro: json['dt_cadastro'] != null
          ? DateTime.parse(json['dt_cadastro'])
          : null,
    );
  }
}