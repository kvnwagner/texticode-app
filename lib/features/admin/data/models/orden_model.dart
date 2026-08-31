/// lib/features/admin/data/models/orden_model.dart
///
/// Modelo de una orden de producción.
///
/// Mapea los datos que devuelve el backend GET /api/ordenes
/// y GET /api/ordenes/:id.
///
/// Nombres reales observados en el JSON del backend:
///   Id_Orden
///   Id_Cliente
///   Id_Material          ⬅️ FK obligatoria (INNER JOIN con `material`)
///   Producto
///   Cantidad
///   Prioridad
///   Fecha_Limite
///   Descripcion
///   Dificultad           (Alta | Media | Baja)
///   Estado
///   Unidades             ⬅️ meta de piezas a producir (distinto de Cantidad)
///   Unidades_Realizadas
///   Id_Operario
///   Fecha_Creacion
///   Cliente
///   NombreMaterial
///
/// ⚠️ IMPORTANTE: `Id_Material` es NOT NULL en la base de datos (el
/// backend hace INNER JOIN con `material`). Si al reconstruir una Orden
/// para hacer PUT no se envía `Id_Material`, el update puede fallar o
/// dejar el registro inconsistente. Por eso este modelo lo captura
/// explícitamente desde el GET, para poder reenviarlo tal cual en el PUT.
class Orden {
  final int idOrden;
  final String codigoOrden;
  final String producto;
  final String? descripcion;
  final List<String> materiales;

  /// FK a la tabla `material`. Requerida por el backend en POST/PUT.
  final int idMaterial;

  /// Nombre del material, solo para mostrar en UI (viene del JOIN del GET).
  final String? nombreMaterial;

  /// Cantidad total solicitada de la orden.
  /// En el backend actual corresponde a: Cantidad
  final int cantidadTotal;

  /// Cantidad de prendas realizadas hasta el momento.
  /// En el backend actual corresponde a: Unidades_Realizadas
  final int cantidadActual;

  /// Meta de unidades a producir (columna "Unidades", separada de
  /// "Cantidad"). Puede venir null en órdenes viejas.
  final int? unidades;

  /// Alta | Media | Baja — usada por el backend para ponderar
  /// "prendas por día" en /api/eficiencia.
  final String dificultad;

  final int idCliente;
  final String cliente;
  final int idOperario;
  final String operario;

  /// Valores reales del ENUM de PostgreSQL: En Proceso | Completada | Pausado
  final String prioridad;
  final String estado;

  final String? fechaLimite;
  final String? fechaCreacion;

  Orden({
    required this.idOrden,
    required this.codigoOrden,
    required this.producto,
    this.descripcion,
    this.materiales = const [],
    required this.idMaterial,
    this.nombreMaterial,
    required this.cantidadTotal,
    required this.cantidadActual,
    this.unidades,
    this.dificultad = 'Media',
    required this.idCliente,
    required this.cliente,
    required this.idOperario,
    required this.operario,
    required this.prioridad,
    required this.estado,
    this.fechaLimite,
    this.fechaCreacion,
  });

