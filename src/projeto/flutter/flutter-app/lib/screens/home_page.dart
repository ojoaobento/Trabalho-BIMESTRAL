import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../models/agendamento.dart';
import '../models/cliente.dart';
import '../models/servico.dart';
import 'cliente.dart';
import 'servico.dart';
import 'agendamento.dart';
class HomePage extends StatefulWidget {
  const new({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

final Cliente1 = Cliente
(
  nome: 'Joao', 
  telefone: '44999080240', 
  email: 'Joao@gmail.com'
  );

  final servico1 = Servico(
    nome: 'Joao', 
    preco: '50', 
    duracaoMinutos: '60');

    final agendamento1 = Agendamento(
      cliente: Cliente1, 
      servico: servico1, 
      dataHora: DateTime(2026,10,10,08,30), 
      status: 'Agendado');