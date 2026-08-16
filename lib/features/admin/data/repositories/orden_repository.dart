import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/orden_model.dart';

/// Habla directo con tu backend Express (ordenes.js), que a su vez
/// habla con Supabase. Ningún dato se guarda localmente: todo viene
/// y va en tiempo real contra la base de datos real.
/// Mismo patrón exacto que usuario_repository.dart.
class OrdenRepository {
  Future<List<Orden>> getOrdenes() async {
    final res = await http.get(Uri.parse(ApiConstants.ordenes));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Orden.fromJson(e)).toList();
    }
    throw Exception('No se pudieron cargar las órdenes (${res.statusCode}).');
  }

  Future<Orden> getOrden(int id) async {
    final res = await http.get(Uri.parse('${ApiConstants.ordenes}/$id'));
    if (res.statusCode == 200) return Orden.fromJson(jsonDecode(res.body));
    throw Exception('Orden no encontrada.');
  }

  Future<void> crearOrden({
    required int idCliente,
    required String producto,
    String? descripcion,
    required List<String> materiales,
    required int cantidadTotal,
    required int idOperario,
    required String prioridad,
    required String fechaLimite, // yyyy-mm-dd
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.ordenes),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Cliente': idCliente,
        'Producto': producto,
        'Descripcion': descripcion,
        'Materiales': materiales,
        'Cantidad_Total': cantidadTotal,
        'Cantidad_Actual': 0,
        'Id_Operario': idOperario,
        'Prioridad': prioridad,
        'Estado': 'Pendiente',
        'Fecha_Limite': fechaLimite,
      }),
    );
    if (res.statusCode != 201) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo crear la orden.');
    }
  }

  Future<void> actualizarOrden({
    required int id,
    required int idCliente,
    required String producto,
    String? descripcion,
    required List<String> materiales,
    required int cantidadTotal,
    required int cantidadActual,
    required int idOperario,
    required String prioridad,
    required String estado,
    required String fechaLimite,
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.ordenes}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Cliente': idCliente,
        'Producto': producto,
        'Descripcion': descripcion,
        'Materiales': materiales,
        'Cantidad_Total': cantidadTotal,
        'Cantidad_Actual': cantidadActual,
        'Id_Operario': idOperario,
        'Prioridad': prioridad,
        'Estado': estado,
        'Fecha_Limite': fechaLimite,
      }),
    );
    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo actualizar la orden.');
    }
  }

  /// Usado por el selector rápido de estado dentro de cada card.
  Future<void> actualizarEstado(int id, String estado) async {
    final res = await http.patch(
      Uri.parse('${ApiConstants.ordenes}/$id/estado'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Estado': estado}),
    );
    if (res.statusCode != 200) {
      throw Exception('No se pudo actualizar el estado de la orden.');
    }
  }

  Future<void> reportarAvance({
    required Orden orden,
    required int cantidadActual,
  }) async {
    final nuevaCantidad = cantidadActual.clamp(0, orden.cantidadTotal);
    await actualizarOrden(
      id: orden.idOrden,
      idCliente: orden.idCliente,
      producto: orden.producto,
      descripcion: orden.descripcion,
      materiales: orden.materiales,
      cantidadTotal: orden.cantidadTotal,
      cantidadActual: nuevaCantidad,
      idOperario: orden.idOperario,
      prioridad: orden.prioridad,
      estado:
          nuevaCantidad >= orden.cantidadTotal ? 'Completada' : 'En proceso',
      fechaLimite: orden.fechaLimite ?? '',
    );
  }

  /// Delete definitivo. Úsalo con cuidado.
  Future<void> eliminarOrden(int id) async {
    final res = await http.delete(Uri.parse('${ApiConstants.ordenes}/$id'));
    if (res.statusCode != 200) {
      throw Exception('No se pudo eliminar la orden.');
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
