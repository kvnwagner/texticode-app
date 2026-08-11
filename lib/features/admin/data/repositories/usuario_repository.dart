import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/usuario_model.dart';

/// Habla directo con tu backend Express (usuarios.js), que a su vez
/// habla con Supabase. Ningún dato se guarda localmente: todo viene
/// y va en tiempo real contra la base de datos real.
class UsuarioRepository {
  Future<List<Usuario>> getUsuarios() async {
    final res = await http.get(Uri.parse(ApiConstants.usuarios));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Usuario.fromJson(e)).toList();
    }
    throw Exception('No se pudieron cargar los usuarios (${res.statusCode}).');
  }

  Future<Usuario> getUsuario(int id) async {
    final res = await http.get(Uri.parse('${ApiConstants.usuarios}/$id'));
    if (res.statusCode == 200) return Usuario.fromJson(jsonDecode(res.body));
    throw Exception('Usuario no encontrado.');
  }

  Future<void> crearUsuario({
    required int idRol,
    required String nombreCompleto,
    required String nombreUsuario,
    required String contrasena,
    String? correo,
    String? telefono,
    String estado = 'activo',
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.usuarios),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Rol': idRol,
        'Nombre_Completo': nombreCompleto,
        'Nombre_Usuario': nombreUsuario,
        'Correo': correo,
        'Telefono': telefono,
        'Estado': estado,
        'Contrasena': contrasena,
      }),
    );
    if (res.statusCode != 201) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo crear el usuario.');
    }
  }

  Future<void> actualizarUsuario({
    required int id,
    required int idRol,
    required String nombreCompleto,
    required String nombreUsuario,
    String? correo,
    String? telefono,
    required String estado,
    String? contrasena, // deja null o vacío para NO cambiar la contraseña
  }) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.usuarios}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id_Rol': idRol,
        'Nombre_Completo': nombreCompleto,
        'Nombre_Usuario': nombreUsuario,
        'Correo': correo,
        'Telefono': telefono,
        'Estado': estado,
        'Contrasena': contrasena,
      }),
    );
    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo actualizar el usuario.');
    }
  }

  /// Soft delete: pone Estado = 'inactivo' (usa esto en vez de eliminar
  /// si quieres conservar historial, como en la mayoría de sistemas reales).
  Future<void> inactivarUsuario(int id) async {
    final res = await http.patch(Uri.parse('${ApiConstants.usuarios}/$id/inactivar'));
    if (res.statusCode != 200) {
      throw Exception('No se pudo inactivar el usuario.');
    }
  }

  /// Delete definitivo (DELETE FROM usuario ...). Úsalo con cuidado.
  Future<void> eliminarUsuario(int id) async {
    final res = await http.delete(Uri.parse('${ApiConstants.usuarios}/$id'));
    if (res.statusCode != 200) {
      throw Exception('No se pudo eliminar el usuario.');
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
