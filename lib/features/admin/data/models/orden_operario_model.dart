class OrdenOperario {
  final int idOrdenOperario;
  final int idOrden;
  final int idOperario;
  final int numeroFase;
  final String descripcionFase;
  final int cantidadRealizada;
  final String estadoFase;
  final String? nombreOperario;

  final String? producto;
  final String? descripcionOrden;
  final int? cantidadOrden;
  final int? unidadesRealizadasOrden;
  final String? estadoOrden;
  final String? prioridad;
  final String? fechaLimite;
  final int? idCliente;
  final String? cliente;
  final String? nombreMaterial;

  OrdenOperario({
    required this.idOrdenOperario,
    required this.idOrden,
    required this.idOperario,
    required this.numeroFase,
    required this.descripcionFase,
    required this.cantidadRealizada,
    required this.estadoFase,
    this.nombreOperario,
    this.producto,
    this.descripcionOrden,
    this.cantidadOrden,
    this.unidadesRealizadasOrden,
    this.estadoOrden,
    this.prioridad,
    this.fechaLimite,
    this.idCliente,
    this.cliente,
    this.nombreMaterial,
  });

  factory OrdenOperario.fromJson(Map<String, dynamic> json) {
    return OrdenOperario(
      idOrdenOperario: _toInt(json['Id_Orden_Operario']),
      idOrden: _toInt(json['Id_Orden']),
      idOperario: _toInt(json['Id_Operario']),
      numeroFase: _toInt(json['Numero_Fase']),
      descripcionFase: json['Descripcion_Fase']?.toString() ?? '',
      cantidadRealizada: _toInt(json['Cantidad_Realizada']),
      estadoFase: json['Estado_Fase']?.toString() ?? 'Pendiente',
      nombreOperario: json['Nombre_Operario']?.toString(),
      producto: json['Producto']?.toString(),
      descripcionOrden: json['Descripcion_Orden']?.toString(),
      cantidadOrden: _toIntOrNull(json['Cantidad']),
      unidadesRealizadasOrden: _toIntOrNull(json['Unidades_Realizadas']),
      estadoOrden: json['Estado_Orden']?.toString(),
      prioridad: json['Prioridad']?.toString(),
      fechaLimite: json['Fecha_Limite']?.toString(),
      idCliente: _toIntOrNull(json['Id_Cliente']),
      cliente: json['Cliente']?.toString(),
      nombreMaterial: json['NombreMaterial']?.toString(),
    );
  }

  static int _toInt(dynamic value) => _toIntOrNull(value) ?? 0;

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool get isCompletada => estadoFase.toLowerCase().contains('completad');
  bool get isEnProceso => estadoFase.toLowerCase().contains('proceso');
  bool get isPendiente => estadoFase.toLowerCase().contains('pendient');

  bool get isAlta => (prioridad ?? '').toLowerCase() == 'alta';
  bool get isBaja => (prioridad ?? '').toLowerCase() == 'baja';

  String get prioridadLabel {
    if (isAlta) return 'Alta';
    if (isBaja) return 'Baja';
    return 'Media';
  }

  String get estadoFaseLabel {
    if (isCompletada) return 'Completada';
    if (isEnProceso) return 'En proceso';
    return 'Pendiente';
  }

  bool get isRetrasada {
    if (isCompletada || fechaLimite == null || fechaLimite!.trim().isEmpty) {
      return false;
    }
    final limite = DateTime.tryParse(fechaLimite!);
    return limite != null && limite.isBefore(DateTime.now());
  }

  double get progresoFase {
    final total = cantidadOrden ?? 0;
    if (total <= 0) return 0;
    return (cantidadRealizada / total).clamp(0.0, 1.0);
  }

  int get progresoFasePorcentaje => (progresoFase * 100).round();

  int get cantidadRestante {
    final total = cantidadOrden ?? 0;
    return (total - cantidadRealizada).clamp(0, total).toInt();
  }

  String get codigoOrden => 'ORD-$idOrden';

  String get fechaCorta {
    if (fechaLimite == null || fechaLimite!.isEmpty) return '';
    try {
      final date = DateTime.parse(fechaLimite!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return fechaLimite!;
    }
  }
}
