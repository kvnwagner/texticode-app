/// Mapea las columnas que devuelve tu backend en GET /api/comprobantes
/// (comprobantes.js), que hace JOIN con `usuario` (dos veces) y
/// `orden_produccion`:
///   Id_Comprobante, Id_Usuario, Id_Orden, Estado, Fecha_Limite,
///   Usuario (Nombre_Completo de Id_Usuario — NO es el cliente, ver
///   nota abajo), Orden_Descripcion, Orden_Estado, Id_Cliente,
///   Cliente (Nombre_Completo real del cliente, vía Id_Cliente)
///
/// ⚠️ IMPORTANTE: `Id_Usuario`/`Usuario` en esta tabla NO representan
/// al cliente del pedido — son quien registró/gestiona el comprobante.
/// El nombre real del cliente es `Cliente` (agregado en el backend con
/// un segundo JOIN a `usuario` a través de `Id_Cliente`). Antes de este
/// fix, la UI mostraba `Usuario` como si fuera el cliente, causando que
/// el comprobante de un cliente mostrara el nombre de otra persona.
class Comprobante {
  final int idComprobante;
  final int idUsuario;
  final int idOrden;
  final String estado;
  final String? fechaLimite;
  final String usuario;
  final String? ordenDescripcion;

  /// Nombre del producto/servicio de la orden (columna `Producto` de
  /// `orden_produccion`), distinto de [ordenDescripcion]. Úsalo como
  /// título del ítem; la descripción va debajo, igual que en la web.
  final String? ordenProducto;
  final String? ordenEstado;
  final int? idCliente;

  /// Nombre real del cliente del pedido. Úsalo en la UI en vez de
  /// [usuario] para mostrar a quién pertenece el comprobante.
  final String cliente;

  Comprobante({
    required this.idComprobante,
    required this.idUsuario,
    required this.idOrden,
    required this.estado,
    this.fechaLimite,
    required this.usuario,
    this.ordenDescripcion,
    this.ordenProducto,
    this.ordenEstado,
    this.idCliente,
    required this.cliente,
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
      ordenProducto: json['Orden_Producto'],
      ordenEstado: json['Orden_Estado'],
      idCliente: json['Id_Cliente'] == null
          ? null
          : (json['Id_Cliente'] is int
          ? json['Id_Cliente']
          : int.tryParse('${json['Id_Cliente']}')),
      // Si el backend todavía no tiene el fix (respuesta vieja sin
      // "Cliente"), cae de vuelta a "Usuario" para no romper la UI,
      // aunque en ese caso el nombre seguirá siendo el incorrecto.
      cliente: json['Cliente'] ?? json['Usuario'] ?? '',
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