import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/material_model.dart';

/// Habla directo con tu backend Express (materiales.js), que a su vez
/// habla con Supabase. Mismo patrón exacto que orden_repository.dart.
class MaterialRepository {
  Future<List<MaterialItem>> getMateriales() async {
    final res = await http.get(Uri.parse(ApiConstants.materiales));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => MaterialItem.fromJson(e)).toList();
    }
    throw Exception('No se pudieron cargar los materiales (${res.statusCode}).');
  }

  Future<MaterialItem> getMaterial(int id) async {
    final res = await http.get(Uri.parse('${ApiConstants.materiales}/$id'));
    if (res.statusCode == 200) return MaterialItem.fromJson(jsonDecode(res.body));
    throw Exception('MaterialItem no encontrado.');
  }

  /// Usa el endpoint dedicado de alertas del backend en vez de filtrar
  /// en el cliente, para que la regla de negocio (Stock_Actual <=
  /// Stock_Minimo) viva en un solo lugar.
  Future<List<MaterialItem>> getAlertasStockBajo() async {
    final res =
        await http.get(Uri.parse('${ApiConstants.materiales}/alertas/stock-bajo'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => MaterialItem.fromJson(e)).toList();
    }
    throw Exception('No se pudieron cargar las alertas de stock.');
  }

  Future<void> crearMaterial({
    required String nombre,
    required String categoria,
    required int stockActual,
    required String unidad,
    required int stockMinimo,
    required int stockMaximo,
    int? idCliente,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.materiales),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Nombre_Material': nombre,
        'Categoria': categoria,
        'Stock_Actual': stockActual,
        'Unidad': unidad,
        'Stock_Minimo': stockMinimo,
        'Stock_Maximo': stockMaximo,
        'Id_Cliente': idCliente,
      }),
    );
    if (res.statusCode != 201) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo crear el material.');
    }
  }

  Future<void> actualizarMaterial({
    required int id,
    required String nombre,
    required String categoria,
    required int stockActual,
    required String unidad,
    required int stockMinimo,
    required int stockMaximo,
    int? idCliente,
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.materiales}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Nombre_Material': nombre,
        'Categoria': categoria,
        'Stock_Actual': stockActual,
        'Unidad': unidad,
        'Stock_Minimo': stockMinimo,
        'Stock_Maximo': stockMaximo,
        'Id_Cliente': idCliente,
      }),
    );
    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo actualizar el material.');
    }
  }

  /// Delete definitivo. Úsalo con cuidado.
  Future<void> eliminarMaterial(int id) async {
    final res = await http.delete(Uri.parse('${ApiConstants.materiales}/$id'));
    if (res.statusCode != 200) {
      throw Exception('No se pudo eliminar el material.');
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