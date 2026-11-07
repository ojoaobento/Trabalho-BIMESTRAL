import 'package:flutter/material.dart';
import 'package:main/models/agendamento_criado.dart';
import 'package:main/ui/screens/home_page.dart';
import 'meus_agendamentos.dart';
class SolicitacaoConfirmadaPage extends StatelessWidget {
  const SolicitacaoConfirmadaPage({
    super.key,
    required this.agendamento,
    required this.whatsApp,
    required this.email,
  });

  final AgendamentoCriado agendamento;
  final String whatsApp;
  final String email;

  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corBorda = Color(0xFFF1DDE5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      body: SafeArea(
        child: Column(
          children: [
            _progresso(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(17, 30, 17, 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        _iconeConfirmacao(),
                        const SizedBox(height: 17),
                        _etiqueta(),
                        const SizedBox(height: 10),
                        const Text(
                          'Agendamento solicitado!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _corTexto,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Enviaremos a confirmação detalhada para o e-mail',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            color: Color(0xFF976D7B),
                          ),
                        ),
                        Text(
                          '$email e também lembrete automático 24 horas\nantes do atendimento.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            color: Color(0xFF976D7B),
                          ),
                        ),
                        const SizedBox(height: 17),
                        _resumo(),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeusAgendamentosPage(
                                  email: email,
                                  telefone: whatsApp,
                                ),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _corPrincipal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                            ),
                            label: const Text(
                              'Ver meus agendamentos',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomePage(),
                              ),
                              (route) => false,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _corTexto,
                              side: const BorderSide(color: _corBorda),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text(
                              'Voltar ao início',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progresso() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1. Horário', style: TextStyle(fontSize: 10, color: _corPrincipal)),
                Text('2. Serviço', style: TextStyle(fontSize: 10, color: _corPrincipal)),
                Text('3. Seus dados', style: TextStyle(fontSize: 10, color: _corPrincipal)),
                Text('4. Confirmar', style: TextStyle(fontSize: 10, color: _corPrincipal)),
                Text(
                  '5. Status',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _corPrincipal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  5,
                  (_) => Expanded(
                    child: Container(height: 3, color: _corPrincipal),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _iconeConfirmacao() => Container(
        width: 61,
        height: 61,
        decoration: BoxDecoration(
          color: const Color(0xFFF1FBF7),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBCEEDB), width: 3),
        ),
        child: const Icon(Icons.check, color: Color(0xFF16866C), size: 29),
      );

  Widget _etiqueta() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F8F1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBCEEDB)),
        ),
        child: const Text(
          'SOLICITAÇÃO REGISTRADA',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: .8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF16866C),
          ),
        ),
      );

  Widget _resumo() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _corBorda),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'ID DO AGENDAMENTO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF976D7B),
                  ),
                ),
                const Spacer(),
                Text(
                  agendamento.id.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _corPrincipal,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: _corBorda),
            ),
            _linha('Serviço:', agendamento.servicoNome),
            _linha('Data & horário:', _dataFormatada()),
            _linhaStatus(),
          ],
        ),
      );

  Widget _linha(String rotulo, String valor) => SizedBox(
        height: 24,
        child: Row(
          children: [
            SizedBox(
              width: 105,
              child: Text(
                rotulo,
                style: const TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
              ),
            ),
            Expanded(
              child: Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _corTexto,
                ),
              ),
            ),
          ],
        ),
      );

  ({String rotulo, Color fundo, Color texto}) _statusVisual() {
    switch (agendamento.status.toLowerCase()) {
      case 'confirmado':
        return (
          rotulo: 'Confirmado',
          fundo: const Color(0xFFE7F8F1),
          texto: const Color(0xFF16866C),
        );
      case 'cancelado':
        return (
          rotulo: 'Cancelado',
          fundo: const Color(0xFFFDE7E9),
          texto: const Color(0xFFB3261E),
        );
      default:
        return (
          rotulo: 'Pendente de aprovação',
          fundo: const Color(0xFFFFF1D9),
          texto: const Color(0xFF9B661E),
        );
    }
  }

  Widget _linhaStatus() {
    final visual = _statusVisual();

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          const Text(
            'Status atual:',
            style: TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: visual.fundo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              visual.rotulo,
              style: TextStyle(fontSize: 8, color: visual.texto),
            ),
          ),
        ],
      ),
    );
  }

  String _dataFormatada() {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    const meses = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];

    final d = agendamento.inicio;
    final hora = d.hour.toString().padLeft(2, '0');
    final minuto = d.minute.toString().padLeft(2, '0');

    return '${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]} · $hora:$minuto';
  }
}