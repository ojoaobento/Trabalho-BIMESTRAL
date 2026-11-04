import 'package:main/data/api_service.dart';

import '../models/categoria.dart';
import '../models/servico.dart';
import '../models/horario_livre.dart';
import '../models/agendamento_criado.dart';

class AgendamentoRepository {
  final ApiClient _api = ApiClient.instancia;

  Future<List<Categoria>> categorias() async {
    final dados = await _api.get('/categorias') as List;

    return dados
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Servico>> servicosAtivos() async {
    final dados = await _api.get('/servicos/ativos') as List;

    return dados
        .map((e) => Servico.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HorarioLivre>> horariosLivres(DateTime data) async {
    final dados = await _api.get(
      '/agendamentos/horarios-livres',
      query: {
        'data': _dia(data),
      },
    ) as List;

    return dados
        .map((e) => HorarioLivre.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AgendamentoCriado> criar({
    required int servicoId,
    required DateTime data,
    required String hora,
    required String nome,
    required String whatsApp,
    required bool aceitaLembretes,
    required bool consentimento,
  }) async {
    final partes = hora.split(':');

    if (partes.length < 2) {
      throw FormatException('Horário inválido: $hora');
    }

    final horaInteira = int.tryParse(partes[0]);
    final minutoInteiro = int.tryParse(partes[1]);

    if (horaInteira == null ||
        minutoInteiro == null ||
        horaInteira < 0 ||
        horaInteira > 23 ||
        minutoInteiro < 0 ||
        minutoInteiro > 59) {
      throw FormatException('Horário inválido: $hora');
    }

    final telefone = whatsApp.replaceAll(
      RegExp(r'\D'),
      '',
    );

    // O backend espera "data" (AAAA-MM-DD) e "hora" (HH:MM) separados e
    // monta o horário no fuso America/Sao_Paulo.
    final resposta = await _api.post('/agendamentos', {
      'cliente': {
        'nome': nome.trim(),
        'telefone': telefone,
        'aceita_lembretes': aceitaLembretes,
        'consentimento': consentimento,
      },
      'servico_id': servicoId,
      'data': _dia(data),
      'hora': '${horaInteira.toString().padLeft(2, '0')}:'
          '${minutoInteiro.toString().padLeft(2, '0')}',
    });

    return AgendamentoCriado.fromJson(
      resposta as Map<String, dynamic>,
    );
  }

  String _dia(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }
}