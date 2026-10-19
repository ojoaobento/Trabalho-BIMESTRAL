import 'cliente.dart';
import 'servico.dart';

class Agendamento {
  final int? id;
  final Cliente cliente;
  final Servico servico;
  final int? confirmadorPor;
  final DateTime dtInicio;
  final DateTime dtFim;
  final DateTime? reservaExpireEm;
  final String status;
  final doubleValorCobrado;
  final String? Observacoes;
  final DateTime dtCadastro;
  
  Agendamento({
    this.id,
    required this.cliente,
    required this.servico,
    this.confirmadorPor,
    required this.dtInicio,
    required this.dtFim,
    this.reservaExpireEm,
    required this.status,
    required this.valorCobrado,
    this.observacoes,
    DateTime? dtCadastro,
  }) : dtCadastro = dtCadastro ?? DateTime.now();
}