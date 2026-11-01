import 'package:flutter/material.dart';
import 'package:main/ui/screens/revisao_page.dart';

class IdentificacaoPage extends StatefulWidget {
  const IdentificacaoPage({
    super.key,
    required this.data,
    required this.horario,
    required this.servico,
    required this.preco,
    required this.duracao,
  });

  final DateTime data;
  final String horario;
  final String servico;
  final double preco;
  final int duracao;

  @override
  State<IdentificacaoPage> createState() => _IdentificacaoPageState();
}

class _IdentificacaoPageState extends State<IdentificacaoPage> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corBorda = Color(0xFFF1DDE5);

  bool _autorizouDados = false;
  bool _autorizouWhatsApp = false;
  final _nomeController = TextEditingController(text: 'Maria Cleusa');
  final _whatsAppController = TextEditingController(text: '(44) 99876-5432');

  @override
  void dispose() {
    _nomeController.dispose();
    _whatsAppController.dispose();
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
                padding: const EdgeInsets.fromLTRB(13, 16, 13, 22),
                children: [
                  _titulo(),
                  const SizedBox(height: 15),
                  _clienteAgendado(),
                  const SizedBox(height: 18),
                  const Text(
                    'Quase lá! Como podemos te\navisar?',
                    style: TextStyle(
                      fontSize: 21,
                      height: 1.12,
                      fontWeight: FontWeight.bold,
                      color: _corTexto,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Sem senha e sem cadastro longo. Apenas o essencial para garantir seu horário.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF976D7B)),
                  ),
                  const SizedBox(height: 12),
                  _botaoGoogle(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: _corBorda)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OU PREENCHA ABAIXO',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF976D7B),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: _corBorda)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _campo('Nome completo *', _nomeController),
                  const SizedBox(height: 11),
                  _campo(
                    'WhatsApp para confirmação *',
                    _whatsAppController,
                    prefixo: 'BR',
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 12, color: _corPrincipal),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Enviaremos a confirmação e o lembrete 24h antes por mensagem.',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF976D7B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CheckboxListTile(
                    value: _autorizouDados,
                    onChanged: (valor) =>
                        setState(() => _autorizouDados = valor ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: _corPrincipal,
                    title: const Text(
                      'Autorizo o uso dos meus dados para agendamento e lembretes conforme a LGPD.',
                      style: TextStyle(fontSize: 9, color: Color(0xFF6F5360)),
                    ),
                  ),
                  CheckboxListTile(
                    value: _autorizouWhatsApp,
                    onChanged: (valor) =>
                        setState(() => _autorizouWhatsApp = valor ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: _corPrincipal,
                    title: const Text(
                      'Autorizo o envio de confirmações e lembretes pelo WhatsApp.',
                      style: TextStyle(fontSize: 9, color: Color(0xFF6F5360)),
                    ),
                  ),
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _corPrincipal,
                ),
              ),
              Text(
                '4. Confirmar',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
              Text(
                '5. Status',
                style: TextStyle(fontSize: 10, color: Colors.black45),
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
              const Expanded(child: Divider(color: _corBorda, thickness: 3)),
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
          'IDENTIFICAÇÃO DO CLIENTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _corPrincipal,
          ),
        ),
      ],
    );
  }

  Widget _clienteAgendado() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nomeController,
      builder: (context, _, _) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: _whatsAppController,
        builder: (context, _, _) => _clienteAgendadoConteudo(),
      ),
    );
  }

  Widget _clienteAgendadoConteudo() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _corPrincipal, width: 1.3),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: _corPrincipal,
            child: Text(
              'MC',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Agendando como ${_nomeController.text}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _corTexto,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  _whatsAppController.text,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF976D7B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoGoogle() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: _corTexto,
          side: const BorderSide(color: _corBorda),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Text(
          'G',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
        ),
        label: const Text(
          'Continuar com o Google',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _campo(
    String titulo,
    TextEditingController controller, {
    String? prefixo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _corTexto,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 11, color: _corTexto),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            prefixText: prefixo == null ? null : '$prefixo   ',
            prefixStyle: const TextStyle(fontSize: 10, color: _corTexto),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _corBorda),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _corBorda),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _corPrincipal),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rodape() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identificação rápida',
                  style: TextStyle(fontSize: 9, color: Colors.black45),
                ),
                Text(
                  'Seus dados ficam protegidos',
                  style: TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              _InstantPageRoute(
                builder: (_) => RevisaoPage(
                  data: widget.data,
                  horario: widget.horario,
                  servico: widget.servico,
                  preco: widget.preco,
                  duracao: widget.duracao,
                  nome: _nomeController.text,
                  whatsApp: _whatsAppController.text,
                ),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _corPrincipal,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            label: const Text('Continuar'),
            icon: const Icon(Icons.arrow_forward, size: 16),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}

class _InstantPageRoute<T> extends PageRouteBuilder<T> {
  _InstantPageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
}
