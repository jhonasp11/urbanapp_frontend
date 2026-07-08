import 'package:flutter/services.dart';

/// Convierte a mayúsculas, permite solo letras y números,
/// y limita la longitud máxima.
class MayusculaAlfanumericoFormatter extends TextInputFormatter {
  final int maxLength;
  MayusculaAlfanumericoFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filtrado =
        newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (filtrado.length > maxLength) {
      return oldValue;
    }
    return TextEditingValue(
      text: filtrado,
      selection: TextSelection.collapsed(offset: filtrado.length),
    );
  }
}

/// Para placas: mayúsculas, letras/números/guión, máximo 8 caracteres.
class PlacaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filtrado =
        newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
    if (filtrado.length > 8) {
      return oldValue;
    }
    return TextEditingValue(
      text: filtrado,
      selection: TextSelection.collapsed(offset: filtrado.length),
    );
  }
}
