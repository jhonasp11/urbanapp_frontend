import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';

class AccesoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> codigo;
  const AccesoDetalleScreen({super.key, required this.codigo});

  @override
  State<AccesoDetalleScreen> createState() => _AccesoDetalleScreenState();
}

class _AccesoDetalleScreenState extends State<AccesoDetalleScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _compartiendo = false;
  String _nombreResidente = '';

  @override
  void initState() {
    super.initState();
    _cargarNombreResidente();
  }

  Future<void> _cargarNombreResidente() async {
    const storage = FlutterSecureStorage();
    final nombres = await storage.read(key: 'nombres') ?? '';
    final apellidos = await storage.read(key: 'apellidos') ?? '';
    setState(() => _nombreResidente = '$nombres $apellidos'.trim());
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'activo':
        return AppColors.success;
      case 'usado':
        return AppColors.primary;
      case 'expirado':
        return Colors.orange;
      case 'anulado':
        return AppColors.error;
      case 'bloqueado':
        return Colors.red.shade800;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _compartirQr() async {
    setState(() => _compartiendo = true);
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_acceso.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al compartir el código QR'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  Widget _buildFilaTarjeta(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          Text(valor,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitante = widget.codigo['visitante'] ?? {};
    final nombre = visitante['nombre_visitante'] ?? visitante['nombre'] ?? '';
    final cedula = visitante['cedula_visitante'] ?? visitante['cedula'] ?? '';
    final estado = widget.codigo['estado'] ?? 'activo';
    final fechaInicio = widget.codigo['fecha_inicio']
            ?.toString()
            .substring(0, 16)
            .replaceFirst('T', ' ') ??
        '';
    final fechaFin = widget.codigo['fecha_fin']
            ?.toString()
            .substring(0, 16)
            .replaceFirst('T', ' ') ??
        '';
    final qrData = widget.codigo['codigo_hash'] ??
        widget.codigo['codigo'] ??
        widget.codigo['id'] ??
        '';
    final esActivo = estado == 'activo';

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
        title: const Text('Detalle de Acceso Generado',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _colorEstado(estado).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _colorEstado(estado),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(estado.toUpperCase(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _colorEstado(estado))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta QR con diseño completo
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('C.I. $cedula',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ColorFiltered(
                      colorFilter: esActivo
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix([
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                      child: QrImageView(
                        data: qrData.isNotEmpty ? qrData : 'urbanapp-qr',
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wb_sunny_outlined,
                              color: Colors.amber, size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'No olvide subir al máximo el brillo de su celular',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.amber),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'VÁLIDO PARA UN INGRESO',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    _buildFilaTarjeta('DE', _nombreResidente),
                    _buildFilaTarjeta('DESDE', fechaInicio),
                    _buildFilaTarjeta('HASTA', fechaFin),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (esActivo) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _compartiendo ? null : _compartirQr,
                  icon: _compartiendo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share_outlined),
                  label: const Text('Compartir QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Este código QR es de un solo uso y caduca automáticamente a la hora indicada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_outlined,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este código QR ha sido $estado y no puede ser utilizado.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.error),
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
}
