import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class PagosDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> pago;
  const PagosDetalleScreen({super.key, required this.pago});

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
        return 'PENDIENTE';
    }
  }

  String _formatFecha(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoStr.substring(0, 10);
    }
  }

  String _labelConcepto() {
    final tipo = pago['tipo_pago'] ?? '';
    if (tipo == 'reserva') return 'Reserva Área Social';
    final meses = pago['cantidad_meses'] ?? 1;
    return 'Alícuota - $meses ${meses == 1 ? 'mes' : 'meses'}';
  }

  void _verComprobante(BuildContext context) {
    final comprobante = (pago['comprobante_url'] ?? '').toString();
    final formato = (pago['formato_archivo'] ?? 'img').toString();

    if (comprobante.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este pago no tiene comprobante'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // PDF -> abrir en el visor externo del dispositivo
    if (formato == 'pdf') {
      _abrirEnNavegador(context, comprobante);
      return;
    }

    // Imagen -> mostrar dentro de la app con zoom
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
                  comprobante,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            color: Colors.white54, size: 48),
                        SizedBox(height: 12),
                        Text('No se pudo cargar la imagen',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
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

  Future<void> _abrirEnNavegador(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
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
    final estado = pago['estado'] ?? 'pendiente';
    final monto =
        double.tryParse((pago['monto_pagado'] ?? 0).toString()) ?? 0.0;
    final fecha = _formatFecha(pago['fecha_envio']);
    final metodo = pago['metodo_pago'] ?? '';
    final banco = pago['banco'] ?? '';
    final comprobanteUrl = pago['comprobante_url'] ?? '';
    final formato = (pago['formato_archivo'] ?? 'img').toString();
    final observacion = pago['observacion_residente'] ?? '';
    final observacionAdmin = pago['observacion_admin'] ?? '';

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
        title: const Text('Detalle de Pago',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _colorEstado(estado).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_labelEstado(estado),
                  style: TextStyle(
                      fontSize: 12,
                      color: _colorEstado(estado),
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            Text('\$${monto.toStringAsFixed(2)} USD',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              estado == 'aprobado'
                  ? 'Pago aprobado correctamente'
                  : estado == 'rechazado'
                      ? 'Pago rechazado'
                      : 'Pago en revisión',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
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
                  _buildFila('Fecha de envío', fecha),
                  _buildDivider(),
                  _buildFila('Concepto', _labelConcepto()),
                  _buildDivider(),
                  _buildFila('Método de pago',
                      metodo.isNotEmpty ? metodo : 'No especificado'),
                  _buildDivider(),
                  _buildFila(
                      'Banco', banco.isNotEmpty ? banco : 'No especificado'),
                  if (observacion.isNotEmpty) ...[
                    _buildDivider(),
                    _buildFila('Observación', observacion),
                  ],
                ],
              ),
            ),

            // Observación del admin si fue rechazado
            if (estado == 'rechazado' && observacionAdmin.isNotEmpty) ...[
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
            ],

            if (comprobanteUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('COMPROBANTE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _verComprobante(context),
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
                        formato == 'pdf'
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formato == 'pdf'
                                  ? 'Comprobante en PDF'
                                  : 'Comprobante (imagen)',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formato == 'pdf'
                                  ? 'Toca para abrir en el visor'
                                  : 'Toca para ver la imagen',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.visibility_outlined,
                          color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(valor,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: AppColors.border);
}
