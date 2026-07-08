import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'reservas_nueva_screen.dart';
import 'reservas_historial_screen.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  List _areas = [];
  bool _loading = true;
  String _userId = '';
  String _residenteId = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final residenteId = await _storage.read(key: 'residente_id') ?? '';
      final res = await _api.get(ApiConstants.areasSociales);
      if (!mounted) return;
      setState(() {
        _userId = userId;
        _residenteId = residenteId;
        _areas = res.data as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconArea(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('basket')) return Icons.sports_basketball_outlined;
    if (n.contains('futbol') || n.contains('fútbol')) {
      return Icons.sports_soccer_outlined;
    }
    return Icons.event_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Módulo de Reservas',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Áreas Sociales',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Container(
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
                      child: _areas.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No hay áreas disponibles',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _areas.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: AppColors.border),
                              itemBuilder: (context, index) {
                                final area = _areas[index];
                                final nombre = area['nombre'] ?? '';
                                final precioRaw = area['tarifa_reserva'] ??
                                    area['precio_reserva'];
                                final precioValor = double.tryParse(
                                        (precioRaw ?? 0).toString()) ??
                                    0.0;
                                final tienePrecio = precioValor > 0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(_iconArea(nombre),
                                            color: AppColors.primary, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(nombre,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.textPrimary)),
                                            if (tienePrecio)
                                              Text(
                                                'Valor de Reserva: \$${precioValor.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary),
                                              ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ReservasNuevaScreen(
                                              area: area,
                                              residenteId: _residenteId,
                                            ),
                                          ),
                                        ).then((_) => _cargar()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                        ),
                                        child: const Text('Reservar',
                                            style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Historial de Reservas',
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
                            builder: (_) => ReservasHistorialScreen(
                                residenteId: _residenteId),
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
                        child: const Text('Consulta tu Historial de Reservas',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
