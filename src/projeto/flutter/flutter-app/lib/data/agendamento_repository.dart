import 'package:main/data/api_service.dart';

import '../models/categoria.dart';
import '../models/servico.dart';
import '../models/horario_livre.dart';
import '../models/agendamento_criado.dart';

/// Resultado do acesso da cliente: token de sessão + lista de agendamentos.
class AcessoCliente {
  const AcessoCliente({
    required this.token,
    required this.agendamentos,
    this.nome,
    this.telefone,
    this.aceitaLembretes,
  });

  final String token;
  final String? nome;

  /// Telefone cadastrado da cliente (só dígitos). Necessário quando ela
  /// entra pelo "Esqueci meu telefone", já que o app não o conhecia.
  final String? telefone;

  /// Preferência de lembretes por e-mail. Nulo se o servidor não informar.
  final bool? aceitaLembretes;
  final List<AgendamentoCriado> agendamentos;
}

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
    required String email,
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

    final resposta = await _api.post('/agendamentos', {
      'cliente': {
        'nome': nome.trim(),
        'telefone': whatsApp.replaceAll(RegExp(r'\D'), ''),
        'email': email.trim(),
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

  /// Pede o envio do código de acesso por e-mail. A resposta é sempre a
  /// mesma, existindo ou não cadastro com esses dados.
  ///
  /// Sem [telefone] (cliente que esqueceu o telefone), o código vai para o
  /// e-mail informado se houver uma única cliente com ele.
  Future<void> solicitarCodigo({
    required String email,
    String? telefone,
  }) async {
    await _api.post('/agendamentos/acesso/codigo', {
      'email': email.trim(),
      if (_temTelefone(telefone)) 'telefone': _digitos(telefone!),
    });
  }

  /// Entra com e-mail + código (+ telefone, se a cliente lembrar dele).
  /// Devolve também o token de sessão.
  Future<AcessoCliente> meusAgendamentos({
    required String email,
    String? telefone,
    required String codigo,
  }) async {
    final dados = await _api.post('/agendamentos/minhas', {
      'email': email.trim(),
      if (_temTelefone(telefone)) 'telefone': _digitos(telefone!),
      'codigo': codigo.trim(),
    }) as Map<String, dynamic>;

    return _acesso(dados);
  }

  /// Entra com o token de sessão guardado no aparelho (sem pedir código).
  /// Lança [ApiException] com statusCode 403 se o token expirou.
  Future<AcessoCliente> meusAgendamentosComToken(String token) async {
    final dados = await _api.post('/agendamentos/minhas', {
      'token': token,
    }) as Map<String, dynamic>;

    return _acesso(dados);
  }

  /// Cancela um horário da cliente logada (identificada pelo token).
  /// Devolve o agendamento já atualizado.
  Future<AgendamentoCriado> cancelarMeuAgendamento({
    required String token,
    required int agendamentoId,
  }) async {
    final dados = await _api.post(
      '/agendamentos/minhas/$agendamentoId/cancelar',
      {'token': token},
    ) as Map<String, dynamic>;

    return AgendamentoCriado.fromJson(dados);
  }

  /// Troca o telefone da cliente logada. O token muda junto, então devolve
  /// o novo.
  Future<({String token, String telefone})> atualizarTelefone({
    required String token,
    required String telefone,
  }) async {
    final resp = await _api.patch('/agendamentos/minhas/telefone', {
      'token': token,
      'telefone': _digitos(telefone),
    }) as Map<String, dynamic>;

    return (
      token: resp['token'] as String,
      telefone: resp['telefone'] as String,
    );
  }

  /// Liga ou desliga os lembretes por e-mail da cliente logada.
  /// Devolve o valor realmente gravado pelo servidor.
  Future<bool> atualizarLembretes({
    required String token,
    required bool aceitaLembretes,
  }) async {
    final resp = await _api.patch('/agendamentos/minhas/lembretes', {
      'token': token,
      'aceita_lembretes': aceitaLembretes,
    }) as Map<String, dynamic>;

    return resp['aceita_lembretes'] as bool;
  }

  AcessoCliente _acesso(Map<String, dynamic> dados) {
    final lista = (dados['agendamentos'] as List)
        .map((e) => AgendamentoCriado.fromJson(e as Map<String, dynamic>))
        .toList();

    final cliente = dados['cliente'];

    return AcessoCliente(
      token: dados['token'] as String,
      nome: cliente is Map ? cliente['nome'] as String? : null,
      telefone: cliente is Map ? cliente['telefone'] as String? : null,
      aceitaLembretes:
          cliente is Map ? cliente['aceita_lembretes'] as bool? : null,
      agendamentos: lista,
    );
  }

  bool _temTelefone(String? telefone) =>
      telefone != null && _digitos(telefone).isNotEmpty;

  String _digitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

  String _dia(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }
}