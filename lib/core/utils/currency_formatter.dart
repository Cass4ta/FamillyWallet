import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return format.format(amount);
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  static String mesAnioKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
}
