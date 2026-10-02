import 'package:intl/intl.dart';

class PatasDateUtils {
  /// Formata uma data para exibição amigável (ex: "Hoje às 10:00", "há 2 dias", etc)
  static String formatFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Se a data for no futuro (devido a drift de relógio), tratar como agora
    if (difference.isNegative) return 'Agora mesmo';

    // Se for hoje
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      if (difference.inMinutes < 1) return 'Agora mesmo';
      if (difference.inMinutes < 60) return 'Há ${difference.inMinutes}min';
      if (difference.inHours < 6) return 'Há ${difference.inHours}h';

      return 'Hoje às ${DateFormat('HH:mm').format(date)}';
    }

    // Se for ontem
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Ontem às ${DateFormat('HH:mm').format(date)}';
    }

    // Se for nos últimos 7 dias
    if (difference.inDays < 7) {
      return 'Há ${difference.inDays} dias';
    }

    // Formato padrão para datas mais antigas
    return DateFormat("d 'de' MMM 'às' HH:mm", 'pt_BR').format(date);
  }

  /// Formato simples (dd/MM/yyyy HH:mm)
  static String formatFullDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(date);
  }
}
