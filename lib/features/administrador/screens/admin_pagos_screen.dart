import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'admin_pago_detalle_screen.dart';
import 'admin_pagos_validados_screen.dart';

class AdminPagosScreen extends StatefulWidget {
  const AdminPagosScreen({super.key});

  @override
  State<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends State<AdminPagosScreen> {
  final _api = ApiService();
  List _pagos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/pagos');
      final todos = res.data as List;
      if (!mounted) return;
      setState(() {
        _pagos = todos.where((p) => p['estado'] == 'pendiente').toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatFecha(String? isoStr) {
    if (isoStr == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
        automaticallyImplyLeading: false,
        title: const Text('Validar Pagos',
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
                            child: const Icon(Icons.payments_outlined,
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
                              Text('${_pagos.length} Pagos por Validar',
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
                          builder: (_) => const AdminPagosValidadosScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded,
                          size: 18, color: AppColors.primary),
                      label: const Text('Ver Pagos Validados',
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
                    if (_pagos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 48,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text('No hay pagos pendientes',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    else
                      ...(_pagos.map((pago) {
                        final residente = pago['residente'] ?? {};
                        final usuario = residente['usuario'] ?? {};
                        final nombres = usuario['nombres'] ?? '';
                        final apellidos = usuario['apellidos'] ?? '';
                        final manzana = residente['manzana'] ?? '';
                        final villa = residente['villa'] ?? '';
                        final fotoUrl =
                            (residente['foto_url'] ?? '').toString();
                        final monto = double.tryParse(
                                (pago['monto_pagado'] ?? 0).toString()) ??
                            0.0;
                        final fecha = _formatFecha(pago['fecha_envio']);
                        final tipo = pago['tipo_pago'] ?? 'alicuota';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminDetallePagoScreen(
                                  pago: pago,
                                  onActualizado: _cargar,
                                ),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
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
                                                fontSize: 18,
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text('$nombres $apellidos',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors
                                                          .textPrimary)),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text('PENDIENTE',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.orange)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('Mz $manzana - Villa $villa',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              tipo == 'reserva'
                                                  ? 'Reserva área social'
                                                  : 'Alícuota',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary),
                                            ),
                                            Text(
                                                '\$${monto.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary)),
                                          ],
                                        ),
                                        Text(fecha,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary),
                                ],
                              ),
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
