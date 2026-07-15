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

/// Para nombre de usuario: bloquea espacios y símbolos.
/// Permite letras, números y guión bajo. Máximo 12 caracteres.
class UsuarioFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Solo letras, números y guión bajo
    final filtrado = newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (filtrado.length > 12) {
      return oldValue;
    }
    return TextEditingValue(
      text: filtrado,
      selection: TextSelection.collapsed(offset: filtrado.length),
    );
  }
}
