/// Mapea GET /api/carga-trabajo y GET /api/carga-trabajo/sugerencias
/// (carga-trabajo del backend). La carga cuenta FASES activas (y órdenes
/// antiguas sin fases); la clasificación (sobrecargado / normal /
/// disponible) la calcula el backend, la app solo la muestra.

class CargaOperario {
  final int idUsuario;
  final String nombreCompleto;
  final String nombreUsuario;
  final String? correo;
  final String? telefono;

  /// Total de carga: fases activas + órdenes antiguas sin fases.
  final int ordenesActivas;
  final int fasesActivas;
  final int ordenesVencidas;
  final int ordenesAltaPrioridad;

  /// 'sobrecargado' | 'normal' | 'disponible' (viene del backend)
  final String estadoCarga;

  CargaOperario({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.nombreUsuario,
    this.correo,
    this.telefono,
    required this.ordenesActivas,
    required this.fasesActivas,
    required this.ordenesVencidas,
    required this.ordenesAltaPrioridad,
    required this.estadoCarga,
  });

  bool get esSobrecargado => estadoCarga == 'sobrecargado';
  bool get esNormal => estadoCarga == 'normal';
  bool get esDisponible => estadoCarga == 'disponible';

  String get initials {
    final parts = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory CargaOperario.fromJson(Map<String, dynamic> json) {
    return CargaOperario(
      idUsuario: _asInt(json['Id_Usuario']),
      nombreCompleto: json['Nombre_Completo'] ?? '',
      nombreUsuario: json['Nombre_Usuario'] ?? '',
      correo: json['Correo'],
      telefono: json['Telefono'],
      ordenesActivas: _asInt(json['ordenes_activas']),
      fasesActivas: _asInt(json['fases_activas']),
      ordenesVencidas: _asInt(json['ordenes_vencidas']),
      ordenesAltaPrioridad: _asInt(json['ordenes_alta_prioridad']),
      estadoCarga: json['estado_carga'] ?? 'normal',
    );
  }
}

class CargaResumen {
  final int totalOperarios;
  final int sobrecargados;
  final int normales;
  final int disponibles;

  CargaResumen({
    required this.totalOperarios,
    required this.sobrecargados,
    required this.normales,
    required this.disponibles,
  });

  factory CargaResumen.fromJson(Map<String, dynamic> json) {
    return CargaResumen(
      totalOperarios: _asInt(json['total_operarios']),
      sobrecargados: _asInt(json['sobrecargados']),
      normales: _asInt(json['normales']),
      disponibles: _asInt(json['disponibles']),
    );
  }
}

class CargaTrabajoResultado {
  final CargaResumen resumen;
  final List<CargaOperario> operarios;

  CargaTrabajoResultado({required this.resumen, required this.operarios});

  List<CargaOperario> get sobrecargados => operarios.where((o) => o.esSobrecargado).toList();
  List<CargaOperario> get disponibles => operarios.where((o) => o.esDisponible).toList();
}

/// Una fase u orden activa individual de UN operario (detalle completo,
/// sin filtrar por capacidad disponible). Viene de
/// GET /api/carga-trabajo/operarios/:id -> data.ordenes_activas_detalle
class OrdenActivaDetalle {
  final String tipo; // 'fase' | 'orden'
  final int? idOrdenOperario; // solo si tipo == 'fase'
  final int idOrden;
  final int idOperario;
  final int? numeroFase;
  final String? descripcionFase;
  final String estadoItem;
  final String producto;
  final String? prioridad;
  final String? fechaLimite;
  final bool vencida;

  OrdenActivaDetalle({
    required this.tipo,
    this.idOrdenOperario,
    required this.idOrden,
    required this.idOperario,
    this.numeroFase,
    this.descripcionFase,
    required this.estadoItem,
    required this.producto,
    this.prioridad,
    this.fechaLimite,
    required this.vencida,
  });

  bool get esFase => tipo == 'fase';

  String get titulo {
    if (!esFase) return producto;
    final desc = (descripcionFase ?? '').trim();
    final fase = numeroFase != null ? 'Fase $numeroFase' : 'Fase';
    return desc.isEmpty ? fase : '$fase · $desc';
  }

  /// Llave para hacer match con un MovimientoSugerido del mismo item
  /// (mismo formato que usa la vista para identificar movimientos).
  String get key => '$tipo-${esFase ? idOrdenOperario : idOrden}';

