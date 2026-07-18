import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'package:dio/dio.dart';

class AdminDetallePagoScreen extends StatefulWidget {
  final Map<String, dynamic> pago;
  final VoidCallback onActualizado;

  const AdminDetallePagoScreen({
    super.key,
    required this.pago,
    required this.onActualizado,
  });

  @override
  State<AdminDetallePagoScreen> createState() => _AdminDetallePagoScreenState();
}

class _AdminDetallePagoScreenState extends State<AdminDetallePagoScreen> {
  bool _procesando = false;

  Future<String> _obtenerAdminId() async {
    const storage = FlutterSecureStorage();
    final api = ApiService();
    final userId = await storage.read(key: 'usuario_id') ?? '';
    try {
      final res = await api.get('/usuarios/$userId');
      return res.data['administrador']?['id'] ?? '';
    } catch (_) {
      return '';
    }
  }

  String _formatFecha(String? isoStr) {
    if (isoStr == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _verComprobante(BuildContext context) {
    final comprobante = (widget.pago['comprobante_url'] ?? '').toString();
    final formato = (widget.pago['formato_archivo'] ?? 'img').toString();

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

  Future<void> _aprobar(BuildContext context) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    final api = ApiService();
    final adminId = await _obtenerAdminId();
    final residente = widget.pago['residente'] ?? {};
    final usuarioId = residente['usuario_id'] ?? '';
    try {
      await api.patch('/pagos/${widget.pago['id']}/validar', data: {
        'estado': 'aprobado',
        'validado_por': adminId,
      });
      try {
        await api.post('/notificaciones', data: {
          'usuario_id': usuarioId,
          'tipo': 'sistema',
          'titulo': 'Pago aprobado',
          'mensaje': 'Tu pago ha sido aprobado y registrado correctamente.',
        });
      } catch (_) {}
      widget.onActualizado();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminPagoExitosoScreen(),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _procesando = false);
      if (!context.mounted) return;
      String mensaje = 'Error al aprobar el pago';
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
  }

  Future<void> _mostrarModalRechazo(BuildContext context) async {
    final motivoCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_outlined,
                    color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('¿Rechazar Pago?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('El residente será notificado del rechazo.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('MOTIVO DEL RECHAZO',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: motivoCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Ej. Comprobante ilegible, monto incorrecto...',
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (motivoCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Debes ingresar el motivo'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    if (motivoCtrl.text.trim().length < 10) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'El motivo debe tener al menos 10 caracteres'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Confirmar Rechazo',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true) return;
    if (_procesando) return;
    setState(() => _procesando = true);

    final api = ApiService();
    final adminId = await _obtenerAdminId();
    final residente = widget.pago['residente'] ?? {};
    final usuarioId = residente['usuario_id'] ?? '';
    try {
      await api.patch('/pagos/${widget.pago['id']}/validar', data: {
        'estado': 'rechazado',
        'validado_por': adminId,
        'observacion_admin': motivoCtrl.text.trim(),
      });
      try {
        await api.post('/notificaciones', data: {
          'usuario_id': usuarioId,
          'tipo': 'sistema',
          'titulo': 'Pago rechazado',
          'mensaje':
              'Tu pago ha sido rechazado. Motivo: ${motivoCtrl.text.trim()}',
        });
      } catch (_) {}
      widget.onActualizado();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago rechazado correctamente'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _procesando = false);
      if (!context.mounted) return;
      String mensaje = 'Error al rechazar el pago';
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
  }

  Widget _buildCampo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _mesesDePago() {
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

    // Obtener los meses (números) desde las alícuotas pagadas
    final pagosAlicuotas = widget.pago['pagos_alicuotas'] as List? ?? [];
    final numerosMes = <int>[];
    for (final pa in pagosAlicuotas) {
      final alic = pa['alicuota'] ?? {};
      final m = alic['mes'];
      if (m is int && m >= 1 && m <= 12) {
        numerosMes.add(m);
      }
    }

    if (numerosMes.isNotEmpty) {
      numerosMes.sort();
      return numerosMes.map((m) => nombresMes[m]).join(' - ');
    }

    // Respaldo: usar mes_pago del propio pago
    final mesPago = widget.pago['mes_pago'];
    if (mesPago is int && mesPago >= 1 && mesPago <= 12) {
      return nombresMes[mesPago];
    }

    return 'No especificado';
  }

  String _formatFechaCorta(dynamic isoStr) {
    if (isoStr == null) return '';
    final s = isoStr.toString();
    if (s.length < 10) return '';
    try {
      final dt = DateTime.parse(s);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Color _colorEstadoPago(String estado) {
    switch (estado) {
      case 'aprobado':
        return AppColors.success;
      case 'rechazado':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  String _labelEstadoPago(String estado) {
    switch (estado) {
      case 'aprobado':
        return 'APROBADO';
      case 'rechazado':
        return 'RECHAZADO';
      default:
        return 'PENDIENTE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final residente = widget.pago['residente'] ?? {};
    final usuario = residente['usuario'] ?? {};
    final nombres = usuario['nombres'] ?? '';
    final apellidos = usuario['apellidos'] ?? '';
    final manzana = residente['manzana'] ?? '';
    final villa = residente['villa'] ?? '';
    final fotoUrl = (residente['foto_url'] ?? '').toString();
    final monto =
        double.tryParse((widget.pago['monto_pagado'] ?? 0).toString()) ?? 0.0;
    final observacion = widget.pago['observacion_residente'] ?? '';
    final metodo = widget.pago['metodo_pago'] ?? '';
    final banco = widget.pago['banco'] ?? '';
    final tipo = widget.pago['tipo_pago'] ?? 'alicuota';
    final esReserva = tipo == 'reserva';
    final estado = (widget.pago['estado'] ?? 'pendiente').toString();
    final esPendiente = estado == 'pendiente';

    // Para alícuota: construir el/los mes(es) que paga
    final mesesPagados = _mesesDePago();

    // Para reserva: fecha y horario
    final reserva = widget.pago['reserva'] ?? {};
    final fechaReserva = _formatFechaCorta(reserva['fecha_reserva']);
    final horaInicio = (reserva['hora_inicio'] ?? '').toString().length >= 16
        ? (reserva['hora_inicio']).toString().substring(11, 16)
        : '';
    final horaFin = (reserva['hora_fin'] ?? '').toString().length >= 16
        ? (reserva['hora_fin']).toString().substring(11, 16)
        : '';

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
        title: const Text('Validar Pago',
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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                    child: fotoUrl.isEmpty
                        ? Text(
                            nombres.isNotEmpty ? nombres[0].toUpperCase() : 'R',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$nombres $apellidos',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('Mz $manzana - Villa $villa',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _colorEstadoPago(estado).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_labelEstadoPago(estado),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _colorEstadoPago(estado))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  _buildCampo('TIPO DE PAGO',
                      esReserva ? 'Reserva Área Social' : 'Alícuota'),
                  _buildCampo('MONTO', '\$${monto.toStringAsFixed(2)}'),
                  if (esReserva) ...[
                    if (fechaReserva.isNotEmpty)
                      _buildCampo('FECHA DE RESERVA', fechaReserva),
                    if (horaInicio.isNotEmpty)
                      _buildCampo('HORARIO', '$horaInicio - $horaFin'),
                  ] else
                    _buildCampo(
                        mesesPagados.contains('-')
                            ? 'MESES QUE PAGA'
                            : 'MES QUE PAGA',
                        mesesPagados),
                  _buildCampo('FECHA Y HORA DE ENVÍO',
                      _formatFecha(widget.pago['fecha_envio'])),
                  if (metodo.isNotEmpty) _buildCampo('MÉTODO', metodo),
                  if (banco.isNotEmpty) _buildCampo('BANCO', banco),
                  if (observacion.isNotEmpty)
                    _buildCampo('OBSERVACIONES', observacion),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _verComprobante(context),
                icon: const Icon(Icons.visibility_outlined,
                    color: AppColors.primary),
                label: const Text('Visualizar Comprobante',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!esPendiente &&
                (widget.pago['observacion_admin'] ?? '')
                    .toString()
                    .isNotEmpty) ...[
              _buildCampo('OBSERVACIÓN DEL ADMIN',
                  widget.pago['observacion_admin'].toString()),
              const SizedBox(height: 4),
            ],
            if (esPendiente)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _procesando ? null : () => _aprobar(context),
                      icon: _procesando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Aprobar Pago',
                          style: TextStyle(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _procesando
                          ? null
                          : () => _mostrarModalRechazo(context),
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.error),
                      label: const Text('Rechazar',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class AdminPagoExitosoScreen extends StatelessWidget {
  const AdminPagoExitosoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Pago Aprobado con Éxito',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success)),
              const SizedBox(height: 8),
              const Text(
                  'El pago ha sido validado y registrado correctamente en el sistema.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Volver al Listado',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
