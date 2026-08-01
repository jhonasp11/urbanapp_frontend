import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class EstadoCuentaScreen extends StatefulWidget {
  final String residenteId;
  final String? generadoPor;
  const EstadoCuentaScreen(
      {super.key, required this.residenteId, this.generadoPor});

  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _descargando = false;
  Map<String, dynamic>? _datos;
  int _anioSeleccionado = DateTime.now().year;

  final List<String> _meses = [
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

  late final List<int> _anios;

  @override
  void initState() {
    super.initState();
    final anioActual = DateTime.now().year;
    // Solo años hasta el actual (sin años futuros)
    _anios = [anioActual - 2, anioActual - 1, anioActual];
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get(
          '${ApiConstants.alicuotas}/residente/${widget.residenteId}/estado-cuenta?anio=$_anioSeleccionado&formato=json');
      if (!mounted) return;
      setState(() {
        _datos = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _descargarPdf() async {
    setState(() => _descargando = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token') ?? '';
      final generadoPorParam = widget.generadoPor != null
          ? '&generado_por=${widget.generadoPor}'
          : '';
      final url =
          '${ApiConstants.baseUrl}/alicuotas/residente/${widget.residenteId}/estado-cuenta?anio=$_anioSeleccionado&formato=pdf$generadoPorParam';

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/estado_cuenta_$_anioSeleccionado.pdf';

      await Dio().download(
        url,
        filePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el PDF'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  Color _colorEstado(String estado) =>
      estado == 'pagado' ? AppColors.success : Colors.orange;

  @override
  Widget build(BuildContext context) {
    final alicuotas = (_datos?['alicuotas'] as List?) ?? [];
    final pagadas = _datos?['pagadas'] ?? 0;
    final pendientes = _datos?['pendientes'] ?? 0;
    final totalPagado = _datos?['total_pagado'] ?? 0;
    final totalPendiente = _datos?['total_pendiente'] ?? 0;

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
        title: const Text('Estado de Cuenta',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filtro de año
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                const Text('Año:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _anioSeleccionado,
                      items: _anios
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text('$a',
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _anioSeleccionado = v);
                          _cargar();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Resumen
                        Row(
                          children: [
                            Expanded(
                              child: _tarjeta(
                                  'Pagadas',
                                  '$pagadas',
                                  AppColors.success,
                                  Icons.check_circle_outline),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _tarjeta('Pendientes', '$pendientes',
                                  Colors.orange, Icons.pending_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _tarjeta(
                                  'Total pagado',
                                  '\$${(totalPagado as num).toStringAsFixed(2)}',
                                  AppColors.success,
                                  Icons.paid_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _tarjeta(
                                  'Total pendiente',
                                  '\$${(totalPendiente as num).toStringAsFixed(2)}',
                                  Colors.orange,
                                  Icons.account_balance_wallet_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Text('Detalle de Alícuotas',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 12),

                        if (alicuotas.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'No hay alícuotas generadas para este año',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ...alicuotas.map((a) {
                            final mes = a['mes'] ?? 0;
                            final anio = a['anio'] ?? '';
                            final monto = (a['monto'] as num?) ?? 0;
                            final estado = a['estado'] ?? 'pendiente';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _colorEstado(estado)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      estado == 'pagado'
                                          ? Icons.check_circle_outline
                                          : Icons.pending_outlined,
                                      color: _colorEstado(estado),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${mes >= 1 && mes <= 12 ? _meses[mes] : ''} $anio',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary)),
                                        Text('\$${(monto).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _colorEstado(estado)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      estado == 'pagado'
                                          ? 'PAGADO'
                                          : 'PENDIENTE',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _colorEstado(estado)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),

          // Botón descargar PDF
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_descargando || alicuotas.isEmpty) ? null : _descargarPdf,
                icon: _descargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(
                    _descargando
                        ? 'Generando...'
                        : 'Descargar Estado de Cuenta',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(String label, String valor, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(valor,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
