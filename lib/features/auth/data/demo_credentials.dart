import '../domain/models/user_role.dart';

/// Autenticación DEMO (sin backend todavía).
///
/// Cuando conectemos el login real contra la API de Node/Express + Supabase,
/// este archivo se reemplaza por un AuthRepository que llame al endpoint,
/// pero la interfaz pública (tryLogin) se puede mantener igual para no
/// tocar la UI.
class DemoCredentials {
  DemoCredentials._();

  static const Map<String, _DemoUser> _users = {
    'admin': _DemoUser(password: 'admin123', role: UserRole.admin),
    'operario': _DemoUser(password: 'operario123', role: UserRole.operario),
    'cliente': _DemoUser(password: 'cliente123', role: UserRole.cliente),
  };

  /// Retorna el [UserRole] si las credenciales son válidas, o `null`.
  static UserRole? tryLogin(String username, String password) {
    final user = _users[username.trim().toLowerCase()];
    if (user == null) return null;
    if (user.password != password) return null;
    return user.role;
  }
}

class _DemoUser {
  final String password;
  final UserRole role;
  const _DemoUser({required this.password, required this.role});
}
