import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';

class AuthService {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String usuario, String contrasena) async {
    try {
      final response = await _api.post(
        ApiConstants.login,
        data: {'usuario': usuario, 'contrasena': contrasena},
      );
      final data = response.data;
      await _storage.write(key: 'token', value: data['access_token']);
      await _storage.write(key: 'rol', value: data['rol']);
      await _storage.write(key: 'estado', value: data['estado']);
      await _storage.write(
          key: 'nombres', value: data['nombres']?.toString() ?? '');
      try {
        final parts = data['access_token'].toString().split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final Map<String, dynamic> payloadMap = json.decode(decoded);
          final userId = payloadMap['sub'].toString();
          await _storage.write(key: 'usuario_id', value: userId);
          try {
            final tempDio = Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              headers: {
                'Authorization': 'Bearer ${data['access_token']}',
                'Content-Type': 'application/json',
              },
            ));
            final resUser = await tempDio.get('/usuarios/$userId');
            final residenteId = resUser.data?['residente']?['id'];
            if (residenteId != null) {
              await _storage.write(
                  key: 'residente_id', value: residenteId.toString());
            }
          } catch (_) {}
        }
      } catch (_) {}
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Limpiar los datos de sesión del almacenamiento seguro
      // (token JWT, rol e identificadores del usuario)
      await _storage.deleteAll();
    } catch (e) {
      // Si el almacenamiento seguro falla al borrar, se registra el error
      // pero no se interrumpe el cierre de sesión: la app continúa al login.
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  Future<String?> getToken() => _storage.read(key: 'token');
  Future<String?> getRol() => _storage.read(key: 'rol');
}
