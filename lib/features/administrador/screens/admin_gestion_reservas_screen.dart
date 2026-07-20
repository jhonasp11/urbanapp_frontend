import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'admin_detalle_reserva_screen.dart';
import 'admin_reservas_validadas_screen.dart';

class AdminGestionReservasScreen extends StatefulWidget {
  const AdminGestionReservasScreen({super.key});

  @override
  State<AdminGestionReservasScreen> createState() =>
      _AdminGestionReservasScreenState();
}

class _AdminGestionReservasScreenState extends State<AdminGestionReservasScreen>
    with WidgetsBindingObserver {
  final _api = ApiService();
  List _reservas = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/reservas');
      final todas = res.data as List;
      if (!mounted) return;
      setState(() {
        _reservas = todas.where((r) {
          if (r['estado'] != 'pendiente') return false;
          final tarifa =
              double.tryParse((r['area']?['tarifa_reserva'] ?? 0).toString()) ??
                  0.0;
          return tarifa ==
              0; // solo áreas sin costo (las pagadas se validan en Pagos)
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatFecha(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatHora(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Gestión de Reservas',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sports_outlined,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PENDIENTES',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                              Text('${_reservas.length} Reservas por Confirmar',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminReservasValidadasScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded,
                          size: 18, color: AppColors.primary),
                      label: const Text('Ver Reservas Validadas',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_reservas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.sports_outlined,
                                size: 48,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text('No hay reservas pendientes',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    else
                      ...(_reservas.map((reserva) {
                        final residente = reserva['residente'] ?? {};
                        final usuario = residente['usuario'] ?? {};
                        final nombres = usuario['nombres'] ?? '';
                        final apellidos = usuario['apellidos'] ?? '';
                        final manzana = residente['manzana'] ?? '';
                        final villa = residente['villa'] ?? '';
                        final fotoUrl =
                            (residente['foto_url'] ?? '').toString();
                        final area = reserva['area'] ?? {};
                        final areaNombre = area['nombre'] ?? '';
                        final fecha = _formatFecha(reserva['fecha_reserva']);
                        final horaInicio = _formatHora(reserva['hora_inicio']);
                        final horaFin = _formatHora(reserva['hora_fin']);

                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminDetalleReservaScreen(
                                reserva: reserva,
                                onActualizado: _cargar,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      backgroundImage: fotoUrl.isNotEmpty
                                          ? NetworkImage(fotoUrl)
                                          : null,
                                      child: fotoUrl.isEmpty
                                          ? Text(
                                              nombres.isNotEmpty
                                                  ? nombres[0].toUpperCase()
                                                  : 'R',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('$nombres $apellidos',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      AppColors.textPrimary)),
                                          Text('Mz $manzana - Villa $villa',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('PENDIENTE',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.orange)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.sports_soccer_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(areaNombre,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(fecha,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.access_time_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text('$horaInicio - $horaFin',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Ver detalle',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
                                    SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppColors.primary, size: 16),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      })),
                  ],
                ),
              ),
            ),
    );
  }
}
