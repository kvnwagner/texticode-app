import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/carga_trabajo_model.dart';

/// Cliente de /api/carga-trabajo. Es la ÚNICA fuente de verdad para saber
/// quién está sobrecargado y para reasignar: la app ya no cuenta ni
/// clasifica por su cuenta.
class CargaTrabajoRepository {
  Map<String, String> get _jsonHeaders => {
        ...ApiConstants.eficienciaHeaders,
        'Content-Type': 'application/json',
      };

  /// GET /api/carga-trabajo?estado=sobrecargado|normal|disponible
  Future<CargaTrabajoResultado> getCarga({String? estado}) async {
    final uri = Uri.parse(ApiConstants.cargaTrabajo)
        .replace(queryParameters: estado == null ? null : {'estado': estado});
    final res = await http.get(uri, headers: ApiConstants.eficienciaHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final List data = body['data'] ?? [];
      return CargaTrabajoResultado(
        resumen: CargaResumen.fromJson((body['resumen'] ?? {}) as Map<String, dynamic>),
        operarios: data.map((e) => CargaOperario.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    throw Exception(_mensaje(res, 'No se pudo cargar la carga de trabajo (${res.statusCode}).'));
  }

  /// GET /api/carga-trabajo/operarios/:id
/// Devuelve TODAS las fases/órdenes activas de un operario (no solo las
/// que el algoritmo de sugerencias pudo calcular). Esto es lo que hay
/// que usar para listar las órdenes en la vista de reasignación.
Future<List<OrdenActivaDetalle>> getDetalleOperario(int idOperario) async {
  final uri = Uri.parse('${ApiConstants.cargaTrabajo}/operarios/$idOperario');
  final res = await http.get(uri, headers: ApiConstants.eficienciaHeaders);

  if (res.statusCode == 200) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] ?? {}) as Map<String, dynamic>;
    final List detalle = data['ordenes_activas_detalle'] ?? [];
    return detalle
        .map((e) => OrdenActivaDetalle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  throw Exception(_mensaje(res, 'No se pudo cargar el detalle del operario (${res.statusCode}).'));
}

  /// GET /api/carga-trabajo/sugerencias
  /// Devuelve lista vacía si no hay sobrecargados o no hay disponibles.
  Future<List<SugerenciaCarga>> getSugerencias() async {
    final uri = Uri.parse('${ApiConstants.cargaTrabajo}/sugerencias');
    final res = await http.get(uri, headers: ApiConstants.eficienciaHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final List data = body['sugerencias'] ?? [];
      return data.map((e) => SugerenciaCarga.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_mensaje(res, 'No se pudieron cargar las sugerencias (${res.statusCode}).'));
  }

  /// POST /api/carga-trabajo/reasignar
  /// Mueve SOLO la fase indicada. Para órdenes antiguas sin fases envía
  /// [idOrden] en lugar de [idOrdenOperario].
  Future<void> reasignar({
    int? idOrdenOperario,
    int? idOrden,
    required int idOperarioDestino,
  }) async {
    assert(idOrdenOperario != null || idOrden != null);

    final res = await http.post(
      Uri.parse('${ApiConstants.cargaTrabajo}/reasignar'),
      headers: _jsonHeaders,
      body: jsonEncode({
        if (idOrdenOperario != null) 'Id_Orden_Operario': idOrdenOperario else 'Id_Orden': idOrden,
        'Id_Operario_Destino': idOperarioDestino,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_mensaje(res, 'No se pudo reasignar (${res.statusCode}).'));
    }
  }

  /// Atajo: reasigna directamente un movimiento sugerido.
  Future<void> reasignarMovimiento(MovimientoSugerido m) {
    return reasignar(
      idOrdenOperario: m.esFase ? m.idOrdenOperario : null,
      idOrden: m.esFase ? null : m.idOrden,
      idOperarioDestino: m.haciaId,
    );
  }

  /// POST /api/carga-trabajo/aplicar-sugerencias
  /// Devuelve cuántas reasignaciones se aplicaron.
  Future<int> aplicarSugerencias() async {
    final res = await http.post(
      Uri.parse('${ApiConstants.cargaTrabajo}/aplicar-sugerencias'),
      headers: _jsonHeaders,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['aplicados'] as num?)?.toInt() ?? 0;
    }
    throw Exception(_mensaje(res, 'No se pudieron aplicar las sugerencias (${res.statusCode}).'));
  }

  String _mensaje(http.Response res, String porDefecto) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['mensaje'] as String?) ?? porDefecto;
    } catch (_) {
      return porDefecto;
    }
  }
}