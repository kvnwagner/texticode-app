/// Mapea exactamente las columnas que debería devolver tu backend en
/// GET /api/ordenes y GET /api/ordenes/:id (ordenes.js), siguiendo el
/// MISMO patrón de nombres que usuario_model.dart:
///   Id_Orden, Codigo_Orden, Producto, Descripcion, Materiales,
///   Cantidad_Total, Cantidad_Actual, Id_Cliente, Cliente, Id_Operario,
///   Operario, Prioridad, Estado, Fecha_Limite, Fecha_Creacion
///
/// ⚠️ AJUSTA estos nombres si tu tabla `orden_produccion` en Supabase
/// usa otros — es el mismo trabajo que se hizo con `usuario`.
///
/// ⚠️ NOTA sobre "0 de 0 prendas": si en tu app seguía saliendo 0/0,
/// es porque el backend está devolviendo la cantidad con OTRO nombre
/// de columna (por ejemplo "Cantidad" en vez de "Cantidad_Total", o
/// "Cantidad_Producida"/"Avance" en vez de "Cantidad_Actual"). Por eso
/// abajo se agregó _firstInt(), que prueba varios nombres posibles en
/// orden. Si tu columna real tiene otro nombre distinto a todos los
/// listados, agrégalo a la lista correspondiente.
class Orden {
  final int idOrden;
  final String codigoOrden;
  final String producto;
  final String? descripcion;
  final List<String> materiales;
  final int cantidadTotal;
  final int cantidadActual;
  final int idCliente;
  final String cliente;
  final int idOperario;
  final String operario;
  final String prioridad; // Alta | Media | Baja
  final String estado; // Pendiente | En proceso | Completada | Retrasada
  final String? fechaLimite; // ISO yyyy-mm-dd
  final String? fechaCreacion; // ISO

  Orden({
    required this.idOrden,
    required this.codigoOrden,
    required this.producto,
    this.descripcion,
    this.materiales = const [],
    required this.cantidadTotal,
    required this.cantidadActual,
    required this.idCliente,
    required this.cliente,
    required this.idOperario,
    required this.operario,
    required this.prioridad,
    required this.estado,
    this.fechaLimite,
    this.fechaCreacion,
  });

  /// Prueba varias llaves posibles del JSON (por si el backend usa un
  /// nombre de columna distinto al esperado) y devuelve la primera que
  /// exista y no sea nula. Devuelve 0 si ninguna existe.
  static int _firstInt(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      if (v is int) return v;
      final parsed = int.tryParse('$v');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys,
      {String fallback = ''}) {
    for (final k in keys) {
      final v = json[k];
      if (v != null && '$v'.trim().isNotEmpty) return '$v';
    }
    return fallback;
  }

  factory Orden.fromJson(Map<String, dynamic> json) {
    return Orden(
      idOrden: _firstInt(json, ['Id_Orden']),
      codigoOrden: _firstString(json, ['Codigo_Orden', 'Codigo']),
      producto: _firstString(json, ['Producto']),
      descripcion: json['Descripcion'],
      materiales:
      (json['Materiales'] as List?)?.map((e) => '$e').toList() ?? const [],
      cantidadTotal: _firstInt(json, [
        'Cantidad_Total',
        'Cantidad',
        'Cantidad_Solicitada',
      ]),
      cantidadActual: _firstInt(json, [
        'Cantidad_Actual',
        'Cantidad_Producida',
        'Cantidad_Elaborada',
        'Avance',
      ]),
      idCliente: _firstInt(json, ['Id_Cliente']),
      cliente: _firstString(json, ['Cliente', 'Nombre_Cliente']),
      idOperario: _firstInt(json, ['Id_Operario']),
      operario: _firstString(json, ['Operario', 'Nombre_Operario']),
      prioridad: _firstString(json, ['Prioridad'], fallback: 'Media'),
      estado: _firstString(json, ['Estado'], fallback: 'Pendiente'),
      fechaLimite: json['Fecha_Limite'],
      fechaCreacion: json['Fecha_Creacion'],
    );
  }

  double get progreso =>
      cantidadTotal == 0 ? 0 : (cantidadActual / cantidadTotal).clamp(0, 1);
  int get progresoPorcentaje => (progreso * 100).round();

  String get _prioridadLower => prioridad.toLowerCase();
  bool get isAlta => _prioridadLower == 'alta';
  bool get isMedia => _prioridadLower == 'media';
  bool get isBaja => _prioridadLower == 'baja';

  String get _estadoLower => estado.toLowerCase();
  bool get isPendiente => _estadoLower.contains('pendient');
  bool get isEnProceso => _estadoLower.contains('proceso');
  bool get isCompletada => _estadoLower.contains('completad');
  bool get isRetrasada => _estadoLower.contains('retrasad');

  String get estadoLabel {
    if (isEnProceso) return 'En proceso';
    if (isCompletada) return 'Completada';
    if (isRetrasada) return 'Retrasada';
    return 'Pendiente';
  }

  String get prioridadLabel {
    if (isAlta) return 'Alta';
    if (isBaja) return 'Baja';
    return 'Media';
  }

  /// Iniciales del operario para el avatar circular
  /// (mismo patrón que Usuario.initials en usuario_model.dart)
  String get operarioInitials {
    final parts = operario.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  /// Formatea Fecha_Limite (ISO) a "d/m/yyyy"
  /// (mismo patrón que Usuario.fechaCorta)
  String get fechaCorta {
    if (fechaLimite == null || fechaLimite!.isEmpty) return '';
    try {
      final d = DateTime.parse(fechaLimite!);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return fechaLimite!;
    }
  }
}