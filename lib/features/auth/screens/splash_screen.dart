import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _decidirRuta();
  }

  Future<void> _decidirRuta() async {
    // pequeña espera para mostrar el splash
    await Future.delayed(const Duration(milliseconds: 400));

    final token = await _storage.read(key: 'token');

    // Sin token o expirado -> limpiar y mandar al login
    if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
      await _storage.deleteAll();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      await NotificationService().initialize();
    } catch (_) {}

    final rol = await _storage.read(key: 'rol');
    if (!mounted) return;

    switch (rol) {
      case 'residente':
        Navigator.pushReplacementNamed(context, '/residente/home');
        break;
      case 'guardia':
        Navigator.pushReplacementNamed(context, '/guardia/home');
        break;
      case 'administrador':
        Navigator.pushReplacementNamed(context, '/admin/home');
        break;
      default:
        await _storage.deleteAll();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Urban App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
