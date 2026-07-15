import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'package:dio/dio.dart';

class PerfilDatosScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const PerfilDatosScreen({super.key, required this.usuario});

  @override
  State<PerfilDatosScreen> createState() => _PerfilDatosScreenState();
}

class _PerfilDatosScreenState extends State<PerfilDatosScreen> {
  final _api = ApiService();
  bool _isLoading = false;

  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _manzanaCtrl;
  late final TextEditingController _villaCtrl;

  @override
  void initState() {
    super.initState();
    final residente = widget.usuario['residente'] ?? {};
    _cedulaCtrl =
        TextEditingController(text: widget.usuario['cedula']?.toString() ?? '');
    _nombresCtrl = TextEditingController(
        text: widget.usuario['nombres']?.toString() ?? '');
    _apellidosCtrl = TextEditingController(
        text: widget.usuario['apellidos']?.toString() ?? '');
    _correoCtrl =
        TextEditingController(text: widget.usuario['correo']?.toString() ?? '');
    _telefonoCtrl = TextEditingController(
        text: widget.usuario['telefono']?.toString() ?? '');
    _manzanaCtrl =
        TextEditingController(text: residente['manzana']?.toString() ?? '');
    _villaCtrl =
        TextEditingController(text: residente['villa']?.toString() ?? '');
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _manzanaCtrl.dispose();
    _villaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_correoCtrl.text.trim().isEmpty || _telefonoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_correoCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un correo electrónico válido'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!RegExp(r'^09[0-9]{8}$').hasMatch(_telefonoCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El teléfono debe tener 10 dígitos y comenzar con 09'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = widget.usuario['id'];
      await _api.patch('/usuarios/$userId', data: {
        'correo': _correoCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos actualizados exitosamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      String mensaje = 'Error al actualizar los datos';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          mensaje = data['message'].toString();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombres = widget.usuario['nombres'] ?? '';
    final fotoUrl = widget.usuario['residente']?['foto_url'] ?? '';

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
        title: const Text('Mis Datos Personales',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                child: fotoUrl.isEmpty
                    ? Text(
                        nombres.isNotEmpty ? nombres[0].toUpperCase() : 'R',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Residente',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
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
                children: [
                  CustomTextField(
                    label: 'Cédula de Identidad',
                    hint: '',
                    prefixIcon: Icons.badge_outlined,
                    controller: _cedulaCtrl,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Nombres',
                    hint: '',
                    prefixIcon: Icons.person_outline,
                    controller: _nombresCtrl,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Apellidos',
                    hint: '',
                    prefixIcon: Icons.person_outline,
                    controller: _apellidosCtrl,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Correo Electrónico',
                    hint: '',
                    prefixIcon: Icons.email_outlined,
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Teléfono',
                    hint: '',
                    prefixIcon: Icons.phone_outlined,
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Manzana',
                          hint: '',
                          prefixIcon: Icons.home_outlined,
                          controller: _manzanaCtrl,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Villa',
                          hint: '',
                          prefixIcon: Icons.villa_outlined,
                          controller: _villaCtrl,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Guardar Cambios',
              icon: Icons.save_outlined,
              isLoading: _isLoading,
              onPressed: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}
