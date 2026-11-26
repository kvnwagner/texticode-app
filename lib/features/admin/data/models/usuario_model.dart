/// Mapea exactamente las columnas que devuelve tu backend en
/// GET /api/usuarios y GET /api/usuarios/:id (usuarios.js):
///   Id_Usuario, Nombre_Completo, Nombre_Usuario, Correo, Telefono,
///   Estado, Fecha_Registro, Rol, Id_Rol
class Usuario {
  final int idUsuario;
  final String nombreCompleto;
  final String nombreUsuario;
  final String? correo;
  final String? telefono;
  final String estado;
  final String? fechaRegistro;
  final String rol;
  final int idRol;

  Usuario({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.nombreUsuario,
    this.correo,
    this.telefono,
    required this.estado,
    this.fechaRegistro,
    required this.rol,
    required this.idRol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['Id_Usuario'] is int
          ? json['Id_Usuario']
          : int.tryParse('${json['Id_Usuario']}') ?? 0,
      nombreCompleto: json['Nombre_Completo'] ?? '',
      nombreUsuario: json['Nombre_Usuario'] ?? '',
      correo: json['Correo'],
      telefono: json['Telefono'],
      estado: json['Estado'] ?? 'activo',
      fechaRegistro: json['Fecha_Registro'],
      rol: json['Rol'] ?? '',
      idRol: json['Id_Rol'] is int
          ? json['Id_Rol']
          : int.tryParse('${json['Id_Rol']}') ?? 0,
    );
  }

  /// Iniciales para el avatar circular (ej: "Andres Castro" -> "AC")
  String get initials {
    final parts = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  bool get isOperario => rol.toLowerCase().contains('operario');
  bool get isCliente => rol.toLowerCase().contains('cliente');
  bool get isAdmin => rol.toLowerCase().contains('admin');
  bool get isActivo => estado.toLowerCase() == 'activo';

  /// Formatea Fecha_Registro (ISO) a "d/m/yyyy" como en el prototipo web
  String get fechaCorta {
    if (fechaRegistro == null || fechaRegistro!.isEmpty) return '';
    try {
      final d = DateTime.parse(fechaRegistro!);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return fechaRegistro!;
    }
  }
}
