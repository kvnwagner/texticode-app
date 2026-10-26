import '../../../../core/network/api_client.dart';

class SuperadminRepository {
  Future<List<Map<String, dynamic>>> empresas() async {
    final data = await ApiClient.get('/empresas');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> guardarEmpresa(
      {int? id, required Map<String, dynamic> data}) async {
    if (id == null) {
      await ApiClient.post('/empresas', body: data);
    } else {
      await ApiClient.put('/empresas/$id', body: data);
    }
  }

  Future<void> cambiarEmpresa(int id, {required bool activar}) => activar
      ? ApiClient.patch('/empresas/$id/activar')
      : ApiClient.delete('/empresas/$id');

  Future<List<Map<String, dynamic>>> administradores(int empresaId) async {
    final data = await ApiClient.get('/empresas/$empresaId/administradores');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> guardarAdministrador(
          int empresaId, int usuarioId, Map<String, dynamic> data) =>
      ApiClient.put('/empresas/$empresaId/administradores/$usuarioId',
          body: data);

  Future<void> cambiarAdministrador(int empresaId, int usuarioId,
          {required bool activar}) =>
      ApiClient.patch(
          '/empresas/$empresaId/administradores/$usuarioId/${activar ? 'activar' : 'inactivar'}');

  Future<List<Map<String, dynamic>>> roles() async {
    final data = await ApiClient.get('/superadmin/roles');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> guardarRol({int? id, required String nombre}) => id == null
      ? ApiClient.post('/superadmin/roles', body: {'Nombre_Rol': nombre})
      : ApiClient.put('/superadmin/roles/$id', body: {'Nombre_Rol': nombre});

  Future<void> cambiarRol(int id, {required bool activar}) => ApiClient.patch(
        '/superadmin/roles/$id/${activar ? 'activar' : 'desactivar'}',
      );
}
