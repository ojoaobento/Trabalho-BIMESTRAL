import 'cliente.dart';
import 'servico.dart';

class Agendamento {
  final int? id;
  final Cliente cliente;
  final Servico servico;
  final DataTime dataHora;
  final String status;

  Agendamento({
    this.id,
    required this.cliente,
    required this.servico,
    required this.dataHora,
    required this.status,
  });
}