  factory OrdenActivaDetalle.fromJson(Map<String, dynamic> json) {
    return OrdenActivaDetalle(
      tipo: json['tipo'] ?? 'orden',
      idOrdenOperario:
          json['Id_Orden_Operario'] == null ? null : _asInt(json['Id_Orden_Operario']),
      idOrden: _asInt(json['Id_Orden']),
      idOperario: _asInt(json['Id_Operario']),
      numeroFase: json['Numero_Fase'] == null ? null : _asInt(json['Numero_Fase']),
      descripcionFase: json['Descripcion_Fase'],
      estadoItem: json['estado_item'] ?? '',
      producto: json['Producto'] ?? '',
      prioridad: json['Prioridad'],
      fechaLimite: json['Fecha_Limite'],
      vencida: json['vencida'] == true,
    );
  }
}

/// Un movimiento sugerido: pasar UNA fase (o una orden antigua sin fases)
/// de un operario sobrecargado a uno disponible.
class MovimientoSugerido {
  /// 'fase' | 'orden'
  final String tipo;
  final int? idOrdenOperario; // id de la fase (solo si tipo == 'fase')
  final int idOrden;
  final int? numeroFase;
  final String? descripcionFase;
  final String producto;
  final String? prioridad;
  final bool vencida;
  final String? fechaLimite;
  final int desdeId;
  final String desdeNombre;
  final int haciaId;
  final String haciaNombre;

  MovimientoSugerido({
    required this.tipo,
    this.idOrdenOperario,
    required this.idOrden,
    this.numeroFase,
    this.descripcionFase,
    required this.producto,
    this.prioridad,
    required this.vencida,
    this.fechaLimite,
    required this.desdeId,
    required this.desdeNombre,
    required this.haciaId,
    required this.haciaNombre,
  });

  bool get esFase => tipo == 'fase';

  /// Texto para mostrar en la tarjeta: "Fase 2 · Ojales" o "Orden completa".
  String get titulo {
    if (!esFase) return producto;
    final desc = (descripcionFase ?? '').trim();
    final fase = numeroFase != null ? 'Fase $numeroFase' : 'Fase';
    return desc.isEmpty ? fase : '$fase · $desc';
  }

  factory MovimientoSugerido.fromJson(Map<String, dynamic> json) {
    final desde = (json['desde_operario'] ?? {}) as Map<String, dynamic>;
    final hacia = (json['hacia_operario'] ?? {}) as Map<String, dynamic>;
    return MovimientoSugerido(
      tipo: json['tipo'] ?? 'orden',
      idOrdenOperario: json['Id_Orden_Operario'] == null ? null : _asInt(json['Id_Orden_Operario']),
      idOrden: _asInt(json['Id_Orden']),
      numeroFase: json['Numero_Fase'] == null ? null : _asInt(json['Numero_Fase']),
      descripcionFase: json['Descripcion_Fase'],
      producto: json['Producto'] ?? '',
      prioridad: json['Prioridad'],
      vencida: json['vencida'] == true,
      fechaLimite: json['Fecha_Limite'],
      desdeId: _asInt(desde['id']),
      desdeNombre: desde['nombre'] ?? '',
      haciaId: _asInt(hacia['id']),
      haciaNombre: hacia['nombre'] ?? '',
    );
  }
}

class SugerenciaCarga {
  final int operarioId;
  final String operarioNombre;
  final int ordenesActivas;
  final int exceso;
  final List<MovimientoSugerido> movimientos;

  SugerenciaCarga({
    required this.operarioId,
    required this.operarioNombre,
    required this.ordenesActivas,
    required this.exceso,
    required this.movimientos,
  });

  factory SugerenciaCarga.fromJson(Map<String, dynamic> json) {
    final op = (json['operario_sobrecargado'] ?? {}) as Map<String, dynamic>;
    return SugerenciaCarga(
      operarioId: _asInt(op['id']),
      operarioNombre: op['nombre'] ?? '',
      ordenesActivas: _asInt(op['ordenes_activas']),
      exceso: _asInt(json['exceso_ordenes']),
      movimientos: (json['movimientos'] as List? ?? [])
          .map((e) => MovimientoSugerido.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse('$v') ?? 0;
}