import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'reservas_comprobante_screen.dart';
import 'package:dio/dio.dart';

class ReservasDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> reserva;
  final String residenteId;
  const ReservasDetalleScreen({
    super.key,
    required this.reserva,
    required this.residenteId,
  });

  @override
  State<ReservasDetalleScreen> createState() => _ReservasDetalleScreenState();
}

class _ReservasDetalleScreenState extends State<ReservasDetalleScreen> {
  final _api = ApiService();
  bool _cancelando = false;

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return AppColors.success;
      case 'pendiente':
        return Colors.orange;
      case 'pendiente_pago':
        return const Color(0xFFE8830C);
      case 'completada':
        return AppColors.primary;
      case 'cancelada':
        return Colors.grey;
      case 'denegada':
        return AppColors.error;
      case 'expirada':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return 'APROBADA';
      case 'pendiente':
        return 'PENDIENTE';
      case 'pendiente_pago':
        return 'PENDIENTE DE PAGO';
      case 'completada':
        return 'COMPLETADA';
      case 'cancelada':
        return 'CANCELADA';
      case 'denegada':
        return 'RECHAZADA';
      case 'expirada':
        return 'EXPIRADA';
      default:
        return estado.toUpperCase();
    }
  }

  Future<void> _cancelarReserva() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text(
            'La reserva será cancelada. Esta acción no se puede deshacer. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _cancelando = true);
    try {
      await _api.patch(
          '${ApiConstants.reservas}/${widget.reserva['id']}/cancelar',
          data: {'residente_id': widget.reserva['residente_id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada exitosamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al cancelar la reserva';
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
      }
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  void _irAPagar() {
    final area = widget.reserva['area'] ?? {};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservasComprobanteScreen(
          reserva: widget.reserva,
          area: area,
          residenteId: widget.residenteId,
        ),
      ),
    );
  }

  void _verComprobante(String url, String formato) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta reserva no tiene comprobante'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (formato == 'pdf') {
      _abrirEnNavegador(url);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirEnNavegador(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el comprobante'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.reserva['area'] ?? {};
    final nombreArea = area['nombre'] ?? 'Area Social';
    final estado = widget.reserva['estado'] ?? '';
    final fecha =
        widget.reserva['fecha_reserva']?.toString().substring(0, 10) ?? '';
    final horaInicio =
        widget.reserva['hora_inicio']?.toString().substring(11, 16) ?? '';
    final horaFin =
        widget.reserva['hora_fin']?.toString().substring(11, 16) ?? '';
    final residente = widget.reserva['residente'] ?? {};
    final nombreResidente =
        '${residente['usuario']?['nombres'] ?? ''} ${residente['usuario']?['apellidos'] ?? ''}'
            .trim();
    final observacionAdmin =
        widget.reserva['observacion_admin']?.toString() ?? '';

    // Comprobante (para reservas de salón ya pagadas)
    final pagos = widget.reserva['pagos'] as List? ?? [];
    final ultimoPago = pagos.isNotEmpty ? pagos.first : null;
    final comprobanteUrl = (ultimoPago?['comprobante_url'] ?? '').toString();
    final formatoComprobante =
        (ultimoPago?['formato_archivo'] ?? 'img').toString();

    final esPorPagar = estado == 'pendiente_pago';
    final esExpirada = estado == 'expirada';
    final tienePago = pagos.isNotEmpty;
    final puedeCancel = !tienePago &&
        (estado == 'confirmada' ||
            estado == 'pendiente_pago' ||
            estado == 'pendiente');

    String duracion = '';
    try {
      final ini = DateTime.parse(widget.reserva['hora_inicio']);
      final fin = DateTime.parse(widget.reserva['hora_fin']);
      final horas = fin.difference(ini).inHours;
      duracion = '$horas ${horas == 1 ? 'Hora' : 'Horas'}';
    } catch (_) {}

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
        title: const Text('Detalle de Reserva',
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
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.sports_outlined,
                        color: Colors.white.withValues(alpha: 0.3), size: 64),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Text(nombreArea,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _colorEstado(estado),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_labelEstado(estado),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'FECHA',
                    valor: fecha,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.person_outline,
                    label: 'RESIDENTE',
                    valor: nombreResidente.isNotEmpty
                        ? nombreResidente
                        : 'Residente',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time_outlined,
                    label: 'HORARIO',
                    valor: '$horaInicio - $horaFin',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.timer_outlined,
                    label: 'TIEMPO',
                    valor: duracion,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mensaje para reserva EXPIRADA
            if (esExpirada) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.timer_off_outlined,
                        color: Colors.grey.shade600, size: 40),
                    const SizedBox(height: 12),
                    Text('Tu tiempo de reserva culminó',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text(
                      'No completaste el pago dentro del tiempo disponible, por lo que el horario fue liberado. Puedes crear una nueva reserva cuando gustes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Comprobante de pago (reservas de salón ya pagadas)
            if (comprobanteUrl.isNotEmpty && !esPorPagar) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('COMPROBANTE DE PAGO',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    _verComprobante(comprobanteUrl, formatoComprobante),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        formatoComprobante == 'pdf'
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formatoComprobante == 'pdf'
                              ? 'Comprobante en PDF'
                              : 'Comprobante (imagen)',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      const Icon(Icons.visibility_outlined,
                          color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Observación del admin cuando está denegada/cancelada
            if ((estado == 'cancelada' || estado == 'denegada') &&
                observacionAdmin.isNotEmpty) ...[
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
                        Icon(Icons.info_outline,
                            color: AppColors.error, size: 16),
                        SizedBox(width: 6),
                        Text('MOTIVO DE RECHAZO',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(observacionAdmin,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Botón PAGAR RESERVA (solo para pendiente_pago)
            if (esPorPagar) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _irAPagar,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Pagar Reserva'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8830C),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8830C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: Color(0xFFE8830C), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tienes un tiempo limitado para completar el pago. Si expira, el horario se liberará automáticamente.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFFB5670A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Botón CANCELAR (para estados cancelables)
            if (puedeCancel) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cancelando ? null : _cancelarReserva,
                  icon: _cancelando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar Reserva'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Podrás cancelar esta reserva hasta 2 horas antes del inicio del horario reservado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(valor,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
