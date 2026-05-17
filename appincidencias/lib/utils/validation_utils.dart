class ValidationUtils {
  /// Valida un DNI o NIE español (Regex + Cálculo de letra matemática)
  static bool validarDNI(String dni) {
    dni = dni.toUpperCase().trim();

    // 1. Validar formato con Regex:
    // Comienza por un número o X, Y, Z, seguido de 7 números y termina en una letra A-Z
    if (!RegExp(r'^[XYZ0-9][0-9]{7}[A-Z]$').hasMatch(dni)) {
      return false;
    }

    // 2. Cálculo matemático de la letra
    String numeroStr = dni.substring(0, 8);
    String letraProporcionada = dni.substring(8);

    // Mapeo para NIE: X=0, Y=1, Z=2
    numeroStr = numeroStr
        .replaceAll('X', '0')
        .replaceAll('Y', '1')
        .replaceAll('Z', '2');

    try {
      int numero = int.parse(numeroStr);
      const String tablaLetras = "TRWAGMYFPDXBNJZSQVHLCKE";
      String letraCorrecta = tablaLetras[numero % 23];

      return letraCorrecta == letraProporcionada;
    } catch (e) {
      return false;
    }
  }

  /// Valida un número de teléfono español (9 dígitos empezando por 6, 7, 8 o 9)
  static bool validarTelefono(String telefono) {
    return RegExp(r'^[6789][0-9]{8}$').hasMatch(telefono.trim());
  }
}
