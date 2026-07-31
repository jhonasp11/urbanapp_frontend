import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'package:dio/dio.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _api = ApiService();

  int _step = 1;
  String _rol = 'residente';
  bool _isLoading = false;
  bool _obscure = true;
  bool _aceptaTerminos = false;
  bool _aceptaPrivacidad = false;
  bool _registroExitoso = false;

  // Manzanas y villas desde la BD
  List<int> _manzanasDisponibles = [];
  List<int> _villasDisponibles = [];
  int? _manzanaSeleccionada;
  int? _villaSeleccionada;
  bool _cargandoManzanas = false;
  bool _cargandoVillas = false;

  // Validación del ID de administrador contra el padrón
  bool _adminValidado = false;
  bool _validandoAdmin = false;

  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _manzanaCtrl = TextEditingController();
  final _villaCtrl = TextEditingController();
  final _idAdminCtrl = TextEditingController();

  bool get _pass8 => _contrasenaCtrl.text.length >= 8;
  bool get _passNum => _contrasenaCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passEsp =>
      _contrasenaCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  // El usuario cumple todo el patrón: 6-12, empieza con letra, 1 mayúscula, 1 número, solo letras/números/_
  bool get _usuarioValido {
    final u = _usuarioCtrl.text.trim();
    return u.length >= 6 &&
        u.length <= 12 &&
        RegExp(r'^[a-zA-Z]').hasMatch(u) &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(u) &&
        u.contains(RegExp(r'[A-Z]')) &&
        u.contains(RegExp(r'[0-9]'));
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
    _manzanaCtrl.dispose();
    _villaCtrl.dispose();
    _idAdminCtrl.dispose();
    super.dispose();
  }

  Future<void> _validarAdmin() async {
    final id = _idAdminCtrl.text.trim();
    if (id.isEmpty) {
      _showSnack('Ingresa el ID de administrador', isError: true);
      return;
    }
    setState(() => _validandoAdmin = true);
    try {
      final res = await _api.get('/usuarios/validar-admin/$id');
      final data = res.data;
      if (data['valido'] == true) {
        if (!mounted) return;
        setState(() {
          _cedulaCtrl.text = (data['cedula'] ?? '').toString();
          _nombresCtrl.text = (data['nombres'] ?? '').toString();
          _apellidosCtrl.text = (data['apellidos'] ?? '').toString();
          _adminValidado = true;
          _validandoAdmin = false;
        });
        _showSnack('Administrador verificado correctamente');
      } else {
        if (!mounted) return;
        setState(() => _validandoAdmin = false);
        _showSnack((data['mensaje'] ?? 'ID no válido').toString(),
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _validandoAdmin = false);
      String mensaje = 'Error al validar el ID';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          mensaje = data['message'].toString();
        }
      }
      _showSnack(mensaje, isError: true);
    }
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
        'rol': _rol,
        'acepta_terminos': true,
        'acepta_privacidad': true,
        if (_rol == 'residente') ...{
          'manzana': _manzanaCtrl.text.trim(),
          'villa': _villaCtrl.text.trim(),
        },
        if (_rol == 'administrador')
          'id_administrador': _idAdminCtrl.text.trim(),
      };
      await _api.post(ApiConstants.registro, data: body);
      if (!mounted) return;
      setState(() => _registroExitoso = true);
    } catch (e) {
      String mensaje = 'Error al registrarse. Verifica los datos.';
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

  Future<void> _cargarManzanas() async {
    setState(() => _cargandoManzanas = true);
    try {
      final res = await _api.get('/manzanas/numeros');
      final lista = (res.data as List).map((e) => e as int).toList();
      if (!mounted) return;
      setState(() {
        _manzanasDisponibles = lista;
        _cargandoManzanas = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargandoManzanas = false);
    }
  }

  Future<void> _cargarVillas(int manzana) async {
    setState(() {
      _cargandoVillas = true;
      _villasDisponibles = [];
      _villaSeleccionada = null;
    });
    try {
      final res = await _api.get('/manzanas/numero/$manzana/villas');
      final lista = (res.data as List).map((e) => e as int).toList();
      if (!mounted) return;
      setState(() {
        _villasDisponibles = lista;
        _cargandoVillas = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargandoVillas = false);
    }
  }

  // Abre un selector con buscador para elegir de una lista de números
  Future<int?> _seleccionarConBuscador({
    required String titulo,
    required List<int> opciones,
    required String prefijo,
  }) async {
    final controller = TextEditingController();
    List<int> filtradas = List.from(opciones);

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar número...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                  onChanged: (v) {
                    setModalState(() {
                      if (v.trim().isEmpty) {
                        filtradas = List.from(opciones);
                      } else {
                        filtradas = opciones
                            .where((n) => n.toString().contains(v.trim()))
                            .toList();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtradas.isEmpty
                    ? const Center(
                        child: Text('Sin resultados',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtradas.length,
                        itemBuilder: (ctx, i) {
                          final n = filtradas[i];
                          return InkWell(
                            onTap: () => Navigator.pop(ctx, n),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(
                                child: Text('$prefijo $n',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // Abre el PDF del documento (terminos_condiciones o politica_privacidad)
  Future<void> _abrirDocumento(String tipo) async {
    try {
      final res = await _api.get('/documentos-publico/tipo/$tipo');
      final url = (res.data['archivo_url'] ?? '').toString();
      if (url.isEmpty) {
        _showSnack('El documento no está disponible por ahora', isError: true);
        return;
      }
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        _showSnack('No se pudo abrir el documento', isError: true);
      }
    } catch (e) {
      _showSnack('El documento no está disponible por ahora', isError: true);
    }
  }

  Widget _buildRolSelector() {
    final roles = [
      {'key': 'residente', 'label': 'Residente', 'icon': Icons.home_outlined},
      {
        'key': 'administrador',
        'label': 'Admin',
        'icon': Icons.admin_panel_settings_outlined
      },
    ];
    return Row(
      children: roles.map((r) {
        final isSelected = _rol == r['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _rol = r['key'] as String;
              // Resetear validación de admin al cambiar de rol
              _adminValidado = false;
              _cedulaCtrl.clear();
              _nombresCtrl.clear();
              _apellidosCtrl.clear();
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(r['icon'] as IconData,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 22),
                  const SizedBox(height: 4),
                  Text(r['label'] as String,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRolBadge() {
    final Map<String, Map<String, dynamic>> info = {
      'residente': {'label': 'Residente', 'icon': Icons.home_outlined},
      'administrador': {
        'label': 'Administrador',
        'icon': Icons.admin_panel_settings_outlined
      },
    };
    final r = info[_rol]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(r['icon'] as IconData, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(r['label'] as String,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline, color: AppColors.primary, size: 14),
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
                  const Text('Crear Cuenta',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Tipo de Usuario',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              if (_step == 1) _buildRolSelector() else _buildRolBadge(),
              const SizedBox(height: 20),
              // Indicador de pasos
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
    final esAdmin = _rol == 'administrador';
    // Para admin, los campos de identidad se muestran solo tras validar el ID
    final mostrarCampos = !esAdmin || _adminValidado;
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          if (esAdmin) ...[
            CustomTextField(
              label: 'ID de Administrador',
              hint: 'Ej. ADM-001',
              prefixIcon: Icons.admin_panel_settings_outlined,
              controller: _idAdminCtrl,
              validator: (v) => Validators.requerido(v, 'ID de Administrador'),
              enabled: !_adminValidado,
            ),
            const SizedBox(height: 12),
            if (!_adminValidado)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _validandoAdmin ? null : _validarAdmin,
                  icon: _validandoAdmin
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: Text(_validandoAdmin ? 'Validando...' : 'Validar ID'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            if (_adminValidado)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Administrador verificado',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
          ],
          if (mostrarCampos) ...[
            CustomTextField(
              label: 'Cédula',
              hint: '0999999999',
              prefixIcon: Icons.badge_outlined,
              controller: _cedulaCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.cedulaEcuatoriana,
              enabled: !esAdmin,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Nombres',
              hint: 'Escriba sus nombres',
              prefixIcon: Icons.person_outline,
              controller: _nombresCtrl,
              validator: (v) => Validators.nombreValido(v, 'Nombres'),
              enabled: !esAdmin,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Apellidos',
              hint: 'Escriba sus apellidos',
              prefixIcon: Icons.person_outline,
              controller: _apellidosCtrl,
              validator: (v) => Validators.nombreValido(v, 'Apellidos'),
              enabled: !esAdmin,
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
          ],
          CustomButton(
            text: 'Siguiente',
            isLoading: _isLoading,
            onPressed: () async {
              // Para admin, exigir que el ID haya sido validado
              if (_rol == 'administrador' && !_adminValidado) {
                _showSnack('Primero valida el ID de administrador',
                    isError: true);
                return;
              }
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
                if (_rol == 'residente') _cargarManzanas();
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
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Volver al Inicio de Sesión',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
            ),
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
          if (_rol == 'residente') ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Manzana',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _cargandoManzanas
                            ? null
                            : () async {
                                final sel = await _seleccionarConBuscador(
                                  titulo: 'Selecciona la manzana',
                                  opciones: _manzanasDisponibles,
                                  prefijo: 'Mz',
                                );
                                if (sel != null) {
                                  setState(() {
                                    _manzanaSeleccionada = sel;
                                    _manzanaCtrl.text = sel.toString();
                                  });
                                  _cargarVillas(sel);
                                }
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.home_outlined,
                                  color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _cargandoManzanas
                                      ? 'Cargando...'
                                      : (_manzanaSeleccionada == null
                                          ? 'Elige'
                                          : 'Mz $_manzanaSeleccionada'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _manzanaSeleccionada == null
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Villa',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: (_manzanaSeleccionada == null || _cargandoVillas)
                            ? null
                            : () async {
                                final sel = await _seleccionarConBuscador(
                                  titulo: 'Selecciona la villa',
                                  opciones: _villasDisponibles,
                                  prefijo: 'Villa',
                                );
                                if (sel != null) {
                                  setState(() {
                                    _villaSeleccionada = sel;
                                    _villaCtrl.text = sel.toString();
                                  });
                                }
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.house_outlined,
                                  color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _cargandoVillas
                                      ? 'Cargando...'
                                      : (_manzanaSeleccionada == null
                                          ? 'Elige Mz'
                                          : (_villaSeleccionada == null
                                              ? 'Elige'
                                              : 'Villa $_villaSeleccionada')),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _villaSeleccionada == null
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Validación visual de manzana/villa obligatorias
            if (_manzanaSeleccionada == null || _villaSeleccionada == null)
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 2),
                child: Text('Selecciona manzana y villa',
                    style: TextStyle(fontSize: 11, color: AppColors.error)),
              ),
            const SizedBox(height: 14),
          ],
          if (_rol == 'administrador') ...[
            CustomTextField(
              label: 'ID de Administrador',
              hint: 'Ej. ADM001',
              prefixIcon: Icons.admin_panel_settings_outlined,
              controller: _idAdminCtrl,
              validator: (v) => Validators.requerido(v, 'ID de Administrador'),
              enabled: false,
            ),
            const SizedBox(height: 14),
          ],
          CustomTextField(
            label: 'Usuario',
            hint: '6-12 caracteres, 1 mayúscula y 1 número',
            prefixIcon: Icons.person_outline,
            controller: _usuarioCtrl,
            inputFormatters: [UsuarioFormatter()],
            validator: Validators.usuario,
            onChanged: (_) => setState(() {}),
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
                _buildRequisito('Usuario válido', _usuarioValido),
                _buildRequisito('Mínimo 8 caracteres', _pass8),
                _buildRequisito('Al menos un número (0-9)', _passNum),
                _buildRequisito('Un carácter especial (!@#\$%)', _passEsp),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _aceptaTerminos = !_aceptaTerminos),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _aceptaTerminos,
                  onChanged: (v) =>
                      setState(() => _aceptaTerminos = v ?? false),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'Acepto los '),
                        TextSpan(
                            text: 'Términos y Condiciones',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  _abrirDocumento('terminos_condiciones')),
                        const TextSpan(text: ' de uso de la aplicación.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _aceptaPrivacidad = !_aceptaPrivacidad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _aceptaPrivacidad,
                  onChanged: (v) =>
                      setState(() => _aceptaPrivacidad = v ?? false),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'He leído y acepto la '),
                        TextSpan(
                            text: 'Política de Privacidad',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap =
                                  () => _abrirDocumento('politica_privacidad')),
                        const TextSpan(
                            text: ' para el tratamiento de mis datos.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Registrarse',
            isLoading: _isLoading,
            onPressed: () async {
              if (!_formKey2.currentState!.validate()) return;
              if (_rol == 'residente' &&
                  (_manzanaSeleccionada == null ||
                      _villaSeleccionada == null)) {
                _showSnack('Selecciona manzana y villa', isError: true);
                return;
              }
              if (!_aceptaTerminos || !_aceptaPrivacidad) {
                _showSnack(
                    'Debes aceptar los términos y la política de privacidad',
                    isError: true);
                return;
              }
              setState(() => _isLoading = true);
              try {
                await _api.post('/usuarios/verificar/paso2', data: {
                  'usuario': _usuarioCtrl.text.trim(),
                  'id_externo':
                      _rol == 'administrador' ? _idAdminCtrl.text.trim() : '',
                  'rol': _rol,
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
    final esPendiente = _rol == 'residente';
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
                    color: esPendiente
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    esPendiente
                        ? Icons.hourglass_top_rounded
                        : Icons.check_circle_rounded,
                    size: 44,
                    color: esPendiente ? AppColors.primary : AppColors.success,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  esPendiente
                      ? 'Solicitud de Registro Enviada'
                      : 'Registro Completado Exitosamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: esPendiente ? AppColors.primary : AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  esPendiente
                      ? 'Tu cuenta ha sido registrada con éxito y actualmente se encuentra en proceso de revisión.\n\nPor favor, espera la aprobación del administrador para poder acceder a todas las funcionalidades.'
                      : 'Tu cuenta ha sido creada con éxito y ya puedes acceder al portal.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Volver al Inicio',
                  icon: Icons.home_outlined,
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
