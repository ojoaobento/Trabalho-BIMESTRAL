/// Utilitário de Feriados para o App Flutter.
/// Sincronizado com os feriados calculados pelo pacote `holidays` (Brasil/Paraná).
class FeriadosUtils {
  /// Calcula o Domingo de Páscoa (algoritmo de Butcher/Meeus).
  static DateTime calcularPascoa(int ano) {
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(ano, mes, dia);
  }

  /// Retorna o mapa de feriados oficiais e facultativos do ano.
  static Map<DateTime, String> obterFeriados(int ano) {
    final pascoa = calcularPascoa(ano);
    final carnaval = pascoa.subtract(const Duration(days: 47));
    final quartaCinzas = pascoa.subtract(const Duration(days: 46));
    final sextaSanta = pascoa.subtract(const Duration(days: 2));
    final corpusChristi = pascoa.add(const Duration(days: 60));

    DateTime d(int mes, int dia) => DateTime(ano, mes, dia);

    return {
      d(1, 1): 'Confraternização Universal',
      carnaval: 'Carnaval',
      quartaCinzas: 'Quarta-feira de Cinzas',
      sextaSanta: 'Sexta-feira Santa',
      pascoa: 'Páscoa',
      d(4, 21): 'Tiradentes',
      d(5, 1): 'Dia do Trabalhador',
      corpusChristi: 'Corpus Christi',
      d(9, 7): 'Independência do Brasil',
      d(10, 12): 'Nossa Senhora Aparecida',
      d(10, 28): 'Dia do Servidor Público',
      d(11, 2): 'Finados',
      d(11, 15): 'Proclamação da República',
      d(11, 20): 'Dia Nacional de Zumbi e da Consciência Negra',
      d(12, 24): 'Véspera de Natal',
      d(12, 25): 'Natal',
      d(12, 31): 'Véspera de Ano-Novo',
    };
  }

  /// Retorna se a data fornecida é feriado ou ponto facultativo.
  static bool ehFeriado(DateTime data) {
    final dia = DateTime(data.year, data.month, data.day);
    final feriados = obterFeriados(data.year);
    return feriados.keys.any((f) =>
        f.year == dia.year && f.month == dia.month && f.day == dia.day);
  }

  /// Retorna a descrição do feriado ou null.
  static String? nomeFeriado(DateTime data) {
    final dia = DateTime(data.year, data.month, data.day);
    final feriados = obterFeriados(data.year);
    for (final entry in feriados.entries) {
      if (entry.key.year == dia.year &&
          entry.key.month == dia.month &&
          entry.key.day == dia.day) {
        return entry.value;
      }
    }
    return null;
  }
}

