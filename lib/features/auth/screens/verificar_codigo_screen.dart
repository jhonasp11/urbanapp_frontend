import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'nueva_contrasena_screen.dart';

class VerificarCodigoScreen extends StatefulWidget {
  final String correo;
  const VerificarCodigoScreen({super.key, required this.correo});

  @override
  State<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

class _VerificarCodigoScreenState extends State<VerificarCodigoScreen> {
  final _api = ApiService();
  final _codigoController = TextEditingController();
  bool _isLoading = false;
  bool _reenviando = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el código de 6 dígitos'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.post('/auth/verificar-codigo', data: {
        'correo': widget.correo,
        'codigo': codigo,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NuevaContrasenaScreen(
            correo: widget.correo,
            codigo: codigo,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código inválido o expirado'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reenviarCodigo() async {
    setState(() => _reenviando = true);
    try {
      // Nota: reenviar requiere cédula+correo. Como aquí solo tenemos el correo,
      // se le pide al usuario volver al paso anterior para reenviar.
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _reenviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Para reenviar el código, vuelve atrás e ingresa tus datos nuevamente.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ocultar parcialmente el correo para mostrarlo con privacidad
    final correoMostrado = _ofuscarCorreo(widget.correo);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: AppColors.primary, size: 40),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verificar Código',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código de 6 dígitos que enviamos a $correoMostrado',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Campo de código
              TextField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '––––––',
                  hintStyle: const TextStyle(
                    letterSpacing: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Verificar',
                isLoading: _isLoading,
                onPressed: _verificar,
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: _reenviando ? null : _reenviarCodigo,
                  child: Text(
                    _reenviando ? 'Enviando...' : '¿No recibiste el código?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ofuscarCorreo(String correo) {
    final partes = correo.split('@');
    if (partes.length != 2) return correo;
    final usuario = partes[0];
    if (usuario.length <= 2) return correo;
    final visible = usuario.substring(0, 2);
    return '$visible${'*' * (usuario.length - 2)}@${partes[1]}';
  }
}
