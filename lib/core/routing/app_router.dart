import 'package:flutter/material.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/admin/presentation/screens/main_shell.dart'; // ⬅️ nuevo
import '../../features/operario/presentation/screens/operario_home_screen.dart';
import '../../features/cliente/presentation/screens/cliente_home_screen.dart';

/// Router muy simple basado en `onGenerateRoute`.
/// Cuando el equipo crezca en pantallas, esto se puede migrar a
/// go_router sin tocar la lógica de las screens.
class AppRouter {
  AppRouter._();

  static const String login = '/';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case home:
        final role = settings.arguments as UserRole?;
        return MaterialPageRoute(builder: (_) => _homeForRole(role));

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  static Widget _homeForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return const MainShell(); // ⬅️ antes: AdminHomeScreen()
      case UserRole.operario:
        return const OperarioHomeScreen();
      case UserRole.cliente:
        return const ClienteHomeScreen();
      case null:
        return const LoginScreen();
    }
  }
}