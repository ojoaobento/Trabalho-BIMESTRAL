import 'package:flutter/material.dart';

/// Cores e peças reaproveitadas por todas as telas do painel.
class PainelCores {
  static const Color vinho = Color(0xFF8E2348);
  static const Color rosaClaro = Color(0xFFFFEEF3);
  static const Color borda = Color(0xFFF1DDE5);
  static const Color texto = Color(0xFF4A1026);
}

void mostrarMensagem(
  BuildContext context,
  String mensagem, {
  bool erro = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? Colors.red.shade700 : PainelCores.vinho,
    ),
  );
}

Future<bool> confirmarExclusao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return resultado ?? false;
}

InputDecoration decoracaoFormulario(String label, {String? prefixo}) {
  return InputDecoration(
    labelText: label,
    prefixText: prefixo,
    labelStyle: const TextStyle(color: PainelCores.vinho),
    floatingLabelStyle: const TextStyle(color: PainelCores.vinho),
    filled: true,
    fillColor: PainelCores.rosaClaro,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PainelCores.borda),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PainelCores.borda),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PainelCores.vinho, width: 1.5),
    ),
  );
}

/// Linha do topo da lista: resumo à esquerda e botão de criar à direita.
class CabecalhoLista extends StatelessWidget {
  final String resumo;
  final String rotuloBotao;
  final VoidCallback onPressed;

  const CabecalhoLista({
    super.key,
    required this.resumo,
    required this.rotuloBotao,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            resumo,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(rotuloBotao),
          style: ElevatedButton.styleFrom(
            backgroundColor: PainelCores.vinho,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class EstadoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const EstadoErro({
    super.key,
    required this.mensagem,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: PainelCores.vinho, size: 40),
          const SizedBox(height: 8),
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onTentarNovamente,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final bool ativo;

  const StatusChip({super.key, required this.ativo});

  @override
  Widget build(BuildContext context) {
    final Color cor = ativo ? Colors.green.shade700 : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}