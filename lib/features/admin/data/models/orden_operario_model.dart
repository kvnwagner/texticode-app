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
  final String? notaOperario;
  final String? fechaCompletada;

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
    this.notaOperario,
    this.fechaCompletada,
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
      notaOperario: json['Nota_Operario']?.toString(),
      fechaCompletada: json['Fecha_Completada']?.toString(),
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

  /// La tabla histórica puede contener "Pendiente", pero para el operario
  /// solo existen tres estados visibles: en proceso, retrasada y completada.
  bool get isEnProceso => !isCompletada && !isRetrasada;

  bool get isAlta => (prioridad ?? '').toLowerCase() == 'alta';
  bool get isBaja => (prioridad ?? '').toLowerCase() == 'baja';

  String get prioridadLabel {
    if (isAlta) return 'Alta';
    if (isBaja) return 'Baja';
    return 'Media';
  }

  String get estadoFaseLabel {
    if (isCompletada) return 'Completada';
    if (isRetrasada) return 'Retrasada';
    if (isEnProceso) return 'En proceso';
    return 'En proceso';
  }

  bool get isRetrasada {
    if (isCompletada || fechaLimite == null || fechaLimite!.trim().isEmpty) {
      return false;
    }
    final limite = DateTime.tryParse(fechaLimite!);
    if (limite == null) return false;
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaLimiteDia = DateTime(limite.year, limite.month, limite.day);
    return fechaLimiteDia.isBefore(inicioHoy);
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

  /// Orden operativo común para web y móvil: vencidas, en proceso y
  /// completadas. Dentro de cada grupo vence primero la fecha más cercana.
  static int compareForOperario(OrdenOperario a, OrdenOperario b) {
    int grupo(OrdenOperario fase) {
      if (fase.isRetrasada) return 0;
      if (fase.isCompletada) return 2;
      return 1;
    }

    final byGroup = grupo(a).compareTo(grupo(b));
    if (byGroup != 0) return byGroup;
    final aDate = DateTime.tryParse(a.fechaLimite ?? '');
    final bDate = DateTime.tryParse(b.fechaLimite ?? '');
    if (aDate != null && bDate != null) {
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
    } else if (aDate != null) {
      return -1;
    } else if (bDate != null) {
      return 1;
    }
    return a.numeroFase.compareTo(b.numeroFase);
  }
}
