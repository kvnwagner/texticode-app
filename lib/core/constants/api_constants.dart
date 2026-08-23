class ApiConstants {
  static const String baseUrl = 'http://192.168.1.9:3001/api';

  static const String usuarios = '$baseUrl/usuarios';
  static const String auth = '$baseUrl/auth';
  static const String ordenes = '$baseUrl/ordenes';
  static const String comprobantes = '$baseUrl/comprobantes';
  static const String materiales = '$baseUrl/materiales';
  static const String eficiencia = '$baseUrl/eficiencia';

  // Debe coincidir exactamente con API_KEY_EFICIENCIA del backend (.env).
  static const String apiKeyEficiencia = 'texticode-2026';

  static const Map<String, String> eficienciaHeaders = {
    'x-api-key': apiKeyEficiencia,
  };
}