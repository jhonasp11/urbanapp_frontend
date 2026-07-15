import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GuardiaIngresoDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> ingreso;
  const GuardiaIngresoDetalleScreen({super.key, required this.ingreso});

  String _formatHora(String? iso) {
    if (iso == null) return '--:--';
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '--:--';
    }
  }

  String _formatFecha(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreVisitante = ingreso['nombre_visitante'] ?? 'Visitante';
    final cedula = ingreso['cedula_visitante'] ?? 'No registrada';
    final nombreResidente = ingreso['nombre_residente'] ?? 'No registrado';
    final manzana = ingreso['manzana_destino'] ?? '';
    final villa = ingreso['villa_destino'] ?? '';
    final placa = (ingreso['placa_vehiculo'] ?? '').toString();
    final tipoIngreso = ingreso['tipo_ingreso'] ?? '';
    final estado = ingreso['estado'] ?? '';
    final hora = _formatHora(ingreso['hora_ingreso']);
    final fecha = _formatFecha(ingreso['hora_ingreso']);
    final observacion = (ingreso['observacion_incidencia'] ?? '').toString();
    final tieneIncidencia = observacion.isNotEmpty;

    final esDenegado = estado == 'denegado';
    final esManual = tipoIngreso == 'manual';

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
        title: const Text('Detalle de Ingreso',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Encabezado con estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: esDenegado
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: esDenegado
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      esDenegado
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                      color: esDenegado ? AppColors.error : AppColors.success,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    esDenegado ? 'Ingreso Denegado' : 'Ingreso Válido',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            esDenegado ? AppColors.error : AppColors.success),
                  ),
                  const SizedBox(height: 2),
                  Text(fecha,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Para denegado: mostrar solo la hora de incidencia
            if (esDenegado)
              Container(
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
                child: _buildFila(
                    Icons.access_time_outlined, 'Hora de incidencia', hora),
              ),

            // Datos del ingreso (solo si NO es denegado)
            if (!esDenegado)
              Container(
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
                child: Column(
                  children: [
                    _buildFila(
                        Icons.person_outline, 'Visitante', nombreVisitante),
                    _buildFila(Icons.badge_outlined, 'Cédula', cedula),
                    _buildFila(
                        Icons.people_outline, 'Residente', nombreResidente),
                    _buildFila(Icons.home_outlined, 'Dirección',
                        'Manzana $manzana, Villa $villa'),
                    _buildFila(Icons.directions_car_outlined, 'Placa',
                        placa.isNotEmpty ? placa : 'No registrada'),
                    _buildFila(
                        Icons.access_time_outlined, 'Hora de ingreso', hora),
                    _buildFila(
                        esManual
                            ? Icons.pan_tool_outlined
                            : Icons.qr_code_scanner_outlined,
                        'Tipo de ingreso',
                        esManual ? 'MANUAL' : 'AUTOMÁTICO'),
                    _buildFila(Icons.verified_outlined, 'Estado', 'VÁLIDO'),
                  ],
                ),
              ),

            // Incidencia (para denegados o ingresos con novedad)
            if (tieneIncidencia) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            color: AppColors.error, size: 16),
                        SizedBox(width: 6),
                        Text('INCIDENCIA REPORTADA',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(observacion,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4)),
                  ],
                ),
              ),
            ] else if (esDenegado) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block_outlined,
                        color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El ingreso fue denegado. No se registró información adicional del visitante.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFila(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(valor,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
