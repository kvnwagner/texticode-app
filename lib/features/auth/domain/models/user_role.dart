/// Roles soportados por Texticode.
/// Coincide con los roles manejados en la versión web (admin / operario / cliente).
enum UserRole { admin, operario, cliente }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.operario:
        return 'Operario';
      case UserRole.cliente:
        return 'Cliente';
    }
  }
}
