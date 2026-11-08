/// Dados que a cliente digitou em "Seus dados", guardados só em memória
/// enquanto ela navega entre as etapas do agendamento (por exemplo, ao
/// tocar em "Editar" o serviço na revisão).
///
/// Some quando o app fecha e é limpo assim que o agendamento é confirmado.
class RascunhoCliente {
  const RascunhoCliente({
    required this.nome,
    required this.telefone,
    required this.email,
    required this.autorizouDados,
    required this.autorizouEmail,
  });

  final String nome;

  /// Já no formato exibido no campo, ex.: (44) 99999-9999.
  final String telefone;
  final String email;
  final bool autorizouDados;
  final bool autorizouEmail;

  static RascunhoCliente? atual;

  static void limpar() => atual = null;
}