import 'package:flutter/material.dart';
import 'package:main/data/agendamento_repository.dart';
import 'package:main/data/api_service.dart';
import 'package:main/data/sessao_cliente.dart';

enum _Estado { carregando, semSessao, pronto, erro }

/// Folha aberta pelo menu ("Notificações") para ligar ou desligar os
/// lembretes por e-mail.
///
/// Só funciona com a cliente "logada" (sessão guardada no aparelho). Sem
/// sessão, mostra um convite para entrar em "Meus agendamentos" — [onEntrar]
/// fica por conta de quem abriu a folha (fechar e navegar).
class LembretesSheet extends StatefulWidget {
  const LembretesSheet({super.key, required this.onEntrar});

  final VoidCallback onEntrar;

  @override
  State<LembretesSheet> createState() => _LembretesSheetState();
}

class _LembretesSheetState extends State<LembretesSheet> {
  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);

  final _repositorio = AgendamentoRepository();

  _Estado _estado = _Estado.carregando;
  String? _token;
  String? _email;
  bool _aceitaLembretes = false;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Lê a sessão do aparelho e pergunta ao servidor o estado atual.
  Future<void> _carregar() async {
    setState(() {
      _estado = _Estado.carregando;
      _erro = null;
    });

    final sessao = await SessaoCliente.carregar();

    if (!mounted) return;

    if (sessao == null) {
      setState(() => _estado = _Estado.semSessao);
      return;
    }

    try {
      final acesso =
          await _repositorio.meusAgendamentosComToken(sessao.token);

      if (!mounted) return;

      setState(() {
        _token = acesso.token;
        _email = sessao.email;
        // Opt-in: se o servidor não informar, considera desligado.
        _aceitaLembretes = acesso.aceitaLembretes ?? false;
        _estado = _Estado.pronto;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 403) {
        // Sessão vencida: apaga e pede para entrar de novo.
        await SessaoCliente.limpar();

        if (!mounted) return;

        setState(() => _estado = _Estado.semSessao);
      } else {
        setState(() {
          _erro = e.mensagem;
          _estado = _Estado.erro;
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao carregar lembretes: $e');

      setState(() {
        _erro = 'Não foi possível carregar agora.';
        _estado = _Estado.erro;
      });
    }
  }

  /// Muda na hora e desfaz se o servidor recusar.
  Future<void> _alterar(bool novo) async {
    final token = _token;

    if (token == null || _salvando) return;

    final anterior = _aceitaLembretes;

    setState(() {
      _aceitaLembretes = novo;
      _salvando = true;
      _erro = null;
    });

    try {
      final gravado = await _repositorio.atualizarLembretes(
        token: token,
        aceitaLembretes: novo,
      );

      if (!mounted) return;

      setState(() {
        _aceitaLembretes = gravado;
        _salvando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 403) {
        await SessaoCliente.limpar();

        if (!mounted) return;

        setState(() {
          _salvando = false;
          _estado = _Estado.semSessao;
        });
      } else {
        setState(() {
          _aceitaLembretes = anterior;
          _salvando = false;
          _erro = e.mensagem;
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao atualizar lembretes: $e');

      setState(() {
        _aceitaLembretes = anterior;
        _salvando = false;
        _erro = 'Não foi possível atualizar agora.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOTIFICAÇÕES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: _corPrincipal,
              ),
            ),
            const SizedBox(height: 16),
            switch (_estado) {
              _Estado.carregando => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: _corPrincipal),
                  ),
                ),
              _Estado.semSessao => _semSessao(),
              _Estado.erro => _comErro(),
              _Estado.pronto => _pronto(),
            },
          ],
        ),
      ),
    );
  }

  Widget _pronto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _corFundo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _corBorda),
          ),
          child: Row(
            children: [
              Icon(
                _aceitaLembretes
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                size: 22,
                color: _corPrincipal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lembretes por e-mail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _corTexto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _aceitaLembretes
                          ? 'Avisamos 24h antes do seu horário.'
                          : 'Desativados. Você não receberá lembretes.',
                      style: const TextStyle(fontSize: 12, color: _corSuave),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_salvando)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _corPrincipal,
                    ),
                  ),
                )
              else
                Switch(
                  value: _aceitaLembretes,
                  onChanged: _alterar,
                  thumbColor: WidgetStateProperty.all(Colors.white),
                  trackColor: WidgetStateProperty.resolveWith(
                    (estados) => estados.contains(WidgetState.selected)
                        ? _corPrincipal
                        : _corBorda,
                  ),
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                ),
            ],
          ),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 10),
          Text(
            _erro!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
          ),
        ],
        if ((_email ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Conta: $_email',
            style: const TextStyle(fontSize: 11, color: _corSuave),
          ),
        ],
      ],
    );
  }

  Widget _semSessao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 20, color: _corPrincipal),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Para ligar ou desligar os lembretes, entre na sua conta '
                'em Meus agendamentos. É rápido: enviamos um código para o '
                'seu e-mail.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: _corTexto,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onEntrar,
            style: FilledButton.styleFrom(
              backgroundColor: _corPrincipal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.event_note_outlined, size: 18),
            label: const Text(
              'Entrar em Meus agendamentos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _comErro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _erro ?? 'Não foi possível carregar agora.',
          style: const TextStyle(fontSize: 13, color: _corTexto),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _carregar,
          style: TextButton.styleFrom(
            foregroundColor: _corPrincipal,
            padding: EdgeInsets.zero,
          ),
          child: const Text('Tentar de novo'),
        ),
      ],
    );
  }
}