import 'package:flutter/material.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, required this.data, required this.horario});

  final DateTime data;
  final String horario;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corBorda = Color(0xFFF1DDE5);

  final _servicos = const [
    _Servico('Manicure / Pedicure', 'Combo Manicure +\nPedicure', 'Cuticulagem tradicional completa, esmaltação e hidratação nas mãos e pés.', 75, 80),
    _Servico('Manicure / Pedicure', 'Manicure Tradicional', 'Cuticulagem, lixamento técnico e esmaltação tradicional.', 38, 40),
    _Servico('Manicure / Pedicure', 'Pedicure Tradicional', 'Higienização, cuticulagem, esfoliação suave e esmaltação nos pés.', 42, 45),
    _Servico('Manicure / Pedicure', 'Spa dos Pés Tradicional', 'Imersão emoliente, esfoliação com sais minerais e hidratação profunda.', 60, 50),
    _Servico('Cabelo', 'Corte & Escova Modelada', 'Corte personalizado de acordo com o estilo e finalização com escova modelada.', 95, 60),
    _Servico('Cabelo', 'Hidratação Profunda & Escova', 'Tratamento de nutrição capilar intensiva seguido de escovação com brilho acetinado.', 130, 75),
    _Servico('Cabelo', 'Coloração / Tonalização', 'Aplicação de coloração ou tonalizante com proteção da fibra capilar.', 180, 120),
    _Servico('Cabelo', 'Escova & Finalização', 'Lavagem suave com massagem relaxante e escova modeladora.', 60, 45),
  ];

  String _filtro = 'Todos';
  _Servico? _servicoSelecionado;

  @override
  void initState() {
    super.initState();
    _servicoSelecionado = _servicos.first;
  }

  @override
  Widget build(BuildContext context) {
    final servicosFiltrados = _filtro == 'Todos'
        ? _servicos
        : _servicos.where((servico) => servico.categoria == _filtro).toList();

    return Scaffold(
      backgroundColor: _corFundo,
      body: SafeArea(
        child: Column(children: [
          _progresso(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
              children: [
                _horarioEscolhido(),
                const SizedBox(height: 16),
                const Text('Serviços disponíveis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _corTexto)),
                const SizedBox(height: 4),
                const Text('• Estes serviços cabem na sua janela livre de 2h30', style: TextStyle(fontSize: 11, color: _corPrincipal)),
                const SizedBox(height: 12),
                _filtros(),
                const SizedBox(height: 14),
                ...servicosFiltrados.map(_cardServico),
              ],
            ),
          ),
          _rodape(),
        ]),
      ),
    );
  }

  Widget _progresso() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1. Horário', style: TextStyle(fontSize: 10, color: _corPrincipal)),
          Text('2. Serviço', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _corPrincipal)),
          Text('3. Seus dados', style: TextStyle(fontSize: 10, color: Colors.black45)),
          Text('4. Confirmar', style: TextStyle(fontSize: 10, color: Colors.black45)),
        ]),
        const SizedBox(height: 7),
        Row(children: [
          const Expanded(child: Divider(color: _corPrincipal, thickness: 3)),
          Expanded(child: Container(height: 3, color: _corPrincipal)),
          const Expanded(child: Divider(color: _corBorda, thickness: 3)),
          const Expanded(child: Divider(color: _corBorda, thickness: 3)),
        ]),
      ]),
    );
  }

  Widget _horarioEscolhido() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _corBorda)),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.chevron_left), color: _corTexto),
        const Icon(Icons.schedule_outlined, size: 18, color: _corPrincipal),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Horário escolhido:', style: TextStyle(fontSize: 10, color: Colors.black54)),
          Text(_dataCurta(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _corTexto)),
        ])),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: _corPrincipal, backgroundColor: const Color(0xFFFFEEF3)),
          child: const Text('Alterar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _filtros() {
    const filtros = ['Todos', 'Cabelo', 'Manicure / Pedicure'];
    return Wrap(
      spacing: 8,
      children: filtros.map((filtro) {
        final quantidade = filtro == 'Todos' ? _servicos.length : _servicos.where((servico) => servico.categoria == filtro).length;
        return ChoiceChip(
          label: Text('$filtro ($quantidade)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          selected: _filtro == filtro,
          showCheckmark: false,
          selectedColor: _corPrincipal,
          backgroundColor: Colors.white,
          side: BorderSide(color: _filtro == filtro ? _corPrincipal : _corBorda),
          labelStyle: TextStyle(color: _filtro == filtro ? Colors.white : _corTexto),
          onSelected: (_) => setState(() => _filtro = filtro),
        );
      }).toList(),
    );
  }

  Widget _cardServico(_Servico servico) {
    final selecionado = _servicoSelecionado == servico;
    return InkWell(
      onTap: () => setState(() => _servicoSelecionado = servico),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selecionado ? _corPrincipal : _corBorda, width: selecionado ? 1.5 : 1),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(servico.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _corTexto)),
            const SizedBox(height: 3),
            Text(servico.descricao, style: const TextStyle(fontSize: 10, height: 1.15, color: Color(0xFF9A6C7C))),
            const SizedBox(height: 9),
            Row(children: [
              const Icon(Icons.schedule_outlined, size: 13, color: _corPrincipal),
              const SizedBox(width: 3),
              Text('${servico.duracao} min', style: const TextStyle(fontSize: 10, color: _corTexto)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 9), child: Text('•', style: TextStyle(color: _corPrincipal))),
              const Text('Cabe no horário', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16836D))),
            ]),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('R\$ ${servico.preco.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _corTexto)),
            const SizedBox(height: 16),
            Icon(selecionado ? Icons.check_circle : Icons.radio_button_unchecked, color: selecionado ? _corPrincipal : _corBorda, size: 20),
          ]),
        ]),
      ),
    );
  }

  Widget _rodape() {
    final servico = _servicoSelecionado;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(servico == null ? 'Nenhum serviço selecionado' : '1 serviço selecionado', style: const TextStyle(fontSize: 9, color: Colors.black45)),
          Text(servico == null ? 'Total: R\$ 0,00' : 'Total: R\$ ${servico.preco.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _corTexto)),
        ])),
        FilledButton.icon(
          onPressed: servico == null ? null : () {},
          style: FilledButton.styleFrom(backgroundColor: _corPrincipal, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13)),
          label: const Text('Continuar'),
          icon: const Icon(Icons.arrow_forward, size: 16),
          iconAlignment: IconAlignment.end,
        ),
      ]),
    );
  }

  String _dataCurta() {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const meses = ['jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.', 'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'];
    return '${dias[widget.data.weekday - 1]} ${widget.data.day} de ${meses[widget.data.month - 1]} às ${widget.horario}';
  }
}

class _Servico {
  const _Servico(this.categoria, this.nome, this.descricao, this.preco, this.duracao);

  final String categoria;
  final String nome;
  final String descricao;
  final double preco;
  final int duracao;
}
