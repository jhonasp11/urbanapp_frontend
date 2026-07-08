import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'pagos_detalle_screen.dart';

class PagosHistorialScreen extends StatefulWidget {
  final String userId;
  const PagosHistorialScreen({super.key, required this.userId});

  @override
  State<PagosHistorialScreen> createState() => _PagosHistorialScreenState();
}

class _PagosHistorialScreenState extends State<PagosHistorialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  List _pagos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final res =
          await _api.get('${ApiConstants.pagos}/residente/${widget.userId}');
      if (!mounted) return;
      setState(() {
        // Solo alícuotas: los pagos de reserva se ven en Historial de Reservas
        _pagos = (res.data as List)
            .where((p) => p['tipo_pago'] == 'alicuota')
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List _filtrarPorEstado(String estado) {
    if (estado == 'todos') return _pagos;
    return _pagos.where((p) => p['estado'] == estado).toList();
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return AppColors.success;
      case 'rechazado':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return 'APROBADO';
      case 'rechazado':
        return 'RECHAZADO';
      default:
        return 'EN REVISIÓN';
    }
  }

  String _labelConcepto(Map pago) {
    const nombresMes = [
      '',
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

    // Obtener los meses reales desde las alícuotas pagadas
    final pagosAlicuotas = pago['pagos_alicuotas'] as List? ?? [];
    final items = <Map<String, int>>[];
    for (final pa in pagosAlicuotas) {
      final alic = pa['alicuota'] ?? {};
      final m = alic['mes'];
      final a = alic['anio'];
      if (m is int && m >= 1 && m <= 12) {
        items.add({'mes': m, 'anio': a is int ? a : 0});
      }
    }

    if (items.isEmpty) {
      return 'Alícuota';
    }

    // Ordenar cronológicamente
    items.sort((x, y) {
      if (x['anio'] != y['anio']) return x['anio']!.compareTo(y['anio']!);
      return x['mes']!.compareTo(y['mes']!);
    });

    if (items.length == 1) {
      final it = items.first;
      return 'Alícuota - ${nombresMes[it['mes']!]} ${it['anio']}';
    }

    // Varios meses: "Alícuota - Mayo, Junio / 2026"
    final anio = items.last['anio'];
    final nombres = items.map((it) => nombresMes[it['mes']!]).join(', ');
    return 'Alícuota - $nombres / $anio';
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
        title: const Text('Historial de Pagos de Alícuotas',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobados'),
            Tab(text: 'Rechazados'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(_filtrarPorEstado('todos')),
                _buildLista(_filtrarPorEstado('pendiente')),
                _buildLista(_filtrarPorEstado('aprobado')),
                _buildLista(_filtrarPorEstado('rechazado')),
              ],
            ),
    );
  }

  Widget _buildLista(List pagos) {
    if (pagos.isEmpty) {
      return const Center(
        child: Text('No hay pagos registrados',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pagos.length,
        itemBuilder: (context, index) {
          final pago = pagos[index];
          final estado = pago['estado'] ?? 'pendiente';
          final monto =
              double.tryParse((pago['monto_pagado'] ?? 0).toString()) ?? 0.0;
          final concepto = _labelConcepto(pago);
          final fecha = pago['fecha_envio']?.toString().substring(0, 10) ?? '';

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PagosDetalleScreen(pago: pago)),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorEstado(estado),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(concepto,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        Text(fecha,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorEstado(estado).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_labelEstado(estado),
                            style: TextStyle(
                                fontSize: 10,
                                color: _colorEstado(estado),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.remove_red_eye_outlined,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
