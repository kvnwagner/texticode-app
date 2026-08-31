import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/orden_model.dart';

/// Habla directo con tu backend Express (ordenes.js), que a su vez
/// habla con Supabase. Ningún dato se guarda localmente: todo viene
/// y va en tiempo real contra la base de datos real.
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

  /// Crea la orden y devuelve el Id_Orden que asigna el backend
  /// (POST /api/ordenes responde { mensaje, Id_Orden }).
  ///
  /// ⚠️ orden_produccion sigue exigiendo un único "Id_Material" (FK
  /// NOT NULL) — pásale el material "principal" de la orden. Si el
  /// formulario permite elegir varios materiales, usa el Id_Orden
  /// devuelto aquí para registrar el resto (y también ese principal,
  /// si quieres que quede reflejado ahí también) contra
  /// OrdenMaterialRepository.agregarMaterial — esa es la tabla
  /// intermedia (orden_material) que sí soporta múltiples materiales.
  Future<int> crearOrden({
    required int idCliente,
    required int idMaterial,
    required String producto,
    String? descripcion,
    required int cantidadTotal,
    required int idOperario,
    required String prioridad,
    required String fechaLimite,
    String dificultad = 'Media',
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.ordenes),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Cliente': idCliente,
        'Id_Material': idMaterial,
        'Id_Operario': idOperario,
        'Producto': producto,
        'Descripcion': descripcion,
        'Cantidad': cantidadTotal,
        'Prioridad': prioridad,
        'Fecha_Limite': fechaLimite,
        'Estado': 'En Proceso',
        'Dificultad': dificultad,
      }),
    );

    if (res.statusCode != 201) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo crear la orden.');
    }

    final body = _tryDecode(res.body);
    final idOrden = body?['Id_Orden'];
    if (idOrden == null) {
      throw Exception('La orden se creó pero el servidor no devolvió su Id_Orden.');
    }
    return idOrden is int ? idOrden : int.parse('$idOrden');
  }

  /// Actualiza una orden completa. El backend hace un UPDATE con TODOS
  /// estos campos (PUT reemplaza el registro entero), así que hay que
  /// mandar siempre el valor actual de cada uno — nunca un valor fijo —
  /// o se sobreescribe silenciosamente lo que ya estaba guardado.
  Future<void> actualizarOrden({
    required int id,
    required int idCliente,
    required int idMaterial,
    required String producto,
    String? descripcion,
    required int cantidadTotal,
    required int idOperario,
    required String prioridad,
    required String fechaLimite,
    required String estado,
    int? unidades,
    int? unidadesRealizadas,
    String dificultad = 'Media',
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.ordenes}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Cliente': idCliente,
        'Id_Material': idMaterial,
        'Id_Operario': idOperario,
        'Producto': producto,
        'Descripcion': descripcion,
        'Cantidad': cantidadTotal,
        'Prioridad': prioridad,
        'Fecha_Limite': fechaLimite,
        'Estado': estado,
        'Unidades': unidades,
        'Unidades_Realizadas': unidadesRealizadas,
        'Dificultad': dificultad,
      }),
    );

    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo actualizar la orden.');
    }
  }

  /// Usado por el selector rápido de estado dentro de cada card.
  /// Requiere que el backend tenga la ruta PATCH /api/ordenes/:id/estado
  /// (ver instrucciones para agregarla en ordenes.js).
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

  /// Reporta el avance total acumulado, conservando el resto de campos
  /// de la orden tal cual estaban (idMaterial, unidades, dificultad, etc.
  /// se toman del objeto `orden` que ya viene de un GET reciente).
  Future<void> reportarAvance({
    required Orden orden,
    required int cantidadActual,
  }) async {
    final nuevaCantidad = cantidadActual.clamp(0, orden.cantidadTotal).toInt();

    await actualizarOrden(
      id: orden.idOrden,
      idCliente: orden.idCliente,
      idMaterial: orden.idMaterial,
      producto: orden.producto,
      descripcion: orden.descripcion,
      cantidadTotal: orden.cantidadTotal,
      idOperario: orden.idOperario,
      prioridad: orden.prioridad,
      estado: nuevaCantidad >= orden.cantidadTotal ? 'Completada' : 'En Proceso',
      fechaLimite: orden.fechaLimite ?? '',
      unidades: orden.unidades,
      unidadesRealizadas: nuevaCantidad,
      dificultad: orden.dificultad,
    );
  }

  /// Suma las unidades reportadas EN ESTA SESIÓN al avance ya registrado.
  Future<void> reportarAvanceIncremental({
    required Orden orden,
    required int unidadesSesion,
  }) async {
    final nuevaCantidad =
        (orden.cantidadActual + unidadesSesion).clamp(0, orden.cantidadTotal).toInt();

    await reportarAvance(orden: orden, cantidadActual: nuevaCantidad);
  }

  /// Reasigna la orden a otro operario, conservando todo lo demás
  /// exactamente igual (cliente, material, cantidades, estado, etc.).
  /// Usado por ReassignOrdersView.
  Future<void> reasignarOperario({
    required Orden orden,
    required int nuevoIdOperario,
  }) async {
    await actualizarOrden(
      id: orden.idOrden,
      idCliente: orden.idCliente,
      idMaterial: orden.idMaterial,
      producto: orden.producto,
      descripcion: orden.descripcion,
      cantidadTotal: orden.cantidadTotal,
      idOperario: nuevoIdOperario,
      prioridad: orden.prioridad,
      estado: orden.estado,
      fechaLimite: orden.fechaLimite ?? '',
      unidades: orden.unidades,
      unidadesRealizadas: orden.cantidadActual,
      dificultad: orden.dificultad,
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