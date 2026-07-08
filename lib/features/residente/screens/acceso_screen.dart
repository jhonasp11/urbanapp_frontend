import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'acceso_historial_screen.dart';
import 'acceso_qr_generado_screen.dart';

class AccesoScreen extends StatefulWidget {
  const AccesoScreen({super.key});

  @override
  State<AccesoScreen> createState() => _AccesoScreenState();
}

class _AccesoScreenState extends State<AccesoScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _cedulaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  String _userId = '';
  bool _isLoading = false;
  bool _loadingVisitantes = false;

  // 0 = selección modo, 1 = visitante guardado, 2 = nuevo visitante
  int _modo = 0;

  List _visitantes = [];
  Map<String, dynamic>? _visitanteSeleccionado;
  bool _guardarVisitante = false;

  DateTime? _fechaInicio;
  TimeOfDay? _horaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaFin;

  @override
  void initState() {
    super.initState();
    _cargarUserId();
  }

  Future<void> _cargarUserId() async {
    final residenteId = await _storage.read(key: 'residente_id') ?? '';
    setState(() => _userId = residenteId);
  }

  Future<void> _cargarVisitantes() async {
    setState(() => _loadingVisitantes = true);
    try {
      final res =
          await _api.get('${ApiConstants.visitantes}/residente/$_userId');
      if (!mounted) return;
      setState(() {
        _visitantes = res.data as List;
        _loadingVisitantes = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingVisitantes = false);
    }
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = hora;
        } else {
          _horaFin = hora;
        }
      });
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'dd/mm/yyyy';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String _formatHora(TimeOfDay? hora, BuildContext context) {
    if (hora == null) return '--:--';
    return hora.format(context);
  }

  void _resetFechas() {
    _fechaInicio = null;
    _horaInicio = null;
    _fechaFin = null;
    _horaFin = null;
  }

  Future<void> _generarQr({
    required String cedula,
    required String nombre,
    required String visitanteId,
  }) async {
    if (_fechaInicio == null || _horaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha y hora de inicio'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_fechaFin == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha y hora de fin'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fechaInicioCompleta = DateTime(
      _fechaInicio!.year,
      _fechaInicio!.month,
      _fechaInicio!.day,
      _horaInicio!.hour,
      _horaInicio!.minute,
    );
    final fechaFinCompleta = DateTime(
      _fechaFin!.year,
      _fechaFin!.month,
      _fechaFin!.day,
      _horaFin!.hour,
      _horaFin!.minute,
    );

    if (fechaFinCompleta.isBefore(fechaInicioCompleta) ||
        fechaFinCompleta.isAtSameMomentAs(fechaInicioCompleta)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha y hora de fin debe ser posterior al inicio'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final diffHoras = fechaFinCompleta.difference(fechaInicioCompleta).inHours;
    if (diffHoras > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El acceso no puede durar más de 24 horas'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fechaInicioStr =
          '${fechaInicioCompleta.year}-${_pad(fechaInicioCompleta.month)}-${_pad(fechaInicioCompleta.day)}T${_pad(fechaInicioCompleta.hour)}:${_pad(fechaInicioCompleta.minute)}:00';
      final fechaFinStr =
          '${fechaFinCompleta.year}-${_pad(fechaFinCompleta.month)}-${_pad(fechaFinCompleta.day)}T${_pad(fechaFinCompleta.hour)}:${_pad(fechaFinCompleta.minute)}:00';
      final fechaBaseStr =
          '${_fechaInicio!.year}-${_pad(_fechaInicio!.month)}-${_pad(_fechaInicio!.day)}T00:00:00';

      String idVisitante = visitanteId;

      // Si es nuevo visitante, crearlo primero
      if (visitanteId.isEmpty) {
        final fechaBaseStr =
            '${_fechaInicio!.year}-${_pad(_fechaInicio!.month)}-${_pad(_fechaInicio!.day)}T00:00:00';

        final resVisitante = await _api.post(ApiConstants.visitantes, data: {
          'residente_id': _userId,
          'nombre_visitante': nombre,
          'cedula_visitante': cedula,
          'fecha_visita': fechaBaseStr,
          'hora_estimada_ingreso':
              '${_pad(_horaInicio!.hour)}:${_pad(_horaInicio!.minute)}',
          'guardado': _guardarVisitante,
        });
        idVisitante = resVisitante.data['id'];
        print('VISITANTE ID: $idVisitante');
      }

      final resQr = await _api.post(ApiConstants.generarQr, data: {
        'visitante_id': idVisitante,
        'residente_id': _userId,
        'fecha_inicio': fechaInicioStr,
        'fecha_fin': fechaFinStr,
      });

      if (!mounted) return;

      final Map<String, dynamic> codigoData =
          Map<String, dynamic>.from(resQr.data);
      codigoData['visitante'] = {'nombre': nombre, 'cedula': cedula};
      codigoData['fecha_inicio'] = fechaInicioStr;
      codigoData['fecha_fin'] = fechaFinStr;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccesoQrGeneradoScreen(codigo: codigoData),
        ),
      );

      _cedulaCtrl.clear();
      _nombreCtrl.clear();
      setState(() {
        _resetFechas();
        _visitanteSeleccionado = null;
        _guardarVisitante = false;
        _modo = 0;
      });
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al generar el código QR';
        final errorStr = e.toString();
        if (errorStr.contains('400')) {
          if (errorStr.contains('24')) {
            mensaje = 'El acceso no puede durar más de 24 horas';
          } else if (errorStr.contains('activo')) {
            mensaje = 'Ya existe un código QR activo para este visitante';
          } else {
            mensaje = 'Datos inválidos, verifica la información ingresada';
          }
        } else if (errorStr.contains('500')) {
          mensaje = 'Error en el servidor, intenta nuevamente';
        }
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

  Widget _buildDateTimeRow({
    required String label,
    required DateTime? fecha,
    required TimeOfDay? hora,
    required bool esInicio,
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
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _seleccionarFecha(esInicio),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _formatFecha(fecha),
                        style: TextStyle(
                            fontSize: 13,
                            color: fecha != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _seleccionarHora(esInicio),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _formatHora(hora, context),
                        style: TextStyle(
                            fontSize: 13,
                            color: hora != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
        title: const Text('Módulo Control de Acceso',
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
            if (_modo == 0) _buildSeleccionModo(),
            if (_modo == 1) _buildVisitanteGuardado(),
            if (_modo == 2) _buildNuevoVisitante(),
            if (_modo == 0) ...[
              const SizedBox(height: 20),
              const Text('Historial de Accesos',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccesoHistorialScreen(userId: _userId),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Consulta tu Historial de Accesos',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeleccionModo() {
    return Container(
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
          const Text('Generar Acceso QR',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const Text('Crea accesos para tus visitantes',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          // Opción visitante guardado
          GestureDetector(
            onTap: () {
              setState(() => _modo = 1);
              _cargarVisitantes();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.people_outline,
                      color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visitante Guardado',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        Text('Selecciona un visitante frecuente',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Opción nuevo visitante
          GestureDetector(
            onTap: () => setState(() => _modo = 2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_add_outlined,
                      color: AppColors.textSecondary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nuevo Visitante',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('Ingresa los datos del visitante',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitanteGuardado() {
    return Container(
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
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _modo = 0;
                  _visitanteSeleccionado = null;
                  _resetFechas();
                }),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              const Text('Visitante Guardado',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingVisitantes)
            const Center(child: CircularProgressIndicator())
          else if (_visitantes.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No tienes visitantes guardados',
                      style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('Usa la opción Nuevo Visitante para agregar uno',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            )
          else if (_visitanteSeleccionado == null) ...[
            const Text('Selecciona un visitante',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ..._visitantes.map((v) {
              final nombre = v['nombre_visitante'] ?? '';
              final cedula = v['cedula_visitante'] ?? '';
              return GestureDetector(
                onTap: () => setState(() => _visitanteSeleccionado = v),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'V',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('CI: $cedula',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            // Visitante seleccionado — mostrar datos y fecha/hora
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (_visitanteSeleccionado!['nombre_visitante'] ?? '')
                              .isNotEmpty
                          ? _visitanteSeleccionado!['nombre_visitante'][0]
                              .toUpperCase()
                          : 'V',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _visitanteSeleccionado!['nombre_visitante'] ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          'CI: ${_visitanteSeleccionado!['cedula_visitante'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _visitanteSeleccionado = null),
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDateTimeRow(
              label: 'Fecha y Hora de Inicio',
              fecha: _fechaInicio,
              hora: _horaInicio,
              esInicio: true,
            ),
            const SizedBox(height: 12),
            _buildDateTimeRow(
              label: 'Fecha y Hora de Fin',
              fecha: _fechaFin,
              hora: _horaFin,
              esInicio: false,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Generar Código QR',
              icon: Icons.qr_code_2,
              isLoading: _isLoading,
              onPressed: () => _generarQr(
                cedula: _visitanteSeleccionado!['cedula_visitante'] ?? '',
                nombre: _visitanteSeleccionado!['nombre_visitante'] ?? '',
                visitanteId: _visitanteSeleccionado!['id'] ?? '',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNuevoVisitante() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _modo = 0;
                    _cedulaCtrl.clear();
                    _nombreCtrl.clear();
                    _guardarVisitante = false;
                    _resetFechas();
                  }),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                const Text('Nuevo Visitante',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Cédula del visitante',
              hint: '0999999999',
              prefixIcon: Icons.badge_outlined,
              controller: _cedulaCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'La cédula es requerida';
                if (v.length != 10) return 'La cédula debe tener 10 dígitos';
                final provincia = int.tryParse(v.substring(0, 2));
                if (provincia == null || provincia < 1 || provincia > 24) {
                  return 'Cédula inválida';
                }
                int suma = 0;
                for (int i = 0; i < 9; i++) {
                  int digito = int.parse(v[i]);
                  if (i % 2 == 0) {
                    digito *= 2;
                    if (digito > 9) digito -= 9;
                  }
                  suma += digito;
                }
                final verificador = (10 - (suma % 10)) % 10;
                if (verificador != int.parse(v[9])) {
                  return 'La cédula ingresada no es válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Nombre del visitante',
              hint: 'Nombre completo',
              prefixIcon: Icons.person_outline,
              controller: _nombreCtrl,
              validator: (v) =>
                  v == null || v.isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildDateTimeRow(
              label: 'Fecha y Hora de Inicio',
              fecha: _fechaInicio,
              hora: _horaInicio,
              esInicio: true,
            ),
            const SizedBox(height: 12),
            _buildDateTimeRow(
              label: 'Fecha y Hora de Fin',
              fecha: _fechaFin,
              hora: _horaFin,
              esInicio: false,
            ),
            const SizedBox(height: 16),
            // Opción guardar visitante
            GestureDetector(
              onTap: () =>
                  setState(() => _guardarVisitante = !_guardarVisitante),
              child: Row(
                children: [
                  Checkbox(
                    value: _guardarVisitante,
                    onChanged: (v) =>
                        setState(() => _guardarVisitante = v ?? false),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Guardar visitante para futuros accesos',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Generar Código QR',
              icon: Icons.qr_code_2,
              isLoading: _isLoading,
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                _generarQr(
                  cedula: _cedulaCtrl.text.trim(),
                  nombre: _nombreCtrl.text.trim(),
                  visitanteId: '',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
