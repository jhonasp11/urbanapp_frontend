import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/custom_button.dart';

class NuevaContrasenaScreen extends StatefulWidget {
  final String correo;
  final String codigo;
  const NuevaContrasenaScreen({
    super.key,
    required this.correo,
    required this.codigo,
  });

  @override
  State<NuevaContrasenaScreen> createState() => _NuevaContrasenaScreenState();
}

class _NuevaContrasenaScreenState extends State<NuevaContrasenaScreen> {
  final _api = ApiService();
  bool _isLoading = false;
  bool _verNueva = false;
  bool _verConfirmar = false;

  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool get _tieneMinimo => _nuevaCtrl.text.length >= 8;
  bool get _tieneNumero => _nuevaCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _tieneEspecial =>
      _nuevaCtrl.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _coinciden =>
      _confirmarCtrl.text.isNotEmpty && _nuevaCtrl.text == _confirmarCtrl.text;

  @override
  void initState() {
    super.initState();
    _nuevaCtrl.addListener(() => setState(() {}));
    _confirmarCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (_nuevaCtrl.text.isEmpty || _confirmarCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completa todos los campos'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (!_tieneMinimo || !_tieneNumero || !_tieneEspecial) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La contraseña no cumple los requisitos de seguridad'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (!_coinciden) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Las contraseñas no coinciden'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.post('/auth/restablecer', data: {
        'correo': widget.correo,
        'codigo': widget.codigo,
        'nueva_contrasena': _nuevaCtrl.text,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('¡Contraseña actualizada!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Ya puedes iniciar sesión con tu nueva contraseña.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Ir al inicio de sesión',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String mensaje = 'No se pudo actualizar la contraseña';
        try {
          final response = (e as dynamic).response?.data;
          if (response != null && response['message'] != null) {
            mensaje = response['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Widget _buildRequisito(String texto, bool cumple) {
    return Row(
      children: [
        Icon(
          cumple ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 16,
          color: cumple ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(texto,
            style: TextStyle(
                fontSize: 12,
                color: cumple ? AppColors.success : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCampoContrasena({
    required String label,
    required TextEditingController controller,
    required bool ver,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !ver,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppColors.textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                ver ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary)),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nueva Contraseña',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primary, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Crea una contraseña nueva y segura\npara proteger tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCampoContrasena(
                    label: 'Nueva Contraseña',
                    controller: _nuevaCtrl,
                    ver: _verNueva,
                    onToggle: () => setState(() => _verNueva = !_verNueva),
                  ),
                  const SizedBox(height: 16),
                  _buildCampoContrasena(
                    label: 'Confirmar Nueva Contraseña',
                    controller: _confirmarCtrl,
                    ver: _verConfirmar,
                    onToggle: () =>
                        setState(() => _verConfirmar = !_verConfirmar),
                  ),
                  const SizedBox(height: 20),
                  const Text('REQUISITOS DE SEGURIDAD',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  _buildRequisito('Mínimo 8 caracteres', _tieneMinimo),
                  const SizedBox(height: 4),
                  _buildRequisito('Al menos un número (0-9)', _tieneNumero),
                  const SizedBox(height: 4),
                  _buildRequisito(
                      'Un carácter especial (!@#\$%)', _tieneEspecial),
                  const SizedBox(height: 4),
                  _buildRequisito('Las contraseñas coinciden', _coinciden),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Restablecer Contraseña',
              icon: Icons.check_rounded,
              isLoading: _isLoading,
              onPressed: _restablecer,
            ),
          ],
        ),
      ),
    );
  }
}
