import 'cliente.dart';
import 'servico.dart';

class Agendamento {
  final int? id;
  final Cliente cliente;
  final Servico servico;
  final DateTime dataHora;

  Agendamento({
    this.id,
    required this.cliente,
    required this.servico,
    required this.dataHora,
  });
}
