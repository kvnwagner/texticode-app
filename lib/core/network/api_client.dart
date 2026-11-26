import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Error uniforme para respuestas de la API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// Cliente HTTP único para las rutas protegidas de Texticode.
/// La empresa nunca se envía desde el teléfono: vive dentro del JWT.
class ApiClient {
  ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'texticode_token';

  /// Tiempo máximo de espera para las peticiones.
  static const Duration _timeout = Duration(seconds: 20);

  /// Obtiene los encabezados de autenticación.
  static Future<Map<String, String>> headers({
    bool json = true,
  }) async {
    final token = await _storage.read(key: _tokenKey);

    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Construye la URL de la petición.
  static Uri uri(
    String path, {
    Map<String, String>? query,
  }) {
    if (ApiConstants.baseUrl.isEmpty) {
      throw const ApiException(
        'Falta configurar API_BASE_URL. '
        'Verifica la dirección del backend.',
      );
    }

    final baseUrl = ApiConstants.baseUrl.replaceAll(
      RegExp(r'/+$'),
      '',
    );

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$baseUrl$cleanPath').replace(
      queryParameters: query,
    );
  }

  /// Petición GET.
  static Future<dynamic> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return _send(
      () async => http.get(
        uri(path, query: query),
        headers: await headers(),
      ),
    );
  }

  /// Petición POST.
  static Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    return _send(
      () async => http.post(
        uri(path),
        headers: authenticated
            ? await headers()
            : const {'Content-Type': 'application/json'},
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  /// Petición PUT.
  static Future<dynamic> put(
    String path, {
    Object? body,
  }) async {
    return _send(
      () async => http.put(
        uri(path),
        headers: await headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  /// Petición PATCH.
  static Future<dynamic> patch(
    String path, {
    Object? body,
  }) async {
    return _send(
      () async => http.patch(
        uri(path),
        headers: await headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  /// Petición DELETE.
  static Future<dynamic> delete(String path) async {
    return _send(
      () async => http.delete(
        uri(path),
        headers: await headers(),
      ),
    );
  }

  /// Ejecuta las peticiones y controla sus respuestas.
  static Future<dynamic> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(_timeout);

      dynamic data;

      // Decodificar respuesta JSON.
      try {
        data = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      // Controlar códigos HTTP.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Error en el servidor.';

        if (data is Map) {
          message = data['error']?.toString() ??
              data['mensaje']?.toString() ??
              data['message']?.toString() ??
              message;
        }

        throw ApiException(
          message,
          statusCode: response.statusCode,
        );
      }

      return data;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respondió a tiempo. '
        'Verifica tu conexión y que el backend esté disponible.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Error de conexión con el servidor: ${e.message}',
      );
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió una respuesta con formato inválido.',
      );
    } catch (e) {
      throw ApiException(
        'Error inesperado al comunicarse con el servidor: $e',
      );
    }
  }
}
