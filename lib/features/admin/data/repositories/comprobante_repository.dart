import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/comprobante_model.dart';

/// Habla directo con tu backend Express (comprobantes.js).
class ComprobanteRepository {
  Future<List<Comprobante>> getComprobantes() async {
    final res = await http.get(Uri.parse(ApiConstants.comprobantes));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Comprobante.fromJson(e)).toList();
    }
    throw Exception('No se pudieron cargar los comprobantes (${res.statusCode}).');
  }

  Future<List<Comprobante>> getComprobantesPorCliente(int idCliente) async {
    final res = await http
        .get(Uri.parse('${ApiConstants.comprobantes}/cliente/$idCliente'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Comprobante.fromJson(e)).toList();
    }
    throw Exception(
        'No se pudieron cargar los comprobantes del cliente (${res.statusCode}).');
  }

  Future<void> actualizarEstado({
    required int id,
    required String estado,
    String? fechaLimite,
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.comprobantes}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Estado': estado,
        'Fecha_Limite': fechaLimite,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('No se pudo actualizar el comprobante.');
    }
  }
}