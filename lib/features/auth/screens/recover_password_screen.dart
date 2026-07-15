import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import 'verificar_codigo_screen.dart';
import 'package:dio/dio.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviarInstrucciones() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final correo = _correoController.text.trim();

    try {
      await _api.post('/auth/recuperar', data: {
        'cedula': _cedulaController.text.trim(),
        'correo': correo,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Ir a la pantalla de ingresar código, pasando el correo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarCodigoScreen(correo: correo),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String mensaje = 'No se pudo procesar la solicitud. Intenta de nuevo.';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            mensaje = data['message'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),

              // Logo centrado
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 32),

              // Título
              const Text(
                'Recuperar Contraseña',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Introduce tu cédula y correo electrónico para recibir un código de recuperación',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Cédula de Identidad',
                      hint: 'Ej: 0912345678',
                      prefixIcon: Icons.badge_outlined,
                      controller: _cedulaController,
                      keyboardType: TextInputType.number,
                      validator: Validators.cedulaEcuatoriana,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Correo electrónico',
                      hint: 'ejemplo@correo.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.correo,
                    ),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: 'Enviar Código',
                      icon: Icons.send_rounded,
                      isLoading: _isLoading,
                      onPressed: _enviarInstrucciones,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Volver
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Volver al inicio de sesión',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
