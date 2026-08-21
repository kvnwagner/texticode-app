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
}