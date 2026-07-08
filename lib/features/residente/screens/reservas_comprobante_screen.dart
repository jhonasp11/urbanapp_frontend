import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/custom_button.dart';

class ReservasComprobanteScreen extends StatefulWidget {
  final Map<String, dynamic> reserva;
  final Map<String, dynamic> area;
  final String residenteId;
  const ReservasComprobanteScreen({
    super.key,
    required this.reserva,
    required this.area,
    required this.residenteId,
  });

  @override
  State<ReservasComprobanteScreen> createState() =>
      _ReservasComprobanteScreenState();
}

class _ReservasComprobanteScreenState extends State<ReservasComprobanteScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  int _paso = 1;
  bool _isLoading = false;

  String _metodo = '';
  String _banco = '';
  String _observacion = '';
  File? _archivo;
  String _nombreArchivo = '';
  String _formatoArchivo = 'img';

  final List<String> _metodos = ['Transferencia', 'Deposito'];
  final List<String> _bancos = [
    'Banco Guayaquil',
    'Banco Pichincha',
    'Banco Pacifico',
    'Produbanco',
    'Banco Internacional'
  ];

  Future<void> _seleccionarArchivo() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Seleccionar comprobante',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        setState(() {
                          _archivo = File(picked.path);
                          _nombreArchivo = picked.name.length > 100
                              ? picked.name.substring(picked.name.length - 100)
                              : picked.name;
                          _formatoArchivo = 'img';
                        });
                      }
                    },
                    child: _buildOpcionArchivo(
                        Icons.camera_alt_outlined, 'Cámara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        setState(() {
                          _archivo = File(picked.path);
                          _nombreArchivo = picked.name.length > 100
                              ? picked.name.substring(picked.name.length - 100)
                              : picked.name;
                          _formatoArchivo = 'img';
                        });
                      }
                    },
                    child: _buildOpcionArchivo(
                        Icons.photo_library_outlined, 'Galería'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          _archivo = File(result.files.single.path!);
                          final name = result.files.single.name;
                          _nombreArchivo = name.length > 100
                              ? name.substring(name.length - 100)
                              : name;
                          _formatoArchivo = 'pdf';
                        });
                      }
                    },
                    child: _buildOpcionArchivo(
                        Icons.picture_as_pdf_outlined, 'PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionArchivo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ],
      ),
    );
  }

  Future<void> _enviar() async {
    if (_archivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un comprobante de pago'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final precio = double.tryParse((widget.area['tarifa_reserva'] ??
                  widget.area['precio_reserva'] ??
                  0)
              .toString()) ??
          0.0;

      // 1. Subir el archivo real a Cloudinary y obtener la URL
      final formData = FormData.fromMap({
        'comprobante': await MultipartFile.fromFile(
          _archivo!.path,
          filename: _nombreArchivo,
        ),
      });
      final resSubida =
          await _api.postFile('${ApiConstants.pagos}/comprobante', formData);
      final comprobanteUrl = resSubida.data['comprobante_url'];
      final formatoArchivo = resSubida.data['formato_archivo'];

      // 2. Crear el pago con la URL real del comprobante
      await _api.post(ApiConstants.pagos, data: {
        'residente_id': widget.residenteId,
        'reserva_id': widget.reserva['id'],
        'monto_pagado': precio,
        'cantidad_meses': 1,
        'tipo_pago': 'reserva',
        'mes_pago': DateTime.now().month,
        'anio_pago': DateTime.now().year,
        'metodo_pago': _metodo.toLowerCase(),
        'banco': _banco,
        'comprobante_url': comprobanteUrl,
        'formato_archivo': formatoArchivo,
        'observacion_residente': _observacion.trim(),
      });

      // 3. Marcar la reserva como pagada (pendiente_pago -> pendiente + notifica admin)
      await _api
          .patch('${ApiConstants.reservas}/${widget.reserva['id']}/pagada');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comprobante enviado exitosamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al enviar comprobante';
        try {
          final response = (e as dynamic).response?.data;
          if (response != null && response['message'] != null) {
            mensaje = response['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final precio = double.tryParse((widget.area['tarifa_reserva'] ??
                widget.area['precio_reserva'] ??
                0)
            .toString()) ??
        0.0;
    final nombreArea = widget.area['nombre'] ?? '';
    final fechaReserva =
        widget.reserva['fecha_reserva']?.toString().substring(0, 10) ?? '';
    final horaInicio =
        widget.reserva['hora_inicio']?.toString().substring(11, 16) ?? '';
    final horaFin =
        widget.reserva['hora_fin']?.toString().substring(11, 16) ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () {
            if (_paso == 2) {
              setState(() => _paso = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Subir Comprobante de Pago',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _paso == 1
            ? _buildPaso1(precio, nombreArea, fechaReserva, horaInicio, horaFin)
            : _buildPaso2(),
      ),
    );
  }

  Widget _buildPaso1(
    double precio,
    String nombreArea,
    String fechaReserva,
    String horaInicio,
    String horaFin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('VALOR A PAGAR POR RESERVA',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              Text(
                '\$${precio.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
              const Divider(height: 20),
              _buildFila('ÁREA SOCIAL', nombreArea),
              const SizedBox(height: 8),
              _buildFila('FECHA DE RESERVA', fechaReserva),
              const SizedBox(height: 8),
              _buildFila('HORARIO', '$horaInicio - $horaFin'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('MÉTODO DE PAGO',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Método de pago',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: AppColors.white,
          ),
          items: _metodos
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _metodo = v ?? ''),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Banco',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: AppColors.white,
          ),
          items: _bancos
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (v) => setState(() => _banco = v ?? ''),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Siguiente',
          onPressed: () {
            if (_metodo.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Selecciona un método de pago'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating),
              );
              return;
            }
            if (_banco.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Selecciona un banco'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating),
              );
              return;
            }
            setState(() => _paso = 2);
          },
        ),
      ],
    );
  }

  Widget _buildFila(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        Text(valor,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EVIDENCIA DE PAGO',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _seleccionarArchivo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _archivo != null ? AppColors.primary : AppColors.border,
                width: _archivo != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _archivo != null
                ? Column(
                    children: [
                      if (_formatoArchivo == 'img')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _archivo!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_outlined,
                                  color: Colors.red, size: 48),
                              SizedBox(height: 8),
                              Text('Archivo PDF seleccionado',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _nombreArchivo,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Toca para cambiar',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withValues(alpha: 0.7))),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_outlined,
                          color: AppColors.primary, size: 40),
                      SizedBox(height: 12),
                      Text('Seleccionar Comprobante',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Imagen (cámara/galería) o PDF',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones (Opcional)',
            hintText: 'Ej. Pago realizado via transferencia Banco Pichincha...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: AppColors.white,
          ),
          onChanged: (v) => _observacion = v,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Enviar Comprobante',
          isLoading: _isLoading,
          onPressed: _enviar,
        ),
      ],
    );
  }
}
