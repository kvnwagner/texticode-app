class ApiConstants {
  // 10.0.2.2 apunta al localhost de TU PC cuando corres en el EMULADOR de Android.
  // Es lo que necesitas mientras pruebas contra "Servidor corriendo en http://localhost:3001".
  //
  // Si vas a probar en un CELULAR FÍSICO conectado por USB o WiFi:
  //   1. Averigua la IP local de tu PC (ipconfig en Windows, ifconfig en Mac/Linux).
  //   2. Cambia esta constante por, por ejemplo: 'http://192.168.1.15:3001/api'
  //   3. Asegúrate de que el celular y el PC estén en la MISMA red WiFi.
  static const String baseUrl = 'http://192.168.0.5:3001/api';

  static const String usuarios = '$baseUrl/usuarios';
  static const String auth = '$baseUrl/auth';
  static const String ordenes = '$baseUrl/ordenes'; // ⬅️ nuevo — Gestión de Producción
  static const String comprobantes = '$baseUrl/comprobantes';
}
