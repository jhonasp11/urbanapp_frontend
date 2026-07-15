import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'package:dio/dio.dart';

class GuardiaIngresoManualScreen extends StatefulWidget {
  final String guardiaId;
  final String bitacoraId;
  const GuardiaIngresoManualScreen({
    super.key,
    required this.guardiaId,
    this.bitacoraId = '',
  });

  @override
  State<GuardiaIngresoManualScreen> createState() =>
      _GuardiaIngresoManualScreenState();
}

class _GuardiaIngresoManualScreenState
    extends State<GuardiaIngresoManualScreen> {
  final _api = ApiService();
  bool _isLoading = false;
  bool _registrado = false;

  final _nombreVisitanteCtrl = TextEditingController();
  final _cedulaVisitanteCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _nombreResidenteCtrl = TextEditingController();
  final _manzanaCtrl = TextEditingController();
  final _villaCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreVisitanteCtrl.dispose();
    _cedulaVisitanteCtrl.dispose();
    _placaCtrl.dispose();
    _nombreResidenteCtrl.dispose();
    _manzanaCtrl.dispose();
    _villaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_nombreVisitanteCtrl.text.isEmpty ||
        _cedulaVisitanteCtrl.text.isEmpty ||
        _nombreResidenteCtrl.text.isEmpty ||
        _manzanaCtrl.text.isEmpty ||
        _villaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos requeridos'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validación cédula ecuatoriana
    final cedula = _cedulaVisitanteCtrl.text.trim();
    if (cedula.length != 10 || !RegExp(r'^\d{10}$').hasMatch(cedula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('La cédula debe tener exactamente 10 dígitos numéricos'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provincia = int.tryParse(cedula.substring(0, 2)) ?? 0;
    if (provincia < 1 || provincia > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cédula ingresada no es válida'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int suma = 0;
    for (int i = 0; i < 9; i++) {
      int digito = int.parse(cedula[i]);
      if (i % 2 == 0) {
        digito *= 2;
        if (digito > 9) digito -= 9;
      }
      suma += digito;
    }
    final verificador = (10 - (suma % 10)) % 10;
    if (verificador != int.parse(cedula[9])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cédula ingresada no es válida'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_placaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la placa del vehículo'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_placaCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La placa ingresada no es válida'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.post(ApiConstants.ingresoManual, data: {
        'guardia_id': widget.guardiaId,
        'bitacora_id': widget.bitacoraId.isNotEmpty ? widget.bitacoraId : null,
        'nombre_visitante': _nombreVisitanteCtrl.text.trim(),
        'cedula_visitante': _cedulaVisitanteCtrl.text.trim(),
        'placa_vehiculo': _placaCtrl.text.trim(),
        'nombre_residente': _nombreResidenteCtrl.text.trim(),
        'manzana_destino': _manzanaCtrl.text.trim(),
        'villa_destino': _villaCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _registrado = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al registrar el ingreso';
        if (e is DioException) {
          if (e.response?.statusCode == 404) {
            mensaje =
                'No se encontró coincidencia con los residentes registrados. Verifica la manzana y villa.';
          } else if (e.response?.data != null) {
            final data = e.response!.data;
            if (data is Map && data['message'] != null) {
              mensaje = data['message'].toString();
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_registrado) return _buildExito();

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
        title: const Text('Ingreso Manual de Visitante',
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
            const Text('DATOS DEL VISITANTE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
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
                    label: 'Nombre del visitante *',
                    hint: 'Nombre completo',
                    prefixIcon: Icons.person_outline,
                    controller: _nombreVisitanteCtrl,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Cédula del visitante *',
                    hint: '0999999999',
                    prefixIcon: Icons.badge_outlined,
                    controller: _cedulaVisitanteCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Placa del vehículo *',
                    hint: 'ABC-1234',
                    prefixIcon: Icons.directions_car_outlined,
                    controller: _placaCtrl,
                    inputFormatters: [PlacaFormatter()],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vehículos: ABC-1234 (con guión)  ·  Motos: AB123C (sin guión)',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('DATOS DEL RESIDENTE QUE VA A VISITAR',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
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
                    label: 'Nombre del residente *',
                    hint: 'Nombre completo',
                    prefixIcon: Icons.person_outline,
                    controller: _nombreResidenteCtrl,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Manzana *',
                          hint: 'Ej. 0000',
                          prefixIcon: Icons.home_outlined,
                          controller: _manzanaCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Villa *',
                          hint: 'Ej. 00',
                          prefixIcon: Icons.villa_outlined,
                          controller: _villaCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Confirmar Registro',
              icon: Icons.how_to_reg_outlined,
              isLoading: _isLoading,
              onPressed: _registrar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExito() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Ingreso Registrado Correctamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success)),
              const SizedBox(height: 8),
              const Text(
                  'El visitante ha sido registrado exitosamente de forma manual.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
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
                    _buildFila(Icons.person_outline, 'Visitante',
                        _nombreVisitanteCtrl.text),
                    _buildFila(Icons.badge_outlined, 'Cédula',
                        _cedulaVisitanteCtrl.text),
                    _buildFila(Icons.people_outline, 'Residente',
                        _nombreResidenteCtrl.text),
                    _buildFila(Icons.home_outlined, 'Dirección',
                        'Manzana ${_manzanaCtrl.text}, Villa ${_villaCtrl.text}'),
                    _buildFila(Icons.directions_car_outlined, 'Placa',
                        _placaCtrl.text),
                    _buildFila(Icons.login_outlined, 'Ingreso', 'MANUAL'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Finalizar',
                onPressed: () => Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFila(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(valor,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
