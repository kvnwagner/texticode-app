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
///   Id_Material
///   Producto
///   Cantidad
///   Prioridad
///   Fecha_Limite
///   Descripcion
///   Dificultad
///   Estado
///   Unidades_Realizadas
///   Id_Operario
///   Unidades
///   Fecha_Creacion
///   Cliente
///   NombreMaterial
///
/// Para mantener compatibilidad con versiones anteriores del backend,
/// también se aceptan nombres alternativos como:
///   Cantidad_Total
///   Cantidad_Actual
///   Cantidad_Producida
///   Cantidad_Elaborada
///   Avance
///   Cantidad_Solicitada
class Orden {
  final int idOrden;
  final String codigoOrden;
  final String producto;
  final String? descripcion;
  final List<String> materiales;

  /// Cantidad total solicitada de la orden.
  ///
  /// En el backend actual corresponde a:
  ///   Cantidad
  final int cantidadTotal;

  /// Cantidad de prendas realizadas hasta el momento.
  ///
  /// En el backend actual corresponde a:
  ///   Unidades_Realizadas
  ///
  /// Si el backend devuelve null, se interpreta como 0.
  final int cantidadActual;

  final int idCliente;
  final String cliente;
  final int idOperario;
  final String operario;

  /// Valores reales del ENUM de PostgreSQL:
  ///   En Proceso
  ///   Completada
  ///   Pausado
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

