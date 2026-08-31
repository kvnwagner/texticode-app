import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auth_user_model.dart';

/// Autenticación real contra tu backend Express (auth.route.js), que
/// valida con bcrypt y devuelve un JWT firmado. Mismo patrón de
/// repository que OrdenRepository / MaterialRepository, pero además
/// guarda el token de sesión en almacenamiento seguro del dispositivo
/// (Keystore en Android / Keychain en iOS — no SharedPreferences plano,
/// porque es un token de autenticación).
class AuthRepository {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'texticode_token';
  static const _keyUsuarioJson = 'texticode_usuario';

  /// POST /api/auth/login — recibe correo (o nombre de usuario) y
  /// contraseña en texto plano; el backend hace el bcrypt.compare.
  /// Lanza Exception con el mensaje exacto que devuelve el backend
  /// ("Credenciales incorrectas.", "Tu cuenta está inactiva...", etc.)
  Future<AuthUser> login(String correoOUsuario, String contrasena) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.auth}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correoOUsuario.trim(),
        'contrasena': contrasena,
      }),
    );

    final body = _tryDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(body?['error'] ?? 'No se pudo iniciar sesión.');
    }

    final token = body!['token'] as String;
    final usuarioJson = body['usuario'] as Map<String, dynamic>;
    final usuario = AuthUser.fromJson(usuarioJson);

    await guardarSesion(token: token, usuarioJson: usuarioJson);

    return usuario;
  }

  /// Guarda token + usuario en almacenamiento seguro. Se usa desde
  /// login() normal Y desde GoogleAuthRepository.signIn(), así ambos
  /// métodos de login dejan la sesión exactamente en el mismo estado
  /// (mismo formato de "usuario guardado", mismo token Bearer para
  /// las demás llamadas autenticadas de la app).
  Future<void> guardarSesion({
    required String token,
    required Map<String, dynamic> usuarioJson,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUsuarioJson, value: jsonEncode(usuarioJson));
  }

  /// Recupera la sesión guardada (por ejemplo al abrir la app de nuevo),
  /// sin necesidad de volver a llamar al backend.
  Future<AuthUser?> getUsuarioGuardado() async {
    final raw = await _storage.read(key: _keyUsuarioJson);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<bool> get isLoggedIn async => (await getToken()) != null;

  /// Cierra sesión: borra el token y el usuario guardados.
  /// Nota: si el usuario inició sesión con Google, además hay que
  /// llamar a GoogleAuthRepository.signOutGoogle() para cerrar también
  /// la sesión del SDK nativo (ver ejemplo en el README).
  Future<void> logout() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUsuarioJson);
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}