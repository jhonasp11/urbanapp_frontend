import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

// Clave global de navegación, usada para redirigir al login ante un 401.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;
  bool _redirigiendo = false;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 solo se trata como "sesión caída" si había un token activo.
        // En el login (sin token) se deja pasar para que muestre su error.
        if (error.response?.statusCode == 401 && !_redirigiendo) {
          final token = await _storage.read(key: 'token');
          final esLogin =
              error.requestOptions.path.contains(ApiConstants.login);
          if (token != null && !esLogin) {
            _redirigiendo = true;
            await _storage.deleteAll();
            _mostrarAvisoYRedirigir();
          }
        }
        handler.next(error);
      },
    ));
  }

  void _mostrarAvisoYRedirigir() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      // Sin contexto: redirigir directo
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      _redirigiendo = false;
      return;
    }

    // Overlay gris con mensaje
    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text(
                    'Tu cuenta ha sido desactivada',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Redirigiéndote al inicio de sesión...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Tras 5 segundos: cerrar overlay y ir al login
    Future.delayed(const Duration(seconds: 5), () {
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      _redirigiendo = false;
    });
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _dio.delete(path, data: data);

  Future<Response> patchFile(String path, FormData formData) => _dio.patch(
        path,
        data: formData,
      );

  Future<Response> postFile(String path, FormData formData) => _dio.post(
        path,
        data: formData,
      );
}