  static int _firstInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      final parsed = int.tryParse('$value');
      if (parsed != null) return parsed;
      final parsedDouble = double.tryParse('$value');
      if (parsedDouble != null) return parsedDouble.toInt();
    }
    return 0;
  }

  static int? _firstIntOrNull(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      final parsed = int.tryParse('$value');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _firstString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && '$value'.trim().isNotEmpty) return '$value';
    }
    return fallback;
  }

  static List<String> _parseMateriales(Map<String, dynamic> json) {
    final value = json['Materiales'];
    if (value == null) return const [];
    if (value is List) return value.map((e) => '$e').toList();
    if (value is String && value.trim().isNotEmpty) return [value];
    return const [];
  }

  /// Construye una Orden a partir del JSON recibido desde el backend.
  factory Orden.fromJson(Map<String, dynamic> json) {
    final cantidadTotal = _firstInt(json, [
      'Cantidad',
      'Cantidad_Total',
      'Cantidad_Solicitada',
    ]);

    final cantidadActual = _firstInt(json, [
      'Unidades_Realizadas',
      'Cantidad_Actual',
      'Cantidad_Producida',
      'Cantidad_Elaborada',
      'Avance',
    ]);

    final idOrden = _firstInt(json, ['Id_Orden']);

    final codigoOrden = _firstString(
      json,
      ['Codigo_Orden', 'Codigo'],
      fallback: 'ORD-$idOrden',
    );

    final producto = _firstString(json, ['Producto']);
    final descripcion = json['Descripcion']?.toString();
    final materiales = _parseMateriales(json);

    final idMaterial = _firstInt(json, ['Id_Material']);
    final nombreMaterial = json['NombreMaterial']?.toString() ??
        json['Nombre_Material']?.toString();

    final unidades = _firstIntOrNull(json, ['Unidades']);
    final dificultad = _firstString(json, ['Dificultad'], fallback: 'Media');

    final idCliente = _firstInt(json, ['Id_Cliente']);
    final cliente = _firstString(json, ['Cliente', 'Nombre_Cliente']);

    final idOperario = _firstInt(json, ['Id_Operario']);
    final operario = _firstString(json, ['Operario', 'Nombre_Operario']);

    final prioridad = _firstString(json, ['Prioridad'], fallback: 'Media');

    final estado = _firstString(json, ['Estado'], fallback: 'En Proceso');

    final fechaLimite = json['Fecha_Limite']?.toString();
    final fechaCreacion = json['Fecha_Creacion']?.toString();

    return Orden(
      idOrden: idOrden,
      codigoOrden: codigoOrden,
      producto: producto,
      descripcion: descripcion,
      materiales: materiales,
      idMaterial: idMaterial,
      nombreMaterial: nombreMaterial,
      cantidadTotal: cantidadTotal,
      cantidadActual: cantidadActual,
      unidades: unidades,
      dificultad: dificultad,
      idCliente: idCliente,
      cliente: cliente,
      idOperario: idOperario,
      operario: operario,
      prioridad: prioridad,
      estado: estado,
      fechaLimite: fechaLimite,
      fechaCreacion: fechaCreacion,
    );
  }

  double get progreso {
    if (cantidadTotal <= 0) return 0;
    return (cantidadActual / cantidadTotal).clamp(0.0, 1.0);
  }

  int get progresoPorcentaje => (progreso * 100).round();

  int get cantidadRestante =>
      (cantidadTotal - cantidadActual).clamp(0, cantidadTotal).toInt();

  String get _prioridadLower => prioridad.trim().toLowerCase();
  bool get isAlta => _prioridadLower == 'alta';
  bool get isMedia => _prioridadLower == 'media';
  bool get isBaja => _prioridadLower == 'baja';

  String get prioridadLabel {
    if (isAlta) return 'Alta';
    if (isBaja) return 'Baja';
    return 'Media';
  }

  String get _estadoLower => estado.trim().toLowerCase();
  bool get isEnProceso =>
      _estadoLower == 'en proceso' || _estadoLower.contains('proceso');
  bool get isCompletada =>
      _estadoLower == 'completada' || _estadoLower.contains('completad');
  bool get isPausado => _estadoLower == 'pausado' || _estadoLower.contains('paus');
  bool get isPendiente =>
      _estadoLower == 'pendiente' || _estadoLower.contains('pendient');
  bool get isRetrasada =>
      _estadoLower == 'retrasada' || _estadoLower.contains('retrasad');

  String get estadoLabel {
    if (isEnProceso) return 'En proceso';
    if (isCompletada) return 'Completada';
    if (isPausado) return 'Pausado';
    if (isRetrasada) return 'Retrasada';
    if (isPendiente) return 'Pendiente';
    return estado;
  }

  String get operarioInitials {
    final nombre = operario.trim();
    if (nombre.isEmpty) return '??';
    final parts = nombre.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get fechaCorta {
    if (fechaLimite == null || fechaLimite!.isEmpty) return '';
    try {
      final date = DateTime.parse(fechaLimite!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return fechaLimite!;
    }
  }

  String get fechaCreacionCorta {
    if (fechaCreacion == null || fechaCreacion!.isEmpty) return '';
    try {
      final date = DateTime.parse(fechaCreacion!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return fechaCreacion!;
    }
  }
}