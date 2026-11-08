import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:main/services/api_client.dart';

class VisaoGeralPage extends StatefulWidget {
  const VisaoGeralPage({super.key});

  @override
  State<VisaoGeralPage> createState() => _VisaoGeralPageState();
}

class _VisaoGeralPageState extends State<VisaoGeralPage> {
  static const Color vinho = Color(0xFF8E2348);

  late Future<Map<String, dynamic>> _dadosVisaoGeralFuture;

  @override
  void initState() {
    super.initState();
    _dadosVisaoGeralFuture = _buscarDadosDaApi();
  }

  // --------------------------------------------------
  // BUSCAR DADOS DA API
  // --------------------------------------------------

  Future<Map<String, dynamic>> _buscarDadosDaApi() async {
    try {
      final resposta =
          await ApiClient.instancia.get('/dashboard/resumo');

      if (resposta is! Map) {
        throw Exception('Resposta inválida da API.');
      }

      return Map<String, dynamic>.from(resposta);
    } catch (e) {
      throw Exception(
        'Erro ao carregar dados da visão geral: $e',
      );
    }
  }

  // --------------------------------------------------
  // ATUALIZAR DADOS
  // --------------------------------------------------

  void _tentarNovamente() {
    setState(() {
      _dadosVisaoGeralFuture = _buscarDadosDaApi();
    });
  }

  int _obterInteiro(dynamic valor) {
    return valor is num ? valor.toInt() : 0;
  }

