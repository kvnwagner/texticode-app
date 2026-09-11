import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../models/orden_operario_model.dart';

class OrdenOperarioRepository {
  Future<OrdenOperario> agregarFase({
    required int idOrden,
    required int idOperario,
    required int numeroFase,
    String? descripcionFase,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.ordenOperario),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Orden': idOrden,
        'Id_Operario': idOperario,
        'Numero_Fase': numeroFase,
        'Descripcion_Fase': descripcionFase,
      }),
    );

    if (res.statusCode == 201) {
      return OrdenOperario.fromJson(jsonDecode(res.body));
    }

    final body = _tryDecode(res.body);

    throw Exception(
      body?['error'] ?? 'No se pudo agregar la fase.',
    );
  }

  Future<List<OrdenOperario>> getFasesDeOrden(int idOrden) async {
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.ordenOperario}/orden/$idOrden',
      ),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      return data
          .map((e) => OrdenOperario.fromJson(e))
          .toList();
    }

    throw Exception(
      'No se pudieron cargar las fases de la orden.',
    );
  }

  Future<List<OrdenOperario>> getFasesDeOperario(
    int idOperario,
  ) async {
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.ordenOperario}/operario/$idOperario',
      ),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      return data
          .map((e) => OrdenOperario.fromJson(e))
          .toList();
    }

    throw Exception(
      'No se pudieron cargar las fases del operario.',
    );
  }

  Future<OrdenOperario> actualizarFase({
    required int idOrdenOperario,
    int? numeroFase,
    String? descripcionFase,
  }) async {
    final res = await http.put(
      Uri.parse(
        '${ApiConstants.ordenOperario}/$idOrdenOperario',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (numeroFase != null)
          'Numero_Fase': numeroFase,
        if (descripcionFase != null)
          'Descripcion_Fase': descripcionFase,
      }),
    );

    if (res.statusCode == 200) {
      return OrdenOperario.fromJson(
        jsonDecode(res.body),
      );
    }

    final body = _tryDecode(res.body);

    throw Exception(
      body?['error'] ?? 'No se pudo actualizar la fase.',
    );
  }

  Future<void> eliminarFase(
    int idOrdenOperario,
  ) async {
    final res = await http.delete(
      Uri.parse(
        '${ApiConstants.ordenOperario}/$idOrdenOperario',
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'No se pudo quitar la fase de la orden.',
      );
    }
  }

  Future<void> reportarAvanceIncremental({
    required int idOrdenOperario,
    required int unidadesSesion,
  }) async {
    final res = await http.patch(
      Uri.parse(
        '${ApiConstants.ordenOperario}/$idOrdenOperario/avance',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'unidadesSesion': unidadesSesion,
      }),
    );

    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);

      throw Exception(
        body?['error'] ??
            'No se pudo reportar el avance.',
      );
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