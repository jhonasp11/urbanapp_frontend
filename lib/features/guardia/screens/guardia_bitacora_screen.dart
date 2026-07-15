import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_constants.dart';

class GuardiaBitacoraScreen extends StatelessWidget {
  final String guardiaId;
  final List<dynamic> ingresos;
  final String bitacoraId;

  const GuardiaBitacoraScreen({
    super.key,
    required this.guardiaId,
    required this.ingresos,
    this.bitacoraId = '',
  });

  String _formatHora(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalHoy = ingresos.length;

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
        title: const Text('Bitácora Digital',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Total ingresos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INGRESOS REGISTRADOS',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$totalHoy',
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1)),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Ingresos Hoy',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: ingresos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 56,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('Sin registros en la bitácora',
                            style: TextStyle(
                                fontSize: 15, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ingresos.length,
                    itemBuilder: (context, i) {
                      final ingreso = ingresos[i];
                      final tieneIncidencia =
                          ingreso['observacion_incidencia'] != null &&
                              ingreso['observacion_incidencia']
                                  .toString()
                                  .isNotEmpty;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ingreso['nombre_visitante'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                      'Mz ${ingreso['manzana_destino'] ?? ''} Villa ${ingreso['villa_destino'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        tieneIncidencia
                                            ? Icons.warning_amber_outlined
                                            : Icons.check_circle_outline,
                                        size: 12,
                                        color: tieneIncidencia
                                            ? AppColors.error
                                            : AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tieneIncidencia
                                            ? 'Incidencia reportada'
                                            : 'Sin novedades',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: tieneIncidencia
                                              ? AppColors.error
                                              : AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (tieneIncidencia) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      ingreso['observacion_incidencia'],
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(_formatHora(ingreso['hora_ingreso']),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Botón descargar PDF
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (bitacoraId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No hay bitácora para generar el PDF'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  try {
                    const storage = FlutterSecureStorage();
                    final token = await storage.read(key: 'token') ?? '';
                    final url =
                        '${ApiConstants.baseUrl}/bitacora/$bitacoraId/pdf';
                    final dir = await getApplicationDocumentsDirectory();
                    final filePath = '${dir.path}/bitacora.pdf';
                    await Dio().download(
                      url,
                      filePath,
                      options:
                          Options(headers: {'Authorization': 'Bearer $token'}),
                    );
                    await OpenFilex.open(filePath);
                  } catch (e) {
                    String mensaje = 'Error al descargar el PDF';
                    if (e is DioException && e.response?.data != null) {
                      final data = e.response!.data;
                      if (data is Map && data['message'] != null) {
                        mensaje = data['message'].toString();
                      }
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(mensaje),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Descargar Reporte PDF',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
}
