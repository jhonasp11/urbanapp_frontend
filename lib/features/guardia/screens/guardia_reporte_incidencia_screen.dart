import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'package:dio/dio.dart';

class GuardiaReporteIncidenciaScreen extends StatefulWidget {
  final String guardiaId;
  final String bitacoraId;

  const GuardiaReporteIncidenciaScreen({
    super.key,
    required this.guardiaId,
    this.bitacoraId = '',
  });

  @override
  State<GuardiaReporteIncidenciaScreen> createState() =>
      _GuardiaReporteIncidenciaScreenState();
}

class _GuardiaReporteIncidenciaScreenState
    extends State<GuardiaReporteIncidenciaScreen> {
  final _api = ApiService();
  final _observacionesCtrl = TextEditingController();
  bool _isLoading = false;
  final DateTime _fechaHora = DateTime.now();

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    super.dispose();
  }

  String _formatFechaHora(DateTime dt) {
    final hora =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    final fecha =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    return '$hora - $fecha';
  }

  Future<void> _enviarReporte() async {
    if (_observacionesCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor describe las observaciones del incidente'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _api.post('/codigos-qr/reporte-incidencia', data: {
        'guardia_id': widget.guardiaId,
        'observacion_incidencia': _observacionesCtrl.text.trim(),
        'hora_ingreso': _fechaHora.toIso8601String(),
        'bitacora_id': widget.bitacoraId.isNotEmpty ? widget.bitacoraId : null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte de incidencia enviado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al enviar el reporte';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            mensaje = data['message'].toString();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Reporte de Incidencia',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Ícono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_outlined,
                  color: AppColors.error, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Reporte de Incidencia',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Límite de intentos alcanzado (3/3).',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Registre los detalles del incidente.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Fecha y hora
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_outlined,
                        color: AppColors.textSecondary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FECHA Y HORA DEL INCIDENTE',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(_formatFechaHora(_fechaHora),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Observaciones
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('OBSERVACIONES DEL INCIDENTE',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: _observacionesCtrl,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'Describa el comportamiento del visitante, el motivo de los fallos o cualquier detalle relevante para el equipo de seguridad...',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.primary)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _enviarReporte,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_isLoading ? 'Enviando...' : 'Enviar Reporte',
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
          ],
        ),
      ),
    );
  }
}
