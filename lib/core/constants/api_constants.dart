class ApiConstants {
  // Base URL de la API del backend. Puede sobreescribirse al compilar/ejecutar:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.61:3001/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.11:3001/api',
  );

  static const String usuarios = '$baseUrl/usuarios';
  static const String auth = '$baseUrl/auth';
  static const String ordenes = '$baseUrl/ordenes';
  static const String comprobantes = '$baseUrl/comprobantes';
  static const String materiales = '$baseUrl/materiales';
  static const String eficiencia = '$baseUrl/eficiencia';
  static const String cargaTrabajo = '$baseUrl/carga-trabajo';
  
  // Inventario reconstruido al final de un período ('YYYY-MM'), a
  // partir de la bitácora de movimientos (material_movimiento) del
  // backend. Ver GET /materiales/reportes/historial en materiales.js.
  static const String materialesHistorial = '$materiales/reportes/historial';

  // Rutas de práctica/consulta (usuarios.js "extra" — ordenes.js/:Id_Orden/materiales,
  // clientes/:Id_Cliente/materiales, etc.). Usada por MaterialRepository para
  // traer solo los materiales asignados a un cliente en concreto.
  static const String practica = '$baseUrl/practica';

  // Tabla intermedia orden_material: permite asociar varios materiales
  // a una misma orden (Id_Orden, Id_Producto, Cantidad_Usada).
  static const String ordenMaterial = '$baseUrl/orden-material';
  static const String ordenOperario = '$baseUrl/orden-operario';

  // Correos transaccionales vía SendGrid (routes/notificaciones.js):
  // cambios de estado al cliente, comprobante de entrega, y tarea
  // asignada al operario cuando se le agrega una fase nueva.
  static const String notificaciones = '$baseUrl/notificaciones';

  // ============================================================
  // GOOGLE AUTH (móvil)
  // ============================================================
  // La web usa un flujo de redirect (getGoogleAuthUrl + callback).
  // En móvil no hay navegador/redirect: el SDK nativo de Google
  // Sign-In entrega un idToken (+ opcionalmente un serverAuthCode)
  // que el backend valida contra Google y responde EXACTAMENTE con
  // el mismo formato que POST /api/auth/login: { token, usuario }.
  static const String googleMobileLogin = '$auth/google/mobile';

  // Web Client ID de Google OAuth. Puede pasarse por --dart-define o usar el valor por defecto:
  // flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '3072212776-4tak504hvbj221drivoa905fd86tsh20.apps.googleusercontent.com',
  );

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