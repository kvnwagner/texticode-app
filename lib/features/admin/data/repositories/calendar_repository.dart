import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// Sincronización de órdenes con Google Calendar.
///
/// El teléfono NUNCA habla directo con la API de Google Calendar: solo
/// dispara la sincronización contra el backend (autenticado con el
/// mismo JWT que usa toda la app), y es el backend quien crea/actualiza
/// los eventos usando el refresh_token que guardó al vincular la
/// cuenta (ver GoogleAuthRepository / connect()). Esto evita manejar
/// credenciales de Google en el cliente y permite sincronizar aunque
/// el usuario haya iniciado sesión con usuario/contraseña en vez de
/// con Google.
class CalendarRepository {
  final AuthRepository _authRepo;

  CalendarRepository({AuthRepository? authRepo})
      : _authRepo = authRepo ?? AuthRepository();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authRepo.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/calendar/status
  /// Indica si el usuario actual ya vinculó Google Calendar.
  Future<CalendarStatus> getStatus() async {
    final res = await http.get(
      Uri.parse(ApiConstants.calendarStatus),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return CalendarStatus.fromJson(jsonDecode(res.body));
    }
    throw Exception('No se pudo consultar el estado de Google Calendar.');
  }

  /// POST /api/calendar/connect
  /// Vincula (o re-vincula) Google Calendar usando un serverAuthCode
  /// obtenido del SDK nativo de Google Sign-In (scope calendar.events).
  /// Útil cuando el usuario ya tenía sesión (login normal) y decide
  /// vincular Calendar después, desde el botón "Vincular con Google"
  /// de la pantalla de perfil.
  Future<void> connect(String serverAuthCode) async {
    final res = await http.post(
      Uri.parse(ApiConstants.calendarConnect),
      headers: await _authHeaders(),
      body: jsonEncode({'serverAuthCode': serverAuthCode}),
    );
    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);
      throw Exception(
          body?['error'] ?? 'No se pudo vincular Google Calendar.');
    }
  }

  /// DELETE /api/calendar/connect
  Future<void> disconnect() async {
    final res = await http.delete(
      Uri.parse(ApiConstants.calendarConnect),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('No se pudo desvincular Google Calendar.');
    }
  }

  /// POST /api/calendar/sync
  /// Sincroniza TODAS las órdenes visibles para el usuario actual
  /// (admin: todas; operario: las suyas; cliente: las suyas) como
  /// eventos en su Google Calendar, uno por cada Fecha_Limite de
  /// orden. Botón "Sincronizar Ahora" del perfil.
  Future<CalendarSyncResult> syncAllOrdenes() async {
    final res = await http.post(
      Uri.parse(ApiConstants.calendarSync),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return CalendarSyncResult.fromJson(jsonDecode(res.body));
    }
    final body = _tryDecode(res.body);
    throw Exception(
        body?['error'] ?? 'No se pudieron sincronizar las órdenes.');
  }

  /// POST /api/calendar/sync/:idOrden
  /// Sincroniza una sola orden (por ejemplo justo después de crearla
  /// o de cambiar su Fecha_Limite).
  Future<void> syncOrden(int idOrden) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.calendarSync}/$idOrden'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);
      throw Exception(body?['error'] ?? 'No se pudo sincronizar la orden.');
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

class CalendarStatus {
  final bool connected;
  final String? calendarEmail;

  CalendarStatus({required this.connected, this.calendarEmail});

  factory CalendarStatus.fromJson(Map<String, dynamic> json) {
    return CalendarStatus(
      connected: json['connected'] == true,
      calendarEmail: json['calendarEmail'] as String?,
    );
  }
}

class CalendarSyncResult {
  final int creados;
  final int actualizados;
  final int total;

  CalendarSyncResult({
    required this.creados,
    required this.actualizados,
    required this.total,
  });

  factory CalendarSyncResult.fromJson(Map<String, dynamic> json) {
    return CalendarSyncResult(
      creados: json['creados'] ?? 0,
      actualizados: json['actualizados'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}
