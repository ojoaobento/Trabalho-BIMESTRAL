import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String horarioSelecionado = '14:30';

  final dias = const ['Seg 12', 'Ter 13', 'Qua 14', 'Qui 15', 'Sex 16', 'Sáb 17'];
  final horarios = const ['09:00', '10:30', '14:30', '16:00', '17:00', '18:30', '19:30'];

  static const corPrincipal = Color(0xFFB85D43);
  static const corFundo = Color(0xFFFFF8F5);
  static const corTexto = Color(0xFF3B0900);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: corPrincipal)),
      home: Scaffold(
        backgroundColor: corFundo,
        body: SafeArea(
          child: Column(
            children: [
              _cabecalho(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('ESTÉTICA & BELEZA',
                        style: TextStyle(color: corPrincipal, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    const Text('Escolha o melhor\nhorário para você',
                        style: TextStyle(fontSize: 29, height: 1.1, fontWeight: FontWeight.bold, color: corTexto)),
                    const SizedBox(height: 20),
                    _cardDestaque(),
                    const SizedBox(height: 28),
                    const Text('Outubro 2024',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corTexto)),
                    const SizedBox(height: 12),
                    _calendario(),
                    const SizedBox(height: 28),
                    const Text('Horários livres para Sexta, 16 de Outubro',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: corTexto)),
                    const SizedBox(height: 4),
                    const Text('●  7 horários livres', style: TextStyle(color: corPrincipal)),
                    const SizedBox(height: 20),
                    _secaoDeHorarios('Manhã', horarios.take(2).toList()),
                    _secaoDeHorarios('Tarde', horarios.skip(2).take(3).toList()),
                    _secaoDeHorarios('Noite', horarios.skip(5).toList()),
                  ],
                ),
              ),
              _rodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(children: [
        Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFFFE4DA), foregroundColor: corPrincipal, child: Icon(Icons.spa_outlined)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Studio Cleusa', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: corTexto))),
          TextButton(onPressed: () {}, child: const Text('Já agendei antes?')),
        ]),
        const SizedBox(height: 14),
        const Text('1. Horário  •  2. Serviço  •  3. Seus dados  •  4. Confirmar',
            style: TextStyle(fontSize: 12, color: corPrincipal)),
      ]),
    );
  }

  Widget _cardDestaque() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corPrincipal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DISPONÍVEL AGORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 16),
        const Text('Próximo horário livre:', style: TextStyle(color: Color(0xFFFFDBD0))),
        const Text('Hoje, 14:30', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold)),
        const Text('Janela de 2h30', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => horarioSelecionado = '14:30'),
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: corPrincipal),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Escolher este horário'),
        ),
      ]),
    );
  }

  Widget _calendario() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selecionado = index == 4;
          return Container(
            width: 65,
            decoration: BoxDecoration(
              color: selecionado ? corPrincipal : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selecionado ? corPrincipal : const Color(0xFFF0D9D1)),
            ),
            child: Center(
              child: Text(dias[index], textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: selecionado ? Colors.white : corTexto)),
            ),
          );
        },
      ),
    );
  }

  Widget _secaoDeHorarios(String titulo, List<String> lista) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: lista.map((horario) {
            final selecionado = horario == horarioSelecionado;
            return ChoiceChip(
              label: Text(horario),
              selected: selecionado,
              showCheckmark: false,
              selectedColor: const Color(0xFFFFDBD0),
              side: BorderSide(color: selecionado ? corPrincipal : const Color(0xFFF0D9D1)),
              onSelected: (_) => setState(() => horarioSelecionado = horario),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _rodape() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Selecionado: Sex 16 · $horarioSelecionado', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: corPrincipal, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Continuar'),
          ),
        ),
      ]),
    );
  }
}
