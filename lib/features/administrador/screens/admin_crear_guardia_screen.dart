import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'package:dio/dio.dart';

class AdminCrearGuardiaScreen extends StatefulWidget {
  const AdminCrearGuardiaScreen({super.key});

  @override
  State<AdminCrearGuardiaScreen> createState() =>
      _AdminCrearGuardiaScreenState();
}

class _AdminCrearGuardiaScreenState extends State<AdminCrearGuardiaScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _api = ApiService();

  int _step = 1;
  bool _isLoading = false;
  bool _obscure = true;
  bool _registroExitoso = false;

  List _turnos = [];
  String? _turnoSeleccionado;

  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _idGuardiaCtrl = TextEditingController();

  bool get _pass8 => _contrasenaCtrl.text.length >= 8;
  bool get _passNum => _contrasenaCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passEsp =>
      _contrasenaCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  @override
  void initState() {
    super.initState();
    _cargarTurnos();
  }

  Future<void> _cargarTurnos() async {
    print('CARGANDO TURNOS...');
    try {
      final res = await _api.get('/usuarios/turnos/lista');
      print('TURNOS RESPONSE: ${res.data}');
      if (!mounted) return;
      setState(() => _turnos = res.data as List);
      print('TURNOS CARGADOS: ${_turnos.length}');
    } catch (e) {
      print('ERROR TURNOS: $e');
    }
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _usuarioCtrl.dispose();
    _contrasenaCtrl.dispose();
    _idGuardiaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    try {
      final body = {
        'cedula': _cedulaCtrl.text.trim(),
        'nombres': _nombresCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'usuario': _usuarioCtrl.text.trim(),
        'contrasena': _contrasenaCtrl.text,
        'rol': 'guardia',
        'acepta_terminos': true,
        'acepta_privacidad': true,
        'id_guardia': _idGuardiaCtrl.text.trim(),
        'turno_id': _turnoSeleccionado,
      };
      await _api.post(ApiConstants.registro, data: body);
      if (!mounted) return;
      setState(() => _registroExitoso = true);
    } catch (e) {
      String mensaje = 'Error al registrar al guardia. Verifica los datos.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          mensaje = data['message'].toString();
        }
      }
      if (mounted) _showSnack(mensaje, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  String _formatHoraTurno(dynamic hora) {
    if (hora == null) return '';
    final str = hora.toString();
    if (str.contains('T')) {
      try {
        final dt = DateTime.parse(str).toUtc();
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    if (str.length >= 5) return str.substring(0, 5);
    return str;
  }

  Widget _buildRequisito(String texto, bool cumple) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(cumple ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: cumple ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  fontSize: 12,
                  color: cumple ? AppColors.primary : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPasoBadge(int paso, String label) {
    final isActive = _step >= paso;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$paso',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.primary : AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_registroExitoso) return _buildExito();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_step == 2) {
                        setState(() => _step = 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  const Text('Crear Guardia',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security_outlined,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Guardia',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                    SizedBox(width: 8),
                    Icon(Icons.lock_outline,
                        color: AppColors.primary, size: 14),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildPasoBadge(1, 'Datos Personales'),
                  Expanded(
                      child: Container(height: 1, color: AppColors.border)),
                  _buildPasoBadge(2, 'Credenciales'),
                ],
              ),
              const SizedBox(height: 24),
              if (_step == 1) _buildPaso1() else _buildPaso2(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaso1() {
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          CustomTextField(
            label: 'Cédula',
            hint: '0999999999',
            prefixIcon: Icons.badge_outlined,
            controller: _cedulaCtrl,
            keyboardType: TextInputType.number,
            validator: Validators.cedulaEcuatoriana,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Nombres',
            hint: 'Escriba sus nombres',
            prefixIcon: Icons.person_outline,
            controller: _nombresCtrl,
            validator: (v) => Validators.requerido(v, 'Nombres'),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Apellidos',
            hint: 'Escriba sus apellidos',
            prefixIcon: Icons.person_outline,
            controller: _apellidosCtrl,
            validator: (v) => Validators.requerido(v, 'Apellidos'),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Correo',
            hint: 'usuario@correo.com',
            prefixIcon: Icons.mail_outline_rounded,
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.correo,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Teléfono',
            hint: '0999999999',
            prefixIcon: Icons.phone_outlined,
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            validator: (v) => Validators.requerido(v, 'Teléfono'),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Siguiente',
            isLoading: _isLoading,
            onPressed: () async {
              if (!_formKey1.currentState!.validate()) return;
              setState(() => _isLoading = true);
              try {
                await _api.post('/usuarios/verificar/paso1', data: {
                  'cedula': _cedulaCtrl.text.trim(),
                  'correo': _correoCtrl.text.trim(),
                  'telefono': _telefonoCtrl.text.trim(),
                });
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                  _step = 2;
                });
              } catch (e) {
                String mensaje = 'Error al verificar los datos';
                if (e is DioException && e.response?.data != null) {
                  final data = e.response!.data;
                  if (data is Map && data['message'] != null) {
                    mensaje = data['message'].toString();
                  }
                }
                if (mounted) {
                  setState(() => _isLoading = false);
                  _showSnack(mensaje, isError: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'ID de Guardia',
            hint: 'Ej. GRD001',
            prefixIcon: Icons.badge_outlined,
            controller: _idGuardiaCtrl,
            validator: (v) => Validators.requerido(v, 'ID de Guardia'),
          ),
          const SizedBox(height: 14),
          // Selector de turno
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TURNO',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    setState(() => _turnoSeleccionado = value),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (ctx) => _turnos
                    .map((turno) => PopupMenuItem<String>(
                          value: turno['id'].toString(),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.access_time_outlined,
                                    color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(turno['nombre'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  Text(
                                    '${_formatHoraTurno(turno['hora_inicio'])} - ${_formatHoraTurno(turno['hora_fin'])}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _turnoSeleccionado != null
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _turnoSeleccionado != null
                              ? (_turnos.firstWhere(
                                      (t) =>
                                          t['id'].toString() ==
                                          _turnoSeleccionado,
                                      orElse: () => {'nombre': ''})['nombre'] ??
                                  '')
                              : 'Selecciona el turno',
                          style: TextStyle(
                              fontSize: 14,
                              color: _turnoSeleccionado != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Usuario',
            hint: 'Nombre de usuario para iniciar sesión',
            prefixIcon: Icons.person_outline,
            controller: _usuarioCtrl,
            validator: (v) => Validators.requerido(v, 'Usuario'),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Contraseña',
            hint: 'Contraseña segura',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            controller: _contrasenaCtrl,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: Validators.contrasena,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REQUISITOS DE SEGURIDAD',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                _buildRequisito('Mínimo 8 caracteres', _pass8),
                _buildRequisito('Al menos un número (0-9)', _passNum),
                _buildRequisito('Un carácter especial (!@#\$%)', _passEsp),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Crear Guardia',
            isLoading: _isLoading,
            onPressed: () async {
              if (!_formKey2.currentState!.validate()) return;
              if (_turnoSeleccionado == null) {
                _showSnack('Selecciona un turno para el guardia',
                    isError: true);
                return;
              }
              setState(() => _isLoading = true);
              try {
                await _api.post('/usuarios/verificar/paso2', data: {
                  'usuario': _usuarioCtrl.text.trim(),
                  'id_externo': _idGuardiaCtrl.text.trim(),
                  'rol': 'guardia',
                });
                await _registrar();
              } catch (e) {
                String mensaje = 'Error al verificar los datos';
                if (e is DioException && e.response?.data != null) {
                  final data = e.response!.data;
                  if (data is Map && data['message'] != null) {
                    mensaje = data['message'].toString();
                  }
                }
                if (mounted) {
                  setState(() => _isLoading = false);
                  _showSnack(mensaje, isError: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExito() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 44, color: AppColors.success),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Guardia Creado Exitosamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success),
                ),
                const SizedBox(height: 16),
                const Text(
                  'El guardia ha sido registrado correctamente y ya puede acceder al sistema con sus credenciales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Volver al Inicio',
                  icon: Icons.home_outlined,
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/admin/home', (route) => false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