  /// Busca un entero en varias posibles llaves del JSON.
  ///
  /// También soporta:
  /// - int
  /// - double
  /// - String numérico
  ///
  /// Si no encuentra ningún valor válido devuelve 0.
  static int _firstInt(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];

      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }

      if (value is double) {
        return value.toInt();
      }

      final parsed = int.tryParse('$value');

      if (parsed != null) {
        return parsed;
      }

      final parsedDouble = double.tryParse('$value');

      if (parsedDouble != null) {
        return parsedDouble.toInt();
      }
    }

    return 0;
  }

  /// Busca un String en varias posibles llaves del JSON.
  ///
  /// Ignora valores null o cadenas vacías.
  static String _firstString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value != null && '$value'.trim().isNotEmpty) {
        return '$value';
      }
    }

    return fallback;
  }

  /// Convierte el campo Materiales en una lista de Strings.
  ///
  /// Soporta:
  /// - List
  /// - String
  /// - null
  static List<String> _parseMateriales(
    Map<String, dynamic> json,
  ) {
    final value = json['Materiales'];

    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value.map((e) => '$e').toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }

    return const [];
  }

  /// Construye una Orden a partir del JSON recibido desde el backend.
  factory Orden.fromJson(Map<String, dynamic> json) {
    // ============================================================
    // CANTIDAD TOTAL
    // ============================================================
    //
    // El JSON real devuelve:
    //
    // "Cantidad": 300
    //
    // Por eso "Cantidad" debe ser la primera opción.
    final cantidadTotal = _firstInt(
      json,
      [
        'Cantidad',
        'Cantidad_Total',
        'Cantidad_Solicitada',
      ],
    );

    // ============================================================
    // CANTIDAD ACTUAL
    // ============================================================
    //
    // El JSON real devuelve:
    //
    // "Unidades_Realizadas": 12
    //
    // o para órdenes nuevas:
    //
    // "Unidades_Realizadas": null
    //
    // Cuando es null, _firstInt() devuelve 0.
    final cantidadActual = _firstInt(
      json,
      [
        'Unidades_Realizadas',
        'Cantidad_Actual',
        'Cantidad_Producida',
        'Cantidad_Elaborada',
        'Avance',
      ],
    );

    // ============================================================
    // DATOS DE LA ORDEN
    // ============================================================

    final idOrden = _firstInt(
      json,
      [
        'Id_Orden',
      ],
    );

    final codigoOrden = _firstString(
      json,
      [
        'Codigo_Orden',
        'Codigo',
      ],
      fallback: 'ORD-$idOrden',
    );

    final producto = _firstString(
      json,
      [
        'Producto',
      ],
    );

    final descripcion = json['Descripcion']?.toString();

    // ============================================================
    // MATERIALES
    // ============================================================

    final materiales = _parseMateriales(json);

    // ============================================================
    // CLIENTE
    // ============================================================

    final idCliente = _firstInt(
      json,
      [
        'Id_Cliente',
      ],
    );

    final cliente = _firstString(
      json,
      [
        'Cliente',
        'Nombre_Cliente',
      ],
    );

    // ============================================================
    // OPERARIO
    // ============================================================

    final idOperario = _firstInt(
      json,
      [
        'Id_Operario',
      ],
    );

    final operario = _firstString(
      json,
      [
        'Operario',
        'Nombre_Operario',
      ],
    );

    // ============================================================
    // PRIORIDAD
    // ============================================================

    final prioridad = _firstString(
      json,
      [
        'Prioridad',
      ],
      fallback: 'Media',
    );

    // ============================================================
    // ESTADO
    // ============================================================
    //
    // IMPORTANTE:
    // PostgreSQL utiliza exactamente:
    //
    // "En Proceso"
    // "Completada"
    // "Pausado"
    //
    // No debemos cambiar el valor aquí porque ese mismo valor
    // puede necesitarse posteriormente para enviarlo al backend.
    final estado = _firstString(
      json,
      [
        'Estado',
      ],
      fallback: 'En Proceso',
    );

    // ============================================================
    // FECHAS
    // ============================================================

    final fechaLimite = json['Fecha_Limite']?.toString();

    final fechaCreacion = json['Fecha_Creacion']?.toString();

    // ============================================================
    // CREAR MODELO
    // ============================================================

    return Orden(
      idOrden: idOrden,
      codigoOrden: codigoOrden,
      producto: producto,
      descripcion: descripcion,
      materiales: materiales,
      cantidadTotal: cantidadTotal,
      cantidadActual: cantidadActual,
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

  // ==============================================================
  // PROGRESO
  // ==============================================================

  /// Progreso de la orden entre 0 y 1.
  double get progreso {
    if (cantidadTotal <= 0) {
      return 0;
    }

    return (cantidadActual / cantidadTotal).clamp(0.0, 1.0);
  }

  /// Progreso expresado como porcentaje entero.
  ///
  /// Ejemplo:
  ///
  /// 12 / 300 = 4%
  int get progresoPorcentaje {
    return (progreso * 100).round();
  }

  /// Cantidad de prendas que todavía faltan por realizar.
  int get cantidadRestante {
    return (cantidadTotal - cantidadActual)
        .clamp(0, cantidadTotal)
        .toInt();
  }

  // ==============================================================
  // PRIORIDAD
  // ==============================================================

  String get _prioridadLower {
    return prioridad.trim().toLowerCase();
  }

  bool get isAlta {
    return _prioridadLower == 'alta';
  }

  bool get isMedia {
    return _prioridadLower == 'media';
  }

  bool get isBaja {
    return _prioridadLower == 'baja';
  }

  String get prioridadLabel {
    if (isAlta) {
      return 'Alta';
    }

    if (isBaja) {
      return 'Baja';
    }

    return 'Media';
  }

  // ==============================================================
  // ESTADO
  // ==============================================================

  String get _estadoLower {
    return estado.trim().toLowerCase();
  }

  bool get isEnProceso {
    return _estadoLower == 'en proceso' ||
        _estadoLower.contains('proceso');
  }

  bool get isCompletada {
    return _estadoLower == 'completada' ||
        _estadoLower.contains('completad');
  }

  bool get isPausado {
    return _estadoLower == 'pausado' ||
        _estadoLower.contains('paus');
  }

  bool get isPendiente {
    return _estadoLower == 'pendiente' ||
        _estadoLower.contains('pendient');
  }

  bool get isRetrasada {
    return _estadoLower == 'retrasada' ||
        _estadoLower.contains('retrasad');
  }

  /// Texto que se muestra en la interfaz.
  ///
  /// El backend conserva:
  ///   En Proceso
  ///
  /// pero la interfaz puede mostrar:
  ///   En proceso
  String get estadoLabel {
    if (isEnProceso) {
      return 'En proceso';
    }

    if (isCompletada) {
      return 'Completada';
    }

    if (isPausado) {
      return 'Pausado';
    }

    if (isRetrasada) {
      return 'Retrasada';
    }

    if (isPendiente) {
      return 'Pendiente';
    }

    return estado;
  }

  // ==============================================================
  // INICIALES DEL OPERARIO
  // ==============================================================

  /// Iniciales del operario para el avatar circular.
  String get operarioInitials {
    final nombre = operario.trim();

    if (nombre.isEmpty) {
      return '??';
    }

    final parts = nombre.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (
      parts.first.substring(0, 1) +
      parts[1].substring(0, 1)
    ).toUpperCase();
  }

  // ==============================================================
  // FECHA
  // ==============================================================

  /// Formatea Fecha_Limite (ISO) a:
  ///
  /// d/m/yyyy
  ///
  /// Ejemplo:
  ///
  /// 2026-06-05T05:00:00.000Z
  /// ↓
  /// 5/6/2026
  String get fechaCorta {
    if (fechaLimite == null || fechaLimite!.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(fechaLimite!);

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return fechaLimite!;
    }
  }

  /// Fecha de creación formateada a:
  ///
  /// d/m/yyyy
  String get fechaCreacionCorta {
    if (fechaCreacion == null || fechaCreacion!.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(fechaCreacion!);

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return fechaCreacion!;
    }
  }
}