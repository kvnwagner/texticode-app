/// Mapea las columnas que devuelve tu backend en GET /api/comprobantes
/// (comprobantes.js), que hace JOIN con `usuario` y `orden_produccion`:
///   Id_Comprobante, Id_Usuario, Id_Orden, Estado, Fecha_Limite,
///   Usuario (Nombre_Completo del cliente), Orden_Descripcion,
///   Orden_Estado, Id_Cliente
class Comprobante {
  final int idComprobante;
  final int idUsuario;
  final int idOrden;
  final String estado;
  final String? fechaLimite;
  final String usuario;
  final String? ordenDescripcion;
  final String? ordenEstado;
  final int? idCliente;

  Comprobante({
    required this.idComprobante,
    required this.idUsuario,
    required this.idOrden,
    required this.estado,
    this.fechaLimite,
    required this.usuario,
    this.ordenDescripcion,
    this.ordenEstado,
    this.idCliente,
  });

  factory Comprobante.fromJson(Map<String, dynamic> json) {
    return Comprobante(
      idComprobante: json['Id_Comprobante'] is int
          ? json['Id_Comprobante']
          : int.tryParse('${json['Id_Comprobante']}') ?? 0,
      idUsuario: json['Id_Usuario'] is int
          ? json['Id_Usuario']
          : int.tryParse('${json['Id_Usuario']}') ?? 0,
      idOrden: json['Id_Orden'] is int
          ? json['Id_Orden']
          : int.tryParse('${json['Id_Orden']}') ?? 0,
      estado: json['Estado'] ?? 'Pendiente',
      fechaLimite: json['Fecha_Limite'],
      usuario: json['Usuario'] ?? '',
      ordenDescripcion: json['Orden_Descripcion'],
      ordenEstado: json['Orden_Estado'],
      idCliente: json['Id_Cliente'] == null
          ? null
          : (json['Id_Cliente'] is int
          ? json['Id_Cliente']
          : int.tryParse('${json['Id_Cliente']}')),
    );
  }

  bool get isCompletado => estado.toLowerCase() == 'completado';

  /// Formatea Fecha_Limite (ISO) a "d/m/yyyy"
  String get fechaCorta {
    if (fechaLimite == null || fechaLimite!.isEmpty) return 'Sin fecha';
    try {
      final d = DateTime.parse(fechaLimite!);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return fechaLimite!;
    }
  }
}