import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_constants.dart';

class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  final _api = ApiService();
  String _moduloSeleccionado = '';
  String _mesSeleccionado = '';
  Map<String, dynamic>? _datos;
  bool _loading = false;

  final List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  final List<Map<String, dynamic>> _modulos = [
    {
      'key': 'pagos',
      'titulo': 'Reporte de Pagos de Alícuotas',
      'descripcion': 'Recaudación, pagos al día, en deuda y pendientes.',
      'icono': Icons.receipt_outlined,
    },
    {
      'key': 'accesos',
      'titulo': 'Reporte de Acceso de Visitantes',
      'descripcion': 'Vehículos e ingresos validados y denegados.',
      'icono': Icons.people_outline,
    },
    {
      'key': 'reservas',
      'titulo': 'Reporte de Reservas de Áreas Sociales',
      'descripcion': 'Reservas por área social y su total.',
      'icono': Icons.calendar_today_outlined,
    },
    {
      'key': 'usuarios',
      'titulo': 'Reporte de Usuarios Registrados',
      'descripcion': 'Residentes, guardias y administradores del sistema.',
      'icono': Icons.groups_outlined,
    },
  ];

  Future<void> _cargarReporte() async {
    // Usuarios no requiere mes; los demás sí
    if (_moduloSeleccionado.isEmpty) return;
    if (_moduloSeleccionado != 'usuarios' && _mesSeleccionado.isEmpty) return;
    setState(() => _loading = true);
    try {
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'usuario_id') ?? '';
      String adminId = '';
      try {
        final resUser = await _api.get('/usuarios/$userId');
        adminId = resUser.data['administrador']?['id'] ?? '';
      } catch (_) {}

      final mes = _meses.indexOf(_mesSeleccionado) + 1;
      final anio = DateTime.now().year;

      String url;
      if (_moduloSeleccionado == 'usuarios') {
        url = '/reportes/usuarios?administrador_id=$adminId&formato=json';
      } else if (_moduloSeleccionado == 'accesos') {
        final fechaDesde = '$anio-${mes.toString().padLeft(2, '0')}-01';
        final ultimoDia = DateTime(anio, mes + 1, 0).day;
        final fechaHasta = '$anio-${mes.toString().padLeft(2, '0')}-$ultimoDia';
        url =
            '/reportes/accesos?fecha_desde=$fechaDesde&fecha_hasta=$fechaHasta&administrador_id=$adminId&formato=json';
      } else {
        url =
            '/reportes/$_moduloSeleccionado?mes=$mes&anio=$anio&administrador_id=$adminId&formato=json';
      }

      final res = await _api.get(url);
      if (!mounted) return;
      setState(() {
        _datos = res.data is Map ? res.data as Map<String, dynamic> : {};
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Reportes',
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
            // Filtros
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _moduloSeleccionado.isEmpty
                            ? null
                            : _moduloSeleccionado,
                        hint: const Text('Módulo',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                        isExpanded: true,
                        items: _modulos
                            .map((m) => DropdownMenuItem<String>(
                                  value: m['key'],
                                  child: Text(m['titulo'],
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _moduloSeleccionado = val ?? '';
                            _datos = null;
                          });
                          _cargarReporte();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _moduloSeleccionado == 'usuarios'
                          ? AppColors.background
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            _mesSeleccionado.isEmpty ? null : _mesSeleccionado,
                        hint: const Text('Mes',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                        isExpanded: true,
                        items: _meses
                            .map((m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(m,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        // Deshabilitado cuando el módulo es usuarios
                        onChanged: _moduloSeleccionado == 'usuarios'
                            ? null
                            : (val) {
                                setState(() {
                                  _mesSeleccionado = val ?? '';
                                  _datos = null;
                                });
                                _cargarReporte();
                              },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_moduloSeleccionado.isEmpty ||
                (_moduloSeleccionado != 'usuarios' &&
                    _mesSeleccionado.isEmpty)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecciona el módulo y el mes en la parte superior para generar el reporte.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Reportes Disponibles',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Estos son los reportes que puedes generar.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ..._modulos.map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(m['icono'],
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['titulo'],
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(m['descripcion'],
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_datos != null) ...[
              _buildResumen(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
    if (_moduloSeleccionado == 'pagos') return _buildResumenPagos();
    if (_moduloSeleccionado == 'accesos') return _buildResumenAccesos();
    if (_moduloSeleccionado == 'reservas') return _buildResumenReservas();
    if (_moduloSeleccionado == 'usuarios') return _buildResumenUsuarios();
    return const SizedBox();
  }

  Widget _buildResumenUsuarios() {
    final total = _datos?['total'] ?? 0;
    final residentes = _datos?['total_residentes'] ?? 0;
    final guardias = _datos?['total_guardias'] ?? 0;
    final administradores = _datos?['total_administradores'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen de Usuarios Registrados',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE USUARIOS REGISTRADOS', '$total',
            AppColors.primary, Icons.groups_outlined),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE RESIDENTES', '$residentes',
            AppColors.success, Icons.home_outlined),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE GUARDIAS', '$guardias', Colors.orange,
            Icons.security_outlined),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE ADMINISTRADORES', '$administradores',
            AppColors.textPrimary, Icons.admin_panel_settings_outlined),
        const SizedBox(height: 24),
        _buildBotonPDF(),
      ],
    );
  }

  Widget _buildResumenPagos() {
    final residentesAlDia = _datos?['residentes_al_dia'] ?? 0;
    final residentesEnDeuda = _datos?['residentes_en_deuda'] ?? 0;
    final alicuotasRecaudadas = _datos?['alicuotas_recaudadas'] ?? 0;
    final recaudado = _datos?['recaudado'] ?? 0;
    final alicuotasPendientes = _datos?['alicuotas_pendientes'] ?? 0;
    final pendiente = _datos?['pendiente'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen de Pagos — $_mesSeleccionado',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),

        // Residentes al día (centrado, ancho completo)
        _buildTarjetaCentrada('RESIDENTES AL DÍA', '$residentesAlDia',
            AppColors.success, Icons.verified_user_outlined),
        const SizedBox(height: 12),
        // Residentes que no han pagado (centrado, ancho completo)
        _buildTarjetaCentrada('RESIDENTES QUE NO HAN PAGADO',
            '$residentesEnDeuda', AppColors.error, Icons.person_off_outlined),
        const SizedBox(height: 12),

        // Alícuotas recaudadas + total
        _buildTarjetaReporte(
            'TOTAL DE ALÍCUOTAS RECAUDADAS',
            '$alicuotasRecaudadas',
            AppColors.primary,
            Icons.receipt_long_outlined,
            valorSecundario: '\$$recaudado'),
        const SizedBox(height: 12),
        // Alícuotas pendientes + total
        _buildTarjetaReporte(
            'TOTAL DE ALÍCUOTAS PENDIENTES DE PAGO',
            '$alicuotasPendientes',
            Colors.orange,
            Icons.pending_actions_outlined,
            valorSecundario: '\$$pendiente'),
        const SizedBox(height: 24),
        _buildBotonPDF(),
      ],
    );
  }

  Widget _buildResumenAccesos() {
    final totalVehiculos = _datos?['total_vehiculos'] ?? 0;
    final automaticos = _datos?['ingresos_automaticos'] ?? 0;
    final manuales = _datos?['ingresos_manuales'] ?? 0;
    final denegados = _datos?['ingresos_denegados'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen de Accesos — $_mesSeleccionado',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE VEHÍCULOS INGRESADOS', '$totalVehiculos',
            AppColors.primary, Icons.directions_car_outlined),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE INGRESOS AUTOMÁTICOS (QR)',
            '$automaticos', AppColors.success, Icons.qr_code_scanner_outlined),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE INGRESOS MANUALES', '$manuales',
            Colors.orange, Icons.pan_tool_outlined),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL DE INGRESOS DENEGADOS', '$denegados',
            AppColors.error, Icons.block_outlined),
        const SizedBox(height: 24),
        _buildBotonPDF(),
      ],
    );
  }

  Widget _buildResumenReservas() {
    final total = _datos?['total'] ?? 0;
    final futbol = _datos?['futbol'] ?? 0;
    final basket = _datos?['basket'] ?? 0;
    final eventos = _datos?['eventos'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen de Reservas — $_mesSeleccionado',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildTarjetaReporte('TOTAL RESERVAS', '$total', AppColors.primary,
            Icons.calendar_today_outlined),
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
              _buildFilaReserva('Fútbol', '$futbol', Icons.sports_soccer),
              const Divider(height: 16),
              _buildFilaReserva('Básquet', '$basket', Icons.sports_basketball),
              const Divider(height: 16),
              _buildFilaReserva(
                  'Área de Eventos', '$eventos', Icons.celebration_outlined),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildBotonPDF(),
      ],
    );
  }

  Widget _buildFilaReserva(String nombre, String cantidad, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(nombre,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ),
        Text(cantidad,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildTarjetaCentrada(
      String titulo, String valor, Color color, IconData icono) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(valor,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaReporte(
      String titulo, String valor, Color color, IconData icono,
      {String? valorSecundario}) {
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(valor,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
          ),
          if (valorSecundario != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(valorSecundario,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBotonPDF() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final storage = const FlutterSecureStorage();
          final userId = await storage.read(key: 'usuario_id') ?? '';
          final token = await storage.read(key: 'token') ?? '';
          String adminId = '';
          try {
            final resUser = await _api.get('/usuarios/$userId');
            adminId = resUser.data['administrador']?['id'] ?? '';
          } catch (_) {}

          final mes = _meses.indexOf(_mesSeleccionado) + 1;
          final anio = DateTime.now().year;

          String url;
          if (_moduloSeleccionado == 'usuarios') {
            url =
                '${ApiConstants.baseUrl}/reportes/usuarios?administrador_id=$adminId&formato=pdf';
          } else if (_moduloSeleccionado == 'accesos') {
            final fechaDesde = '$anio-${mes.toString().padLeft(2, '0')}-01';
            final ultimoDia = DateTime(anio, mes + 1, 0).day;
            final fechaHasta =
                '$anio-${mes.toString().padLeft(2, '0')}-$ultimoDia';
            url =
                '${ApiConstants.baseUrl}/reportes/accesos?fecha_desde=$fechaDesde&fecha_hasta=$fechaHasta&administrador_id=$adminId&formato=pdf';
          } else {
            url =
                '${ApiConstants.baseUrl}/reportes/$_moduloSeleccionado?mes=$mes&anio=$anio&administrador_id=$adminId&formato=pdf';
          }

          // Descargar PDF con dio y guardarlo
          try {
            final dir = await getApplicationDocumentsDirectory();
            final filePath = _moduloSeleccionado == 'usuarios'
                ? '${dir.path}/reporte_usuarios.pdf'
                : '${dir.path}/reporte_${_moduloSeleccionado}_$mes-$anio.pdf';

            await Dio().download(
              url,
              filePath,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );

            final result = await OpenFilex.open(filePath);
            if (result.type != ResultType.done) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo abrir el PDF'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Descargar Reporte PDF',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
