import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';

/// Habla con /api/orden-material — la tabla intermedia orden_material
/// que permite asociar VARIOS materiales a una misma orden
/// (orden_produccion.Id_Material sigue siendo una FK NOT NULL única,
/// así que esto es lo que se usa para el resto de materiales elegidos
/// en NewOrderSheet).
class OrdenMaterialRepository {
  /// Agrega un material a una orden ya creada.
  /// POST /api/orden-material — { Id_Orden, Id_Producto, Cantidad_Usada }
  Future<void> agregarMaterial({
    required int idOrden,
    required int idProducto,
    required int cantidadUsada,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.ordenMaterial),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Orden': idOrden,
        'Id_Producto': idProducto,
        'Cantidad_Usada': cantidadUsada,
      }),
    );
    if (res.statusCode != 201) {
      final body = _tryDecode(res.body);
      // El backend responde 409 si ese material ya estaba en la orden.
      throw Exception(body?['error'] ?? 'No se pudo agregar el material a la orden.');
    }
  }

  /// Materiales ya asociados a una orden (con su Cantidad_Usada).
  /// GET /api/orden-material/orden/:idOrden
  Future<List<Map<String, dynamic>>> getMaterialesDeOrden(int idOrden) async {
    final res = await http.get(Uri.parse('${ApiConstants.ordenMaterial}/orden/$idOrden'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('No se pudieron cargar los materiales de la orden.');
  }

  /// PUT /api/orden-material/:idOrden/:idProducto
  Future<void> actualizarCantidad({
    required int idOrden,
    required int idProducto,
    required int cantidadUsada,
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.ordenMaterial}/$idOrden/$idProducto'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Cantidad_Usada': cantidadUsada}),
    );
    if (res.statusCode != 200) {
      throw Exception('No se pudo actualizar la cantidad del material.');
    }
  }

  /// DELETE /api/orden-material/:idOrden/:idProducto
  Future<void> eliminarMaterial({required int idOrden, required int idProducto}) async {
    final res =
        await http.delete(Uri.parse('${ApiConstants.ordenMaterial}/$idOrden/$idProducto'));
    if (res.statusCode != 200) {
      throw Exception('No se pudo quitar el material de la orden.');
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