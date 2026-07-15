class Validators {
  static String? cedulaEcuatoriana(String? value) {
    if (value == null || value.isEmpty) return 'La cédula es requerida';
    final cedula = value.replaceAll(RegExp(r'[.\-]'), '');
    if (cedula.length != 10) return 'La cédula debe tener 10 dígitos';
    final provincia = int.tryParse(cedula.substring(0, 2));
    if (provincia == null || provincia < 1 || provincia > 24) {
      return 'Cédula inválida';
    }
    int suma = 0;
    for (int i = 0; i < 9; i++) {
      int digito = int.parse(cedula[i]);
      if (i % 2 == 0) {
        digito *= 2;
        if (digito > 9) digito -= 9;
      }
      suma += digito;
    }
    final verificador = (10 - (suma % 10)) % 10;
    if (verificador != int.parse(cedula[9])) return 'Cédula inválida';
    return null;
  }

  static String? correo(String? value) {
    if (value == null || value.isEmpty) return 'El correo es requerido';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Correo inválido';
    }
    return null;
  }

  static String? contrasena(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Debe contener un número';
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Debe contener un carácter especial';
    }
    return null;
  }

  static String? requerido(String? value, String campo) {
    if (value == null || value.isEmpty) return '$campo es requerido';
    return null;
  }

  static String? manzana(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa la manzana';
    if (value.trim().length > 4) return 'Máximo 4 caracteres';
    return null;
  }

  static String? villa(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa la villa';
    if (value.trim().length > 2) return 'Máximo 2 caracteres';
    return null;
  }

  static String? usuario(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El usuario es requerido';
    }
    final v = value.trim();
    if (v.length < 6 || v.length > 12) {
      return 'El usuario debe tener entre 6 y 12 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z]').hasMatch(v)) {
      return 'Debe comenzar con una letra';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
      return 'Solo se permiten letras, números y guión bajo';
    }
    if (!v.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!v.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    return null;
  }
}
