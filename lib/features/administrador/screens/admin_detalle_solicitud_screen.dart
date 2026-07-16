import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'admin_padron_manzana_screen.dart';
import 'package:dio/dio.dart';

class AdminDetalleSolicitudScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onActualizado;

  const AdminDetalleSolicitudScreen({
    super.key,
    required this.usuario,
    required this.onActualizado,
  });

  @override
  State<AdminDetalleSolicitudScreen> createState() =>
      _AdminDetalleSolicitudScreenState();
}

class _AdminDetalleSolicitudScreenState
    extends State<AdminDetalleSolicitudScreen> {
  bool _verificandoPadron = false;
  bool? _padronVerificado;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _verificarPadron();
  }

  Future<void> _verificarPadron() async {
    // Solo aplica a residentes
    if (widget.usuario['rol'] != 'residente') return;
    final res = widget.usuario['residente'] ?? {};
    final cedula = widget.usuario['cedula'] ?? '';
    final manzana = res['manzana'] ?? '';
    final villa = res['villa'] ?? '';
    if (cedula.isEmpty || manzana.isEmpty || villa.isEmpty) return;

    setState(() => _verificandoPadron = true);
    try {
      final api = ApiService();
      final r =
          await api.get('/usuarios/padron/verificar/$cedula/$manzana/$villa');
      if (!mounted) return;
      setState(() {
        _padronVerificado = r.data['verificado'] == true;
        _verificandoPadron = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _padronVerificado = false;
          _verificandoPadron = false;
        });
      }
    }
  }

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

  String _labelEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return 'ACTIVADO';
      case 'pendiente':
        return 'PENDIENTE';
      case 'rechazado':
        return 'RECHAZADO';
      case 'desactivado':
        return 'DESACTIVADO';
      default:
        return estado.toUpperCase();
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return AppColors.success;
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return AppColors.error;
      case 'desactivado':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }

  // Pide justificación cuando el residente no consta en el padrón
  Future<String?> _pedirMotivoExcepcion(BuildContext context) async {
    final motivoCtrl = TextEditingController();
    return showDialog<String>(
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_maybe_outlined,
                    color: Colors.orange, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Aprobar fuera del padrón',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Este residente no consta en el padrón de la urbanización. Indica el motivo por el que apruebas su cuenta.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: motivoCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Ej. Documento de propiedad verificado presencialmente...',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final texto = motivoCtrl.text.trim();
                    if (texto.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Debes indicar un motivo'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, texto);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Aprobar de todos modos',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, null),
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
  }

  Future<void> _aprobar(BuildContext context) async {
    if (_procesando) return;

    // Si no consta en el padrón, exigir justificación antes de continuar
    String? motivo;
    if (_padronVerificado == false) {
      motivo = await _pedirMotivoExcepcion(context);
      if (motivo == null) return; // canceló
    }

    setState(() => _procesando = true);
    final api = ApiService();
    final adminId = await _obtenerAdminId();
    try {
      await api.patch('/usuarios/${widget.usuario['id']}/estado', data: {
        'estado': 'aprobado',
        'administrador_id': adminId,
        if (motivo != null) 'motivo': motivo,
      });
      try {
        await api.post('/notificaciones', data: {
          'usuario_id': widget.usuario['id'],
          'tipo': 'sistema',
          'titulo': 'Cuenta aprobada',
          'mensaje':
              'Tu cuenta ha sido aprobada. Ya puedes acceder a Urban App.',
        });
      } catch (_) {}

      widget.onActualizado();
      if (!context.mounted) return;

      final nav = Navigator.of(context);
      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminAprobacionExitosaScreen(
            nombres:
                '${widget.usuario['nombres']} ${widget.usuario['apellidos']}',
            ubicacion:
                'Manzana ${widget.usuario['residente']?['manzana']} - Villa ${widget.usuario['residente']?['villa']}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _procesando = false);
      if (!context.mounted) return;
      String mensaje = 'Error al aprobar el residente';
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

  Future<void> _cambiarEstado(BuildContext context, String nuevoEstado) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    final api = ApiService();
    final adminId = await _obtenerAdminId();
    try {
      await api.patch('/usuarios/${widget.usuario['id']}/estado',
          data: {'estado': nuevoEstado, 'administrador_id': adminId});
      try {
        await api.post('/notificaciones', data: {
          'usuario_id': widget.usuario['id'],
          'tipo': 'sistema',
          'titulo': nuevoEstado == 'aprobado'
              ? 'Cuenta reactivada'
              : 'Cuenta desactivada',
          'mensaje': nuevoEstado == 'aprobado'
              ? 'Tu cuenta ha sido reactivada. Ya puedes acceder a Urban App.'
              : 'Tu cuenta ha sido desactivada. Contacta al administrador.',
        });
      } catch (_) {}

      widget.onActualizado();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado == 'aprobado'
              ? 'Cuenta reactivada correctamente'
              : 'Cuenta desactivada correctamente'),
          backgroundColor:
              nuevoEstado == 'aprobado' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _procesando = false);
      if (!context.mounted) return;
      String mensaje = 'Error al cambiar el estado';
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
                child: const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Denegar Solicitud',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Estás a punto de denegar esta solicitud. El residente será notificado.',
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
                              'Ej. Datos de residente incorrectos, dirección no válida...',
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
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Denegar Solicitud',
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

    final api = ApiService();
    final adminId = await _obtenerAdminId();
    try {
      await api.patch('/usuarios/${widget.usuario['id']}/estado',
          data: {'estado': 'rechazado', 'administrador_id': adminId});
      try {
        await api.post('/notificaciones', data: {
          'usuario_id': widget.usuario['id'],
          'tipo': 'sistema',
          'titulo': 'Solicitud rechazada',
          'mensaje':
              'Tu solicitud ha sido rechazada. Motivo: ${motivoCtrl.text.trim()}',
        });
      } catch (_) {}

      widget.onActualizado();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud rechazada correctamente'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al rechazar la solicitud'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _labelRolTexto(String rol) {
    switch (rol) {
      case 'guardia':
        return 'Guardia de Seguridad';
      case 'administrador':
        return 'Administrador';
      default:
        return rol;
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

  @override
  Widget build(BuildContext context) {
    final nombres = widget.usuario['nombres'] ?? '';
    final apellidos = widget.usuario['apellidos'] ?? '';
    final res = widget.usuario['residente'] ?? {};
    final manzana = res['manzana'] ?? '';
    final villa = res['villa'] ?? '';
    final estado = widget.usuario['estado'] ?? '';
    final color = _colorEstado(estado);

    // Foto desde cualquier rol
    final fotoUrl = (widget.usuario['residente']?['foto_url'] ??
            widget.usuario['guardia']?['foto_url'] ??
            widget.usuario['administrador']?['foto_url'] ??
            '')
        .toString();

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
        title: const Text('Detalle de Solicitud',
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
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage:
                  fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
              child: fotoUrl.isEmpty
                  ? Text(
                      nombres.isNotEmpty ? nombres[0].toUpperCase() : 'R',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text('$nombres $apellidos',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(
                widget.usuario['rol'] == 'residente'
                    ? 'Manzana $manzana - Villa $villa'
                    : _labelRolTexto(widget.usuario['rol'] ?? ''),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _labelEstado(estado),
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ),
            const SizedBox(height: 20),
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
                  _buildCampo(
                      'CÉDULA DE IDENTIDAD', widget.usuario['cedula'] ?? ''),
                  _buildCampo('USUARIO', widget.usuario['usuario'] ?? ''),
                  _buildCampo('NOMBRES', nombres),
                  _buildCampo('APELLIDOS', apellidos),
                  _buildCampo(
                      'CORREO ELECTRÓNICO', widget.usuario['correo'] ?? ''),
                  _buildCampo('TELÉFONO', widget.usuario['telefono'] ?? ''),
                  if (widget.usuario['rol'] == 'residente')
                    Row(
                      children: [
                        Expanded(child: _buildCampo('MANZANA', manzana)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCampo('VILLA', villa)),
                      ],
                    ),
                ],
              ),
            ),
            // Tarjeta de verificación contra el padrón (solo residentes)
            if (widget.usuario['rol'] == 'residente') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _verificandoPadron
                      ? AppColors.background
                      : (_padronVerificado == true
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.error.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _verificandoPadron
                        ? AppColors.border
                        : (_padronVerificado == true
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.error.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _verificandoPadron
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _padronVerificado == true
                                ? Icons.verified_outlined
                                : Icons.gpp_maybe_outlined,
                            color: _padronVerificado == true
                                ? AppColors.success
                                : AppColors.error,
                            size: 22,
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _verificandoPadron
                                ? 'Verificando datos...'
                                : (_padronVerificado == true
                                    ? 'Residente verificado'
                                    : 'Verificación fallida'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _verificandoPadron
                                  ? AppColors.textSecondary
                                  : (_padronVerificado == true
                                      ? AppColors.success
                                      : AppColors.error),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (!_verificandoPadron)
                            Text(
                              _padronVerificado == true
                                  ? 'El residente ha sido verificado correctamente. La información de la vivienda y el número de cédula coinciden con los registros del sistema.'
                                  : 'El sistema no pudo validar los datos del residente con los registros de la urbanización.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminPadronManzanaScreen(
                        manzana: manzana.toString(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.people_outline,
                      color: AppColors.primary),
                  label: Text('Ver padrón de la Manzana $manzana',
                      style: const TextStyle(
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
            ],
            const SizedBox(height: 24),
            if (estado == 'pendiente') ...[
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
                          : const Icon(Icons.person_outline),
                      label: const Text('Aprobar',
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
                      icon: const Icon(Icons.block_outlined,
                          color: AppColors.error),
                      label: const Text('Denegar',
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
            ] else if (estado == 'aprobado') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _procesando
                      ? null
                      : () => _cambiarEstado(context, 'desactivado'),
                  icon: const Icon(Icons.person_off_outlined,
                      color: AppColors.error),
                  label: const Text('Desactivar cuenta',
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
            ] else if (estado == 'desactivado' || estado == 'rechazado') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _procesando
                      ? null
                      : () => _cambiarEstado(context, 'aprobado'),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Reactivar cuenta',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminAprobacionExitosaScreen extends StatelessWidget {
  final String nombres;
  final String ubicacion;

  const AdminAprobacionExitosaScreen({
    super.key,
    required this.nombres,
    required this.ubicacion,
  });

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
              const Text('Residente Aprobado Exitosamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success)),
              const SizedBox(height: 8),
              const Text(
                  'El registro ha sido procesado y el residente puede acceder a Urban App.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(nombres,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(ubicacion,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver a Inicio',
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
      ),
    );
  }
}
