import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/cambiar_contrasena_screen.dart';
import '../../features/admin/presentation/screens/main_shell.dart';
import '../../features/operario/presentation/screens/operario_home_screen.dart';
import '../../features/cliente/presentation/screens/cliente_home_screen.dart';

/// Rutas nombradas de la app (usadas con go_router vía context.go / context.push).
class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String home = '/home';
  static const String cambiarContrasena = '/cambiar-contrasena';
}

/// Configuración central de navegación con go_router.
///
/// La ruta `/home` recibe el rol del usuario autenticado como `extra`
/// (state.extra), tal como antes se pasaba con `arguments` en el
/// Navigator clásico:
///   context.go(AppRoutes.home, extra: usuario.role);
///
/// La ruta `/cambiar-contrasena` recibe el token como query param
/// (?token=xxx), tal como llega desde el deep link
/// texticode://cambiar-contrasena?token=xxx.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          final role = state.extra as UserRole?;
          return _homeForRole(role);
        },
      ),
      GoRoute(
        path: AppRoutes.cambiarContrasena,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return CambiarContrasenaScreen(token: token);
        },
      ),
    ],
    // Si alguna vez se navega a una ruta que no existe, volvemos al login
    // en vez de mostrar la pantalla de error por defecto de go_router.
    errorBuilder: (context, state) => const LoginScreen(),
  );

  static Widget _homeForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return const MainShell();
      case UserRole.operario:
        return const OperarioHomeScreen();
      case UserRole.cliente:
        return const ClienteHomeScreen();
      case null:
        return const LoginScreen();
    }
  }
}