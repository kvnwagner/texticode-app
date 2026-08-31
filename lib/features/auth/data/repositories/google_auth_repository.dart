import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/auth_user_model.dart';
import 'auth_repository.dart';

/// Inicio de sesión con Google, equivalente al flujo que ya usa la
/// versión web (getGoogleAuthUrl + callback), pero adaptado a móvil:
/// aquí no hay redirect de navegador, se usa el SDK nativo de Google
/// Sign-In.
///
/// Flujo:
///   1) El SDK muestra el selector de cuentas de Google y pide permiso
///      de email + Google Calendar en un solo consentimiento.
///   2) Se obtiene el idToken (identidad) y el serverAuthCode (permiso
///      de Calendar, de un solo uso, para que el BACKEND lo cambie por
///      un refresh_token — nunca se maneja el refresh_token en el
///      cel).
///   3) Se envían ambos al backend, que:
///        a) Verifica el idToken contra Google.
///        b) Busca/crea el usuario en la tabla `usuario` con el MISMO
///           criterio de rol que usa la web (mismo correo => mismo
///           Id_Rol / Rol).
///        c) Devuelve { token, usuario } con el MISMO formato que
///           POST /api/auth/login — por eso el resto de la app
///           (AuthUser.role, AppRouter, AuthRepository) no necesita
///           saber si el login fue con contraseña o con Google.
///        d) Intercambia el serverAuthCode por un refresh_token y lo
///           guarda del lado del servidor para poder crear eventos en
///           el Google Calendar del usuario (ver CalendarRepository).
class GoogleAuthRepository {
  final AuthRepository _authRepo;

  /// "Web client ID" (tipo OAuth "Web application") creado en Google
  /// Cloud Console para este proyecto — debe ser el MISMO client ID
  /// que el backend usa para verificar el idToken/serverAuthCode.
  /// Es DISTINTO del Client ID de Android/iOS que va en
  /// google-services.json / GoogleService-Info.plist.
  final String serverClientId;

  GoogleAuthRepository({
    this.serverClientId = ApiConstants.googleWebClientId,
    AuthRepository? authRepo,
  }) : _authRepo = authRepo ?? AuthRepository();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      // Permiso para crear/editar eventos en el calendario del
      // usuario — necesario para "vincular todas las ordenes con
      // Google Calendar".
      'https://www.googleapis.com/auth/calendar.events',
    ],
    serverClientId: serverClientId,
  );

  /// Lanza el selector de cuentas de Google y autentica contra el
  /// backend. Devuelve el AuthUser ya logueado (mismo objeto que
  /// AuthRepository.login) y deja la sesión guardada en almacenamiento
  /// seguro, lista para usar en el resto de la app.
  ///
  /// El [serverAuthCode] resultante también queda disponible en
  /// `account.serverAuthCode` por si quieres invocar
  /// CalendarRepository.connect() explícitamente más adelante (por
  /// ejemplo, si el usuario decide vincular Calendar después, no en el
  /// momento del login). El backend, si está bien implementado, ya
  /// hace esa conexión en el mismo POST de login — ver README.
  Future<AuthUser> signIn() async {
    _ensureConfigured();
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Inicio de sesión con Google cancelado.');
    }

    final googleAuth = await account.authentication;
    final serverAuthCode = account.serverAuthCode;

    if (googleAuth.idToken == null) {
      throw Exception('No se pudo obtener el token de Google.');
    }

    final res = await http.post(
      Uri.parse(ApiConstants.googleMobileLogin),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
        'serverAuthCode': serverAuthCode,
      }),
    );

    final body = _tryDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(
          body?['error'] ?? 'No se pudo iniciar sesión con Google.');
    }

    final token = body!['token'] as String;
    final usuarioJson = body['usuario'] as Map<String, dynamic>;
    final usuario = AuthUser.fromJson(usuarioJson);

    await _authRepo.guardarSesion(token: token, usuarioJson: usuarioJson);

    return usuario;
  }

  /// Pide a Google un serverAuthCode para vincular Calendar al usuario
  /// que ya inició sesión en Texticode con contraseña/JWT.
  Future<String> requestCalendarServerAuthCode() async {
    _ensureConfigured();
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Vinculación con Google cancelada.');
    }

    final serverAuthCode = account.serverAuthCode;
    if (serverAuthCode == null || serverAuthCode.isEmpty) {
      throw Exception(
        'Google no entregó el código de Calendar. Revisa el Web Client ID, '
        'el SHA-1/SHA-256 de Android y que el scope de Calendar esté aprobado.',
      );
    }
    return serverAuthCode;
  }

  /// Cierra la sesión del SDK nativo de Google (además de
  /// AuthRepository.logout(), que borra el token/JWT de la app).
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Silencioso: si no había sesión de Google activa no es un error.
    }
  }

  void _ensureConfigured() {
    if (serverClientId.trim().isEmpty) {
      throw Exception(
        'Falta configurar GOOGLE_WEB_CLIENT_ID. Ejecuta la app con '
        '--dart-define=GOOGLE_WEB_CLIENT_ID=tu-web-client-id.apps.googleusercontent.com',
      );
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
