import 'dart:async';

import 'package:flutter/material.dart';
import 'package:main/ui/screens/status_page.dart';

class RevisaoPage extends StatefulWidget {
  const RevisaoPage({
    super.key,
    required this.data,
    required this.horario,
    required this.servico,
    required this.preco,
    required this.duracao,
    required this.nome,
    required this.whatsApp,
  });

  final DateTime data;
  final String horario;
  final String servico;
  final double preco;
  final int duracao;
  final String nome;
  final String whatsApp;

  @override
  State<RevisaoPage> createState() => _RevisaoPageState();
}

class _RevisaoPageState extends State<RevisaoPage> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corBorda = Color(0xFFF1DDE5);

  int _segundosRestantes = 2 * 60 + 25;
  Timer? _cronometro;

  @override
  void initState() {
    super.initState();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes == 0) {
        timer.cancel();
        return;
      }

      setState(() => _segundosRestantes--);
    });
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      body: SafeArea(
        child: Column(
          children: [
            _progresso(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(11, 16, 11, 18),
                children: [
                  _titulo(),
                  const SizedBox(height: 14),
                  _preReserva(),
                  const SizedBox(height: 12),
                  _servico(),
                  const SizedBox(height: 9),
                  _dadosData(),
                  const SizedBox(height: 9),
                  _local(),
                  const SizedBox(height: 9),
                  _cliente(),
                ],
              ),
            ),
            _rodape(),
          ],
        ),
      ),
    );
  }

  Widget _progresso() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1. Horário',
                style: TextStyle(fontSize: 10, color: _corPrincipal),
              ),
              Text(
                '2. Serviço',
                style: TextStyle(fontSize: 10, color: _corPrincipal),
              ),
              Text(
                '3. Seus dados',
                style: TextStyle(fontSize: 10, color: _corPrincipal),
              ),
              Text(
                '4. Confirmar',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _corPrincipal,
                ),
              ),
              Text(
                '5. Status do agendamento',
                style: TextStyle(fontSize: 8, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Expanded(
                child: Divider(color: _corPrincipal, thickness: 3),
              ),
              Expanded(child: Container(height: 3, color: _corPrincipal)),
              Expanded(child: Container(height: 3, color: _corPrincipal)),
              const Expanded(child: Divider(color: _corBorda, thickness: 3)),
              Expanded(child: Container(height: 3, color: _corPrincipal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _titulo() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: _corBorda),
          ),
          icon: const Icon(Icons.chevron_left, size: 18),
          color: _corTexto,
        ),
        const SizedBox(width: 8),
        const Text(
          'REVISÃO FINAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _corPrincipal,
          ),
        ),
      ],
    );
  }

  Widget _preReserva() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 11,
            backgroundColor: _corPrincipal,
            child: Icon(Icons.lock_outline, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horário pré-reservado!',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corPrincipal,
                  ),
                ),
                Text(
                  'Seu horário fica reservado por mais:',
                  style: TextStyle(fontSize: 9, color: Color(0xFF9A6C7C)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _tempoRestanteFormatado(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _corPrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servico() {
    return _cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SERVIÇO ESCOLHIDO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _corPrincipal,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // A pilha de navegação é Horário > Serviço > Seus dados >
                  // Revisão. Voltar duas telas retorna diretamente à seleção
                  // do serviço e preserva o horário escolhido.
                  final navigator = Navigator.of(context);
                  navigator
                    ..pop()
                    ..pop();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: _corPrincipal,
                ),
                child: const Text(
                  'Editar',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            widget.servico,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _corTexto,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Serviço selecionado para o seu horário.',
            style: TextStyle(fontSize: 10, color: Color(0xFF976D7B)),
          ),
        ],
      ),
    );
  }

  Widget _dadosData() {
    return Row(
      children: [
        Expanded(
          child: _cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATA E HORÁRIO',
                  style: TextStyle(fontSize: 8, color: Color(0xFF9A6C7C)),
                ),
                const SizedBox(height: 4),
                Text(
                  _dataFormatada(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Término previsto: ${_fimPrevisto()}',
                  style: const TextStyle(fontSize: 8, color: Color(0xFF976D7B)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DURAÇÃO & VALOR',
                  style: TextStyle(fontSize: 8, color: Color(0xFF9A6C7C)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.duracao} min · R\$ ${widget.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pagamento no local',
                  style: TextStyle(fontSize: 8, color: Color(0xFF976D7B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _local() {
    return _cartao(
      child: const Row(
        children: [
          Icon(Icons.location_on_outlined, color: _corPrincipal, size: 17),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Studio Cleusa',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _corTexto,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Av. Brasil, 1420 – Sala 4 · Maringá, PR',
                style: TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cliente() {
    return _cartao(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agendado para:',
                  style: TextStyle(fontSize: 9, color: Color(0xFF9A6C7C)),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.nome,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.whatsApp,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: _corPrincipal,
            ),
            child: const Text(
              'Editar',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartao({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _corBorda),
      ),
      child: child,
    );
  }

  Widget _rodape() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => SolicitacaoConfirmadaPage(
                    data: widget.data,
                    horario: widget.horario,
                    servico: widget.servico,
                    whatsApp: widget.whatsApp,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _corPrincipal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Confirmar agendamento'),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sem pagamento antecipado. Você paga diretamente no studio.',
            style: TextStyle(fontSize: 8, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  String _dataFormatada() {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const meses = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${dias[widget.data.weekday - 1]} ${widget.data.day} de ${meses[widget.data.month - 1]} · ${widget.horario}';
  }

  String _fimPrevisto() {
    final partes = widget.horario.split(':');
    final inicioEmMinutos = int.parse(partes[0]) * 60 + int.parse(partes[1]);
    final fimEmMinutos = inicioEmMinutos + widget.duracao;
    final horas = (fimEmMinutos ~/ 60) % 24;
    final minutos = fimEmMinutos % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }

  String _tempoRestanteFormatado() {
    final minutos = _segundosRestantes ~/ 60;
    final segundos = _segundosRestantes % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }
}
