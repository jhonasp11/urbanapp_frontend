import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

class AdminDocumentosScreen extends StatefulWidget {
  const AdminDocumentosScreen({super.key});

  @override
  State<AdminDocumentosScreen> createState() => _AdminDocumentosScreenState();
}

class _AdminDocumentosScreenState extends State<AdminDocumentosScreen> {
  final _api = ApiService();
  Map<String, dynamic?> _documentos = {
    'reglamento': null,
    'terminos_condiciones': null,
    'politica_privacidad': null,
  };
  bool _loading = true;

  final Map<String, String> _titulos = {
    'reglamento': 'Reglamento Interno',
    'terminos_condiciones': 'Términos y Condiciones',
    'politica_privacidad': 'Política de Privacidad',
  };

  final Map<String, IconData> _iconos = {
    'reglamento': Icons.menu_book_outlined,
    'terminos_condiciones': Icons.gavel_outlined,
    'politica_privacidad': Icons.shield_outlined,
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/documentos');
      final lista = res.data as List;
      final Map<String, dynamic?> docs = {
        'reglamento': null,
        'terminos_condiciones': null,
        'politica_privacidad': null,
      };
      for (final doc in lista) {
        final tipo = doc['tipo']?.toString() ?? '';
        if (docs.containsKey(tipo)) {
          docs[tipo] = doc;
        }
      }
      if (!mounted) return;
      setState(() {
        _documentos = docs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatFecha(String? isoStr) {
    if (isoStr == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return 'Sin fecha';
    }
  }

  Future<void> _abrirPdf(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el documento'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Documentos y Reglamentos',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text('ARCHIVOS CARGADOS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5)),
                    ),
                    ..._documentos.entries.map((entry) {
                      final tipo = entry.key;
                      final doc = entry.value;
                      final titulo = _titulos[tipo] ?? tipo;
                      final icono = _iconos[tipo] ?? Icons.description_outlined;
                      final fecha = doc != null
                          ? _formatFecha(doc['created_at'])
                          : 'Sin documento';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icono, color: Colors.red, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titulo,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  Text(
                                    doc != null
                                        ? 'Cargado el $fecha'
                                        : 'Sin documento cargado',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            // Botón visualizar
                            IconButton(
                              onPressed: doc != null
                                  ? () => _abrirPdf(doc['archivo_url'] ?? '')
                                  : null,
                              icon: Icon(
                                Icons.visibility_outlined,
                                color: doc != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.4),
                              ),
                              tooltip: 'Visualizar',
                            ),
                            // Botón modificar
                            IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminModificarDocumentoScreen(
                                    tipo: tipo,
                                    titulo: titulo,
                                    documentoActual: doc,
                                    onActualizado: _cargar,
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Modificar',
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guía de Administración',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          SizedBox(height: 4),
                          Text(
                              'Consulta el manual de procedimientos actualizados para la gestión de la Urbanización.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class AdminModificarDocumentoScreen extends StatefulWidget {
  final String tipo;
  final String titulo;
  final Map<String, dynamic>? documentoActual;
  final VoidCallback onActualizado;

  const AdminModificarDocumentoScreen({
    super.key,
    required this.tipo,
    required this.titulo,
    required this.documentoActual,
    required this.onActualizado,
  });

  @override
  State<AdminModificarDocumentoScreen> createState() =>
      _AdminModificarDocumentoScreenState();
}

class _AdminModificarDocumentoScreenState
    extends State<AdminModificarDocumentoScreen> {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String _archivoNombre = '';
  PlatformFile? _archivo;
  Map<String, dynamic>? _usuario;

  String _formatFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatFechaISO(String? isoStr) {
    if (isoStr == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return _formatFecha(dt);
    } catch (_) {
      return 'Sin fecha';
    }
  }

  String _proximaVersion() {
    final actual = widget.documentoActual?['version']?.toString();
    if (actual == null || actual.isEmpty) return '1.0';
    final numero = int.tryParse(actual.split('.')[0]) ?? 1;
    return '${numero + 1}.0';
  }

  @override
  void initState() {
    super.initState();
    _cargarAdmin();
  }

  Future<void> _cargarAdmin() async {
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final res = await _api.get('/usuarios/$userId');
      if (!mounted) return;
      setState(() => _usuario = res.data);
    } catch (_) {}
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path == null) return;
      setState(() {
        _archivo = file;
        _archivoNombre = file.name;
      });
    }
  }

  Future<void> _guardar() async {
    if (_archivo == null || _archivo!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un archivo PDF'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final adminId = _usuario?['administrador']?['id'] ?? '';

      // 1. Subir el PDF real a Cloudinary
      final formData = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(
          _archivo!.path!,
          filename: _archivoNombre,
        ),
      });
      final resSubida = await _api.postFile('/documentos/archivo', formData);
      final archivoUrl = resSubida.data['archivo_url'];

      // 2. Crear el documento (el backend calcula la versión y notifica)
      await _api.post('/documentos', data: {
        'titulo': widget.titulo,
        'tipo': widget.tipo,
        'archivo_url': archivoUrl,
        'version': 'auto',
        'visible_para': 'todos',
        'subido_por': adminId,
      });

      widget.onActualizado();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento actualizado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el documento'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCampoLectura(String label, String valor) {
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
            child: Row(
              children: [
                Expanded(
                  child: Text(valor,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary)),
                ),
                const Icon(Icons.lock_outline,
                    size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombres = _usuario?['nombres'] ?? '';
    final apellidos = _usuario?['apellidos'] ?? '';
    final adminId = _usuario?['administrador']?['id_administrador'] ?? '';
    final fechaCarga = _formatFechaISO(widget.documentoActual?['created_at']);
    final fechaHoy = _formatFecha(DateTime.now());

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
        title: Text('Modificar ${widget.titulo}',
            style: const TextStyle(
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
              child: Column(
                children: [
                  _buildCampoLectura('VERSIÓN A GENERAR', _proximaVersion()),
                  _buildCampoLectura('ID ADMINISTRADOR', adminId),
                  _buildCampoLectura(
                      'NOMBRE DEL ADMINISTRADOR', '$nombres $apellidos'),
                  _buildCampoLectura('FECHA DE CARGA ANTERIOR', fechaCarga),
                  _buildCampoLectura('FECHA DE ACTUALIZACIÓN', fechaHoy),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selector de archivo
            GestureDetector(
              onTap: _seleccionarArchivo,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _archivoNombre.isNotEmpty
                        ? AppColors.primary
                        : AppColors.border,
                    width: _archivoNombre.isNotEmpty ? 1.5 : 1,
                  ),
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _archivoNombre.isNotEmpty
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _archivoNombre.isNotEmpty
                            ? Icons.picture_as_pdf_outlined
                            : Icons.upload_file_outlined,
                        color: _archivoNombre.isNotEmpty
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _archivoNombre.isNotEmpty
                          ? _archivoNombre
                          : 'Toca para seleccionar un PDF',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: _archivoNombre.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _archivoNombre.isNotEmpty
                              ? AppColors.primary
                              : AppColors.textSecondary),
                    ),
                    if (_archivoNombre.isEmpty) ...[
                      const SizedBox(height: 4),
                      const Text('Formato permitido: PDF',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardar,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar Documento',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
