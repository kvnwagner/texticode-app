import '../../domain/models/user_role.dart';

/// Usuario autenticado, tal como lo devuelve POST /api/auth/login
/// dentro de la clave "usuario". Es independiente del modelo Usuario
/// que usa el panel admin para listar usuarios (ese trae más campos
/// como teléfono; este solo trae lo que el login realmente devuelve).
class AuthUser {
  final int idUsuario;
  final String nombreCompleto;
  final String nombreUsuario;
  final String correo;
  final int idRol;
  final String rol;
  final String estado;

  AuthUser({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.nombreUsuario,
    required this.correo,
    required this.idRol,
    required this.rol,
    required this.estado,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      idUsuario: json['Id_Usuario'] as int,
      nombreCompleto: json['Nombre_Completo'] as String? ?? '',
      nombreUsuario: json['Nombre_Usuario'] as String? ?? '',
      correo: json['Correo'] as String? ?? '',
      idRol: json['Id_Rol'] as int,
      rol: json['Rol'] as String? ?? '',
      estado: json['Estado'] as String? ?? '',
    );
  }

  /// Traduce Id_Rol / Rol (tal como vienen del backend) al enum
  /// UserRole que ya usa toda la navegación de la app.
  /// 1 = Administrador, 2 = Operario, 3 = Cliente (mismo criterio
  /// que getRuta() en LoginView.vue).
  UserRole get role {
    final rolLower = rol.toLowerCase();
    if (idRol == 1 || rolLower.contains('admin')) return UserRole.admin;
    if (idRol == 2 || rolLower.contains('operario')) return UserRole.operario;
    return UserRole.cliente;
  }
}