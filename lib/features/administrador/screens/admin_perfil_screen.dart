import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'perfil/admin_datos_personales_screen.dart';
import 'perfil/admin_cambiar_contrasena_screen.dart';
import 'perfil/admin_documentos_screen.dart';
import 'perfil/admin_ayuda_screen.dart';

class AdminPerfilScreen extends StatefulWidget {
  const AdminPerfilScreen({super.key});

  @override
  State<AdminPerfilScreen> createState() => _AdminPerfilScreenState();
}

class _AdminPerfilScreenState extends State<AdminPerfilScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  final _picker = ImagePicker();
  Map<String, dynamic>? _usuario;
  bool _loading = true;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final res = await _api.get('/usuarios/$userId');
      if (!mounted) return;
      setState(() {
        _usuario = res.data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFuente() async {
    final fotoUrl = (_usuario?['administrador']?['foto_url'] ?? '').toString();
    final tieneFoto = fotoUrl.isNotEmpty;

    final accion = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            if (tieneFoto)
              ListTile(
                leading: const Icon(Icons.visibility_outlined,
                    color: AppColors.primary),
                title: const Text('Ver foto'),
                onTap: () => Navigator.pop(ctx, 'ver'),
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, 'camara'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, 'galeria'),
            ),
            if (tieneFoto)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Eliminar foto',
                    style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, 'eliminar'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (accion == null) return;
    if (accion == 'ver') {
      _verFoto(fotoUrl);
    } else if (accion == 'camara') {
      await _subirFoto(ImageSource.camera);
    } else if (accion == 'galeria') {
      await _subirFoto(ImageSource.gallery);
    } else if (accion == 'eliminar') {
      await _eliminarFoto();
    }
  }

  void _verFoto(String url) {
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
                child: Image.network(url, fit: BoxFit.contain),
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

  Future<void> _eliminarFoto() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar foto'),
        content: const Text('¿Seguro que deseas eliminar tu foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      await _api.delete('/usuarios/$userId/foto');
      if (!mounted) return;
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil eliminada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        String mensaje = 'No se pudo eliminar la foto';
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
  }

  Future<void> _subirFoto(ImageSource fuente) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: fuente,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (imagen == null) return;

      setState(() => _subiendoFoto = true);

      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          imagen.path,
          filename: imagen.name,
        ),
      });

      await _api.patchFile('/usuarios/$userId/foto', formData);

      if (!mounted) return;
      await _cargar();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil actualizada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar la foto'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.power_settings_new_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('¿Cerrar Sesión?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
                '¿Estás seguro de que deseas cerrar sesión? Deberás ingresar tus credenciales nuevamente para acceder.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cerrar Sesión',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;
    await _storage.deleteAll();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _buildSeccion(String titulo, List<Widget> opciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(titulo,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
        ),
        Container(
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
          child: Column(children: opciones),
        ),
      ],
    );
  }

  Widget _buildOpcion({
    required IconData icon,
    required String titulo,
    Color? color,
    IconData? trailingIcon,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(titulo,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: c)),
            ),
            Icon(trailingIcon ?? Icons.chevron_right_rounded,
                color: c == AppColors.textPrimary ? AppColors.textSecondary : c,
                size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombres = _usuario?['nombres'] ?? '';
    final apellidos = _usuario?['apellidos'] ?? '';
    final fotoUrl = _usuario?['administrador']?['foto_url'] ?? '';
    final correo = _usuario?['correo'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Mi Perfil',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta perfil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                        GestureDetector(
                          onTap: _subiendoFoto ? null : _seleccionarFuente,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage: fotoUrl.isNotEmpty
                                    ? NetworkImage(fotoUrl)
                                    : null,
                                child: fotoUrl.isEmpty
                                    ? Text(
                                        nombres.isNotEmpty
                                            ? nombres[0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary),
                                      )
                                    : null,
                              ),
                              if (_subiendoFoto)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_outlined,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('$nombres $apellidos',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(correo,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: AppColors.primary, size: 14),
                              SizedBox(width: 4),
                              Text('ADMINISTRADOR GENERAL',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSeccion('GESTIÓN DE CUENTA', [
                    _buildOpcion(
                      icon: Icons.person_outline,
                      titulo: 'Mis Datos Personales',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminDatosPersonalesScreen(
                            usuario: _usuario!,
                            onActualizado: _cargar,
                          ),
                        ),
                      ),
                    ),
                    _buildOpcion(
                      icon: Icons.lock_outline,
                      titulo: 'Cambiar Contraseña',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminCambiarContrasenaScreen(
                            usuarioId: _usuario?['id'] ?? '',
                          ),
                        ),
                      ),
                    ),
                    _buildOpcion(
                      icon: Icons.description_outlined,
                      titulo: 'Documentos y Reglamentos',
                      isLast: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDocumentosScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _buildSeccion('SOPORTE', [
                    _buildOpcion(
                      icon: Icons.help_outline,
                      titulo: 'Ayuda y Soporte',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAyudaScreen(),
                        ),
                      ),
                    ),
                    _buildOpcion(
                      icon: Icons.logout_rounded,
                      titulo: 'Cerrar Sesión',
                      color: AppColors.error,
                      trailingIcon: Icons.power_settings_new_rounded,
                      isLast: true,
                      onTap: _cerrarSesion,
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
