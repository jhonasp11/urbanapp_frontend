import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'guardia_datos_personales_screen.dart';
import 'guardia_cambiar_contrasena_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

class GuardiaPerfilScreen extends StatefulWidget {
  const GuardiaPerfilScreen({super.key});

  @override
  State<GuardiaPerfilScreen> createState() => _GuardiaPerfilScreenState();
}

class _GuardiaPerfilScreenState extends State<GuardiaPerfilScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  Map<String, dynamic>? _usuario;
  bool _loading = true;
  final _picker = ImagePicker();
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String _formatHoraTurno(String? horaStr) {
    if (horaStr == null) return '';
    try {
      final dt = DateTime.parse(horaStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return horaStr.length >= 5 ? horaStr.substring(0, 5) : horaStr;
    }
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
    final fotoUrl = (_usuario?['guardia']?['foto_url'] ?? '').toString();
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

      // Leer los bytes ANTES del setState y de cualquier await largo,
      // porque en algunos dispositivos la pantalla se recrea al usar el picker.
      final bytes = await imagen.readAsBytes();
      final userId = await _storage.read(key: 'usuario_id') ?? '';

      if (mounted) setState(() => _subiendoFoto = true);

      final formData = FormData.fromMap({
        'foto': MultipartFile.fromBytes(bytes, filename: imagen.name),
      });

      final resp = await _api.patchFile('/usuarios/$userId/foto', formData);

      final nuevaUrl = resp.data?['foto_url'];
      if (nuevaUrl != null) {
        // Evictar del caché para forzar descarga de la imagen nueva
        await NetworkImage(nuevaUrl.toString()).evict();
      }

      // Recargar los datos del perfil (trae la URL nueva)
      await _cargar();

      // Mostrar el mensaje usando el navigatorKey global, que no depende
      // de que esta pantalla siga viva (el picker puede recrearla).
      final messenger = navigatorKey.currentState?.overlay?.context;
      if (messenger != null && messenger.mounted) {
        ScaffoldMessenger.of(messenger).showSnackBar(
          const SnackBar(
            content: Text(
                'Foto de perfil actualizada. Desliza hacia abajo para verla.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String mensaje = 'No se pudo actualizar la foto';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          mensaje = data['message'].toString();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
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
            const Text('¿Estás seguro que deseas cerrar sesión?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
                'Tendrás que ingresar tus credenciales nuevamente para acceder a tu cuenta.',
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
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textSecondary)),
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

  @override
  Widget build(BuildContext context) {
    final nombres = _usuario?['nombres'] ?? '';
    final apellidos = _usuario?['apellidos'] ?? '';
    final guardia = _usuario?['guardia'] ?? {};
    final fotoUrl = guardia['foto_url'] ?? '';
    final turno = guardia['turno'] ?? {};
    final nombreTurno = turno['nombre'] ?? '';
    final horaInicio = _formatHoraTurno(turno['hora_inicio']?.toString());
    final horaFin = _formatHoraTurno(turno['hora_fin']?.toString());

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
          : RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar y nombre
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
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
                                  radius: 40,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  backgroundImage: fotoUrl.isNotEmpty
                                      ? NetworkImage(fotoUrl)
                                      : null,
                                  child: fotoUrl.isEmpty
                                      ? Text(
                                          nombres.isNotEmpty
                                              ? nombres[0].toUpperCase()
                                              : 'G',
                                          style: const TextStyle(
                                              fontSize: 32,
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
                                          width: 24,
                                          height: 24,
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
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.edit,
                                        color: AppColors.white, size: 12),
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
                          const Text('Guardia de Seguridad',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          // Turno
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_outlined,
                                    color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  nombreTurno.isNotEmpty
                                      ? '$nombreTurno • $horaInicio - $horaFin'
                                      : 'Sin turno asignado',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Opciones
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
                      child: Column(
                        children: [
                          _buildOpcion(
                            icon: Icons.person_outline,
                            titulo: 'Mis Datos Personales',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GuardiaDatosPersonalesScreen(
                                  usuario: _usuario ?? {},
                                  onActualizado: _cargar,
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          _buildOpcion(
                            icon: Icons.lock_outline,
                            titulo: 'Cambiar Contraseña',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const GuardiaCambiarContrasenaScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cerrar sesión
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
                      child: _buildOpcion(
                        icon: Icons.logout_rounded,
                        titulo: 'Cerrar Sesión',
                        color: AppColors.error,
                        onTap: _cerrarSesion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOpcion({
    required IconData icon,
    required String titulo,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(titulo,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.textPrimary)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: color ?? AppColors.textSecondary),
    );
  }
}
