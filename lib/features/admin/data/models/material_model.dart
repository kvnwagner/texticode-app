/// Modelo de un material de inventario.
/// Mapea 1:1 las columnas de la tabla `material` en Supabase,
/// tal como las devuelve materiales.js (incluye el JOIN con usuario
/// para traer el nombre del cliente dueño del material).
class MaterialItem {
  final int idMaterial;
  final String nombre;
  final String categoria;
  final int stockActual;
  final String unidad;
  final int stockMinimo;
  final int stockMaximo;
  final int? idCliente;
  final String? nombreCliente;

  MaterialItem({
    required this.idMaterial,
    required this.nombre,
    required this.categoria,
    required this.stockActual,
    required this.unidad,
    required this.stockMinimo,
    required this.stockMaximo,
    this.idCliente,
    this.nombreCliente,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    int toIntValue(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return MaterialItem(
      idMaterial: toIntValue(json['Id_Material']),
      nombre: json['Nombre_Material'] as String? ?? '',
      categoria: json['Categoria'] as String? ?? '',
      stockActual: toIntValue(json['Stock_Actual']),
      unidad: json['Unidad'] as String? ?? '',
      stockMinimo: toIntValue(json['Stock_Minimo']),
      stockMaximo: toIntValue(json['Stock_Maximo']),
      idCliente: json['Id_Cliente'] == null ? null : toIntValue(json['Id_Cliente']),
      nombreCliente: json['Nombre_Cliente'] as String?,
    );
  }

  bool get isLow => stockActual < stockMinimo;

  /// Progreso del stock actual contra el máximo (0.0 – 1.0), usado
  /// para pintar la barra de progreso de cada card.
  double get stockPct {
    if (stockMaximo <= 0) return 0;
    final p = stockActual / stockMaximo;
    return p.clamp(0.0, 1.0);
  }
}