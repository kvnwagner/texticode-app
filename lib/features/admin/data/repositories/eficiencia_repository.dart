import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/eficiencia_operario_model.dart';

class EficienciaRepository {
  Future<List<EficienciaOperario>> getOperarios({
    String? rendimiento,
    String? estado,
    int? limite,
  }) async {
    final query = <String, String>{
      if (rendimiento != null) 'rendimiento': rendimiento,
      if (estado != null) 'estado': estado,
      if (limite != null) 'limite': '$limite',
    };

    final uri = Uri.parse('${ApiConstants.eficiencia}/operarios')
        .replace(queryParameters: query.isEmpty ? null : query);

    final res = await http.get(uri, headers: ApiConstants.eficienciaHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List data = body['data'] ?? [];
      return data.map((e) => EficienciaOperario.fromJson(e)).toList();
    }
    throw Exception('No se pudo cargar la eficiencia (${res.statusCode}).');
  }

  Future<Map<String, dynamic>> getOperarioDetalle(int idUsuario) async {
    final uri = Uri.parse('${ApiConstants.eficiencia}/operarios/$idUsuario');
    final res = await http.get(uri, headers: ApiConstants.eficienciaHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('No se pudo cargar el detalle del operario (${res.statusCode}).');
  }

  /// GET /api/eficiencia/operarios/:id/historial?periodo=semana|mes|trimestre
  Future<EficienciaHistorial> getHistorial(int idUsuario, String periodo) async {
    final uri = Uri.parse('${ApiConstants.eficiencia}/operarios/$idUsuario/historial')
        .replace(queryParameters: {'periodo': periodo});
    final res = await http.get(uri, headers: ApiConstants.eficienciaHeaders);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return EficienciaHistorial.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception('No se pudo cargar la tendencia (${res.statusCode}).');
  }

  /// POST /api/eficiencia/observaciones
  Future<void> crearObservacion({
    required int idOperario,
    required int idAdmin,
    required int idOrden,
    required String observacion,
  }) async {
    final uri = Uri.parse('${ApiConstants.eficiencia}/observaciones');
    final res = await http.post(
      uri,
      headers: {
        ...ApiConstants.eficienciaHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Id_Operario': idOperario,
        'Id_Admin': idAdmin,
        'Id_Orden': idOrden,
        'Observacion': observacion,
      }),
    );
    if (res.statusCode != 201) {
      final body = _tryDecode(res.body);
      throw Exception(body?['mensaje'] ?? 'No se pudo guardar la observación.');
    }
  }

  /// DELETE /api/eficiencia/observaciones/:id
  Future<void> eliminarObservacion(int idObservacion) async {
    final uri = Uri.parse('${ApiConstants.eficiencia}/observaciones/$idObservacion');
    final res = await http.delete(uri, headers: ApiConstants.eficienciaHeaders);
    if (res.statusCode != 200) {
      throw Exception('No se pudo eliminar la observación.');
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}