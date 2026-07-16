import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'urbanapp_channel',
        'UrbanApp Notificaciones',
        description: 'Notificaciones de UrbanApp',
        importance: Importance.high,
      ),
    );

    await _guardarToken();

    _messaging.onTokenRefresh.listen((token) async {
      await _actualizarToken(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _mostrarNotificacionLocal(message);
    });
  }

  Future<void> _guardarToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storage.write(key: 'fcm_token', value: token);
        await _actualizarToken(token);
      }
    } catch (_) {}
  }

  Future<void> _actualizarToken(String token) async {
    try {
      final userId = await _storage.read(key: 'usuario_id');
      if (userId != null) {
        await _api.patch('/usuarios/$userId', data: {'fcm_token': token});
      }
    } catch (_) {}
  }

  void _mostrarNotificacionLocal(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'urbanapp_channel',
          'UrbanApp Notificaciones',
          channelDescription: 'Notificaciones de UrbanApp',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'fcm_token');
  }
}
