import 'package:flutter/material.dart';

/// Abre o diálogo de confirmação de cancelamento.
/// Devolve true só se a cliente confirmar o cancelamento.
Future<bool> confirmarCancelamento(
  BuildContext context, {
  required String servico,
  required String periodo,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (_) => _DialogCancelar(servico: servico, periodo: periodo),
  );

  return resultado == true;
}

class _DialogCancelar extends StatelessWidget {
  const _DialogCancelar({
    required this.servico,
    required this.periodo,
  });

  static const _corPrincipal = Color(0xFF8E2348);
  static const _corFundo = Color(0xFFFFF8FA);
  static const _corTexto = Color(0xFF4A1026);
  static const _corSuave = Color(0xFF976D7B);
  static const _corBorda = Color(0xFFF1DDE5);
  static const _corPerigo = Color(0xFFB3261E);
  static const _corPerigoFundo = Color(0xFFFDE7E9);

  final String servico;
  final String periodo;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: _corPerigoFundo,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                size: 28,
                color: _corPerigo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancelar horário?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _corTexto,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'O horário ficará livre para outras clientes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.35, color: _corSuave),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _corFundo,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _corBorda),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.spa_outlined,
                        size: 16,
                        color: _corPrincipal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          servico,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _corTexto,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: _corPrincipal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          periodo,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _corTexto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, false),
                style: FilledButton.styleFrom(
                  backgroundColor: _corPrincipal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Manter horário',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _corPerigo,
                  side: const BorderSide(color: _corPerigo),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Cancelar horário',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}