import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';

class AccesoQrGeneradoScreen extends StatefulWidget {
  final Map<String, dynamic> codigo;
  const AccesoQrGeneradoScreen({super.key, required this.codigo});

  @override
  State<AccesoQrGeneradoScreen> createState() => _AccesoQrGeneradoScreenState();
}

class _AccesoQrGeneradoScreenState extends State<AccesoQrGeneradoScreen> {
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
    final nombre = visitante['nombre'] ?? '';
    final cedula = visitante['cedula'] ?? '';
    final fechaInicio = widget.codigo['fecha_inicio']
            ?.toString()
            .replaceFirst('T', ' ')
            .substring(0, 16) ??
        '';
    final fechaFin = widget.codigo['fecha_fin']
            ?.toString()
            .replaceFirst('T', ' ')
            .substring(0, 16) ??
        '';
    final qrData = widget.codigo['codigo_hash'] ??
        widget.codigo['codigo'] ??
        widget.codigo['id'] ??
        '';

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
        title: const Text('Acceso Generado',
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
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 48),
            const SizedBox(height: 8),
            const Text('Código Generado con Éxito',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const Text('Comparte este código con tu visitante',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

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
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                    QrImageView(
                      data: qrData.isNotEmpty ? qrData : 'urbanapp-qr',
                      version: QrVersions.auto,
                      size: 200,
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
          ],
        ),
      ),
    );
  }
}