  double _obterDouble(dynamic valor) {
    return valor is num ? valor.toDouble() : 0.0;
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dadosVisaoGeralFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: vinho),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  'Não foi possível carregar os dados.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vinho,
                  ),
                  onPressed: _tentarNovamente,
                  child: const Text(
                    'Tentar novamente',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final dados = snapshot.data ?? <String, dynamic>{};

        // --------------------------------------------------
        // INDICADORES
        // --------------------------------------------------

        final agendamentosHoje =
            _obterInteiro(dados['agendamentos_hoje']);

        final faturamentoMes =
            _obterDouble(dados['faturamento_mes']);

        final totalClientes =
            _obterInteiro(dados['total_clientes']);

        final totalServicos =
            _obterInteiro(dados['total_servicos_ativos']);

        final pendentes =
            _obterInteiro(dados['agendamentos_pendentes']);

        final confirmados =
            _obterInteiro(dados['agendamentos_confirmados']);

        final concluidos =
            _obterInteiro(dados['agendamentos_concluidos']);

        final cancelados =
            _obterInteiro(dados['agendamentos_cancelados']);

        final faltas =
            _obterInteiro(dados['agendamentos_faltas']);

        // --------------------------------------------------
        // DESEMPENHO SEMANAL
        // --------------------------------------------------

        final desempenhoBruto =
            dados['desempenho_semanal'] as List<dynamic>? ??
                [0, 0, 0, 0, 0, 0, 0];

        final valoresSemana = List<double>.generate(
          7,
          (index) {
            if (index >= desempenhoBruto.length) {
              return 0;
            }

            return _obterDouble(desempenhoBruto[index]);
          },
        );

        final maiorValor = valoresSemana.reduce(
          (a, b) => a > b ? a : b,
        );

        final maxY = maiorValor > 0
            ? maiorValor * 1.2
            : 20.0;

        // --------------------------------------------------
        // DISTRIBUIÇÃO POR STATUS
        // --------------------------------------------------

        return RefreshIndicator(
          color: vinho,
          onRefresh: () async {
            _tentarNovamente();
            await _dadosVisaoGeralFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              
              // --------------------------------------------------
              // TÍTULO
              // --------------------------------------------------


              Text(
                'Acompanhe os indicadores do seu negócio.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // CARDS PRINCIPAIS
              // --------------------------------------------------

              LayoutBuilder(
                builder: (context, constraints) {
                  final largura =
                      (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: largura,
                        child: _buildCardResumo(
                          titulo: 'Agendamentos Hoje',
                          valor: '$agendamentosHoje',
                          icone: Icons.calendar_today,
                          cor: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: largura,
                        child: _buildCardResumo(
                          titulo: 'Faturamento do Mês',
                          valor:
                              'R\$ ${faturamentoMes.toStringAsFixed(2)}',
                          icone: Icons.attach_money,
                          cor: Colors.green,
                        ),
                      ),
                      SizedBox(
                        width: largura,
                        child: _buildCardResumo(
                          titulo: 'Clientes',
                          valor: '$totalClientes',
                          icone: Icons.people_alt_outlined,
                          cor: Colors.orange,
                        ),
                      ),
                      SizedBox(
                        width: largura,
                        child: _buildCardResumo(
                          titulo: 'Serviços Ativos',
                          valor: '$totalServicos',
                          icone: Icons.content_cut,
                          cor: Colors.purple,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // DESEMPENHO SEMANAL
              // --------------------------------------------------

              _buildTituloSecao(
                'Desempenho Semanal',
                'Quantidade de agendamentos por dia',
              ),

              const SizedBox(height: 12),

              Container(
                height: 280,
                padding: const EdgeInsets.fromLTRB(
                  12,
                  24,
                  16,
                  12,
                ),
                decoration: _decoracaoCard(),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => vinho,
                        getTooltipItem:
                            (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} agendamentos',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const dias = [
                              'Seg',
                              'Ter',
                              'Qua',
                              'Qui',
                              'Sex',
                              'Sáb',
                              'Dom',
                            ];

                            final index = value.toInt();

                            if (index < 0 || index >= dias.length) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dias[index],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.15),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _gerarBarrasDinamicas(
                      valoresSemana,
                      maxY,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // STATUS DOS AGENDAMENTOS
              // --------------------------------------------------

              _buildTituloSecao(
                'Agendamentos do Mês',
                'Distribuição por situação',
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: _decoracaoCard(),
                child: Column(
                  children: [
                    _buildIndicadorStatus(
                      titulo: 'Pendentes',
                      quantidade: pendentes,
                      cor: Colors.orange,
                      icone: Icons.hourglass_empty,
                    ),
                    const Divider(height: 24),
                    _buildIndicadorStatus(
                      titulo: 'Confirmados',
                      quantidade: confirmados,
                      cor: Colors.blue,
                      icone: Icons.check_circle_outline,
                    ),
                    const Divider(height: 24),
                    _buildIndicadorStatus(
                      titulo: 'Concluídos',
                      quantidade: concluidos,
                      cor: Colors.green,
                      icone: Icons.task_alt,
                    ),
                    const Divider(height: 24),
                    _buildIndicadorStatus(
                      titulo: 'Cancelados',
                      quantidade: cancelados,
                      cor: Colors.red,
                      icone: Icons.cancel_outlined,
                    ),
                    const Divider(height: 24),
                    _buildIndicadorStatus(
                      titulo: 'Faltas',
                      quantidade: faltas,
                      cor: Colors.grey,
                      icone: Icons.person_off_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // GRÁFICO
  // --------------------------------------------------

  List<BarChartGroupData> _gerarBarrasDinamicas(
    List<double> valores,
    double maxY,
  ) {
    return List.generate(valores.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: valores[index],
            color: vinho,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: const Color(0xFFFFEEF3),
            ),
          ),
        ],
      );
    });
  }

  // --------------------------------------------------
  // CARD DE RESUMO
  // --------------------------------------------------

  Widget _buildCardResumo({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoracaoCard(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cor.withValues(alpha: 0.15),
            child: Icon(
              icone,
              color: cor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A1026),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // INDICADOR DE STATUS
  // --------------------------------------------------

  Widget _buildIndicadorStatus({
    required String titulo,
    required int quantidade,
    required Color cor,
    required IconData icone,
  }) {
    return Row(
      children: [
        Icon(
          icone,
          color: cor,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          quantidade.toString(),
          style: TextStyle(
            color: cor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // TÍTULO DE SEÇÃO
  // --------------------------------------------------

  Widget _buildTituloSecao(
    String titulo,
    String subtitulo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A1026),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // DECORAÇÃO DOS CARDS
  // --------------------------------------------------

  BoxDecoration _decoracaoCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}