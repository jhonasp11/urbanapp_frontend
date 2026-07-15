import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'recover_password_screen.dart';
import '../../../core/services/notification_service.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _recordarme = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = await _authService.login(
        _usuarioController.text.trim(),
        _contrasenaController.text.trim(),
      );
      if (!mounted) return;
      final rol = data['rol'];
      final estado = data['estado'];

      if (estado == 'pendiente') {
        _showSnack('Tu cuenta está pendiente de aprobación.', isError: true);
        await _authService.logout();
        return;
      }

      // Inicializar notificaciones (sin bloquear el login si no hay conexión)
      try {
        await NotificationService()
            .initialize()
            .timeout(const Duration(seconds: 5));
      } catch (_) {}

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
          _showSnack('Rol no reconocido', isError: true);
      }
    } catch (e) {
      String mensaje = 'Usuario o contraseña incorrectos';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          mensaje = data['message'].toString();
        }
      }
      _showSnack(mensaje, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Urban App',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 28),

                        // Usuario
                        CustomTextField(
                          label: 'Usuario',
                          hint: 'Ingrese su Usuario',
                          prefixIcon: Icons.mail_outline_rounded,
                          controller: _usuarioController,
                          validator: (v) => v == null || v.isEmpty
                              ? 'El Usuario es requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        CustomTextField(
                          label: 'Contraseña',
                          hint: '**********',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          controller: _contrasenaController,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'La contraseña es requerida'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Recordarme + Olvidaste
                        Row(
                          children: [
                            Checkbox(
                              value: _recordarme,
                              onChanged: (v) =>
                                  setState(() => _recordarme = v ?? false),
                              activeColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text(
                              'Recordarme',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RecoverPasswordScreen(),
                                ),
                              ),
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Botón login
                        CustomButton(
                          text: 'Iniciar Sesión',
                          icon: Icons.login_rounded,
                          isLoading: _isLoading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 20),

                        // Registrarse
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿Aún no tienes cuenta? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/registro'),
                              child: const Text(
                                'Registrarse',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
