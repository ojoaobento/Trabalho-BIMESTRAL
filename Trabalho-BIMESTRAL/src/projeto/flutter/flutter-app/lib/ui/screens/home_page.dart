import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Os únicos dados que mudam quando a pessoa toca na tela.
  int diaSelecionado = 4;
  String horarioSelecionado = '14:30';

  final dias = const [
    ('Seg', '12', 'Lotado'),
    ('Ter', '13', '3 vagas'),
    ('Qua', '14', '5 vagas'),
    ('Qui', '15', '0 vagas'),
    ('Sex', '16', 'Hoje'),
    ('Sáb', '17', '6 vagas'),
  ];

  final horarios = const ['09:00', '10:30', '14:30', '16:00', '17:00', '18:30', '19:30'];

  static const corPrincipal = Color(0xFFB85D43);
  static const corTexto = Color(0xFF3B0900);
  static const corFundo = Color(0xFFFFF8F5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: corPrincipal),
      ),
      home: Scaffold(
        backgroundColor: corFundo,
        body: SafeArea(
          child: Column(
            children: [
              _cabecalho(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titulo(),
                      const SizedBox(height: 20),
                      _cardProximoHorario(),
                      const SizedBox(height: 28),
                      _calendario(),
                      const SizedBox(height: 28),
                      _horarios(),
                    ],
                  ),
                ),
              ),
              _botaoContinuar(),
            ],
          ),
        ),
      ),
    );
  }

  // Parte 1: nome do salão e as quatro etapas do agendamento.
  Widget _cabecalho() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFE6DE),
                foregroundColor: corPrincipal,
                child: Icon(Icons.spa_outlined),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Studio Cleusa',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: corTexto)),
              ),
              TextButton(onPressed: () {}, child: const Text('Já agendei antes?')),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _Etapa(numero: '1', texto: 'Horário', ativa: true),
              _Linha(),
              _Etapa(numero: '2', texto: 'Serviço'),
              _Linha(),
              _Etapa(numero: '3', texto: 'Dados'),
              _Linha(),
              _Etapa(numero: '4', texto: 'Confirmar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _titulo() {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ESTÉTICA & BELEZA',
          style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: corPrincipal, fontWeight: FontWeight.bold)),
      SizedBox(height: 7),
      Text('Escolha o melhor\nhorário para você',
          style: TextStyle(fontSize: 30, height: 1.08, color: corTexto, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Reserve seu momento de cuidado com tranquilidade.',
          style: TextStyle(color: Colors.black54)),
    ]);
  }

  // Parte 2: destaque do horário mais próximo disponível.
  Widget _cardProximoHorario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corPrincipal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.bolt_rounded, color: Color(0xFFFFD9CB), size: 18),
          SizedBox(width: 6),
          Text('DISPONÍVEL AGORA',
              style: TextStyle(color: Colors.white, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 18),
        const Text('Próximo horário livre:', style: TextStyle(color: Color(0xFFFFD9CB))),
        const SizedBox(height: 3),
        const Text('Hoje, 14:30',
            style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
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

  // Parte 3: os dias são criados pela lista "dias".
  Widget _calendario() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Outubro 2024',
            style: TextStyle(fontSize: 20, color: corTexto, fontWeight: FontWeight.bold))),
        TextButton(onPressed: () {}, child: const Text('Ver calendário')),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dias.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final dia = dias[index];
            final selecionado = diaSelecionado == index;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => diaSelecionado = index),
              child: Container(
                width: 64,
                decoration: BoxDecoration(
                  color: selecionado ? corPrincipal : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selecionado ? corPrincipal : const Color(0xFFF0D9D1)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(dia.$1, style: TextStyle(fontSize: 12, color: selecionado ? Colors.white : Colors.black54)),
                  Text(dia.$2, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: selecionado ? Colors.white : corTexto)),
                  Text(dia.$3, style: TextStyle(fontSize: 10, color: selecionado ? Colors.white : corPrincipal)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // Parte 4: cada botão altera somente "horarioSelecionado".
  Widget _horarios() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Horários livres para Sexta, 16 de Outubro',
          style: TextStyle(fontSize: 17, color: corTexto, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('●  7 horários livres', style: TextStyle(color: corPrincipal)),
      const SizedBox(height: 20),
      const Text('Manhã', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
      const SizedBox(height: 10),
      _listaDeHorarios(horarios.take(2).toList()),
      const SizedBox(height: 20),
      const Text('Tarde', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
      const SizedBox(height: 10),
      _listaDeHorarios(horarios.skip(2).take(3).toList()),
      const SizedBox(height: 20),
      const Text('Noite', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
      const SizedBox(height: 10),
      _listaDeHorarios(horarios.skip(5).toList()),
    ]);
  }

  Widget _listaDeHorarios(List<String> lista) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: lista.map((horario) {
        final selecionado = horarioSelecionado == horario;
        return ChoiceChip(
          label: Text(horario),
          selected: selecionado,
          showCheckmark: false,
          selectedColor: const Color(0xFFFFD9CB),
          side: BorderSide(color: selecionado ? corPrincipal : const Color(0xFFF0D9D1)),
          onSelected: (_) => setState(() => horarioSelecionado = horario),
        );
      }).toList(),
    );
  }

  Widget _botaoContinuar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 10)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Selecionado: Sex 16 · $horarioSelecionado', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 9),
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

class _Etapa extends StatelessWidget {
  final String numero;
  final String texto;
  final bool ativa;
  const _Etapa({required this.numero, required this.texto, this.ativa = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(
        radius: 13,
        backgroundColor: ativa ? const Color(0xFFB85D43) : const Color(0xFFF0D9D1),
        child: Text(numero, style: TextStyle(fontSize: 12, color: ativa ? Colors.white : const Color(0xFF7A2F18))),
      ),
      const SizedBox(height: 3),
      Text(texto, style: TextStyle(fontSize: 10, color: ativa ? const Color(0xFFB85D43) : Colors.black54)),
    ]);
  }
}

class _Linha extends StatelessWidget {
  const _Linha();
  @override
  Widget build(BuildContext context) => const Expanded(child: Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Divider(color: Color(0xFFF0D9D1)),
  ));
}
