import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final numbersOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbersOnly.isEmpty) return newValue.copyWith(text: '');

    final number = int.parse(numbersOnly);
    final formatter = NumberFormat('#,###', 'es_ES');
    final newText = formatter.format(number).replaceAll(',', '.'); // Asegurar puntos

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
