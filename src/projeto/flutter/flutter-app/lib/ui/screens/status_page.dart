import 'package:flutter/material.dart';
import 'package:main/ui/screens/home_page.dart';

class SolicitacaoConfirmadaPage extends StatelessWidget {
  const SolicitacaoConfirmadaPage({
    super.key,
    required this.data,
    required this.horario,
    required this.servico,
    required this.whatsApp,
  });

  final DateTime data;
  final String horario;
  final String servico;
  final String whatsApp;

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
                    'Enviaremos a confirmação detalhada no seu WhatsApp',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, height: 1.35, color: Color(0xFF976D7B)),
                  ),
                  Text(
                    '$whatsApp e também lembrete automático 24 horas\nantes do atendimento.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, height: 1.35, color: Color(0xFF976D7B)),
                  ),
                  const SizedBox(height: 17),
                  _resumo(),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // A tela de "Meus agendamentos" será ligada aqui
                        // assim que estiver disponível no fluxo.
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _corPrincipal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
                      label: const Text(
                        'Ver meus agendamentos',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomePage()),
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
                      child: const Text('Voltar ao início', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                    ],
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
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
    child: Column(
      children: [
        const Row(
          children: [
            _EtapaProgresso('1. Horário'),
            _EtapaProgresso('2. Serviço'),
            _EtapaProgresso('3. Seus dados'),
            _EtapaProgresso('4. Confirmar'),
            _EtapaProgresso('5. Status', ativa: true),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: List.generate(
            5,
            (_) => Expanded(child: Container(height: 3, color: _corPrincipal)),
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
      'SOLICITAÇÃO CONFIRMADA',
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
          children: const [
            Text('CÓDIGO DO AGENDAMENTO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF976D7B))),
            Spacer(),
            Text('#SC-8492', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _corPrincipal)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: _corBorda),
        ),
        _linha('Serviço:', servico),
        const SizedBox(height: 7),
        _linha('Data & horário:', _dataFormatada()),
        const SizedBox(height: 7),
        Row(
          children: [
            const Text('Status atual:', style: TextStyle(fontSize: 9, color: Color(0xFF976D7B))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFFF1D9), borderRadius: BorderRadius.circular(10)),
              child: const Text('Pendente de aprovação', style: TextStyle(fontSize: 8, color: Color(0xFF9B661E))),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _linha(String rotulo, String valor) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
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
          textAlign: TextAlign.end,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: _corTexto,
          ),
        ),
      ),
    ],
  );

  String _dataFormatada() {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    return '${dias[data.weekday - 1]} ${data.day} de ${meses[data.month - 1]} · $horario';
  }
}

class _EtapaProgresso extends StatelessWidget {
  const _EtapaProgresso(this.texto, {this.ativa = false});

  final String texto;
  final bool ativa;

  @override
  Widget build(BuildContext context) => Expanded(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: ativa ? FontWeight.bold : FontWeight.normal,
          color: ativa ? SolicitacaoConfirmadaPage._corPrincipal : Colors.black45,
        ),
      ),
    ),
  );
}
