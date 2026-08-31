class ApiConstants {
  static const String baseUrl = 'http://192.168.0.6:3001/api';

  static const String usuarios = '$baseUrl/usuarios';
  static const String auth = '$baseUrl/auth';
  static const String ordenes = '$baseUrl/ordenes';
  static const String comprobantes = '$baseUrl/comprobantes';
  static const String materiales = '$baseUrl/materiales';
  static const String eficiencia = '$baseUrl/eficiencia';

  // ============================================================
  // GOOGLE AUTH (móvil)
  // ============================================================
  // La web usa un flujo de redirect (getGoogleAuthUrl + callback).
  // En móvil no hay navegador/redirect: el SDK nativo de Google
  // Sign-In entrega un idToken (+ opcionalmente un serverAuthCode)
  // que el backend valida contra Google y responde EXACTAMENTE con
  // el mismo formato que POST /api/auth/login: { token, usuario }.
  //
  // ⚠️ Verifica este path contra tu backend real. Si tu Express ya
  // expone otro nombre para el login de Google (por ejemplo
  // "/auth/google/token" o "/auth/google/verify"), solo cambia esta
  // línea — el resto de la app no depende del nombre exacto.
  static const String googleMobileLogin = '$auth/google/mobile';

  // Web Client ID de Google OAuth. Se pasa al ejecutar/compilar:
  // flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxx.apps.googleusercontent.com
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  // ============================================================
  // GOOGLE CALENDAR
  // ============================================================
  static const String calendarBase = '$baseUrl/calendar';
  static const String calendarStatus = '$calendarBase/status';
  static const String calendarConnect = '$calendarBase/connect';
  static const String calendarSync = '$calendarBase/sync';

  // Debe coincidir exactamente con API_KEY_EFICIENCIA del backend (.env).
  static const String apiKeyEficiencia = 'texticode-2026';

  static const Map<String, String> eficienciaHeaders = {
    'x-api-key': apiKeyEficiencia,
  };
}
