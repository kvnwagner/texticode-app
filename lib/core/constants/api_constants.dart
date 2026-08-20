class ApiConstants {
  // IP local de tu PC + puerto donde está corriendo el backend.
  // Esta configuración es para probar la aplicación en un celular físico.
  static const String baseUrl = 'http://192.168.10.30:3001/api';

  static const String usuarios = '$baseUrl/usuarios';
  static const String auth = '$baseUrl/auth';
  static const String ordenes = '$baseUrl/ordenes';
  static const String comprobantes = '$baseUrl/comprobantes';
}