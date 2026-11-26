import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/comprobante_model.dart';

/// Habla directo con tu backend Express (comprobantes.js).
class ComprobanteRepository {
  Future<List<Comprobante>> getComprobantes() async {
    final List data = await ApiClient.get('/comprobantes');
    return data.map((e) => Comprobante.fromJson(e)).toList();
  }

  Future<List<Comprobante>> getComprobantesPorCliente(int idCliente) async {
    final List data = await ApiClient.get('/comprobantes/cliente/$idCliente');
    return data.map((e) => Comprobante.fromJson(e)).toList();
  }

  Future<void> actualizarEstado({
    required int id,
    required String estado,
    String? fechaLimite,
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.comprobantes}/$id'),
      headers: await ApiClient.headers(),
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
