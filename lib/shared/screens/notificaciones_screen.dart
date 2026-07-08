import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  List _notificaciones = [];
  bool _loading = true;
  bool _soloSinLeer = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final res =
          await _api.get('${ApiConstants.notificaciones}/usuario/$userId');
      if (!mounted) return;
      setState(() {
        _notificaciones = res.data as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marcarLeida(String id) async {
    try {
      await _api.patch('${ApiConstants.notificaciones}/$id/leer', data: {});
      await _cargar();
    } catch (_) {}
  }

  Future<void> _marcarTodasLeidas() async {
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      await _api.patch(
          '${ApiConstants.notificaciones}/usuario/$userId/leer-todas',
          data: {});
      await _cargar();
    } catch (_) {}
  }

  List get _filtradas {
    if (_soloSinLeer) {
      return _notificaciones.where((n) => n['leida'] == false).toList();
    }
    return _notificaciones;
  }

  IconData _iconTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'pago':
        return Icons.credit_card_outlined;
      case 'reserva':
        return Icons.calendar_today_outlined;
      case 'acceso':
        return Icons.qr_code_outlined;
      case 'alicuota':
        return Icons.receipt_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _tiempoRelativo(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      final diff = DateTime.now().difference(fecha);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
      if (diff.inDays == 1) return 'Ayer';
      return 'Hace ${diff.inDays} días';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;
    final sinLeerCount =
        _notificaciones.where((n) => n['leida'] == false).length;

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
        title: const Text('Notificaciones',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          if (sinLeerCount > 0)
            TextButton(
              onPressed: _marcarTodasLeidas,
              child: const Text('Leer todas',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildFiltro('Todas', !_soloSinLeer),
                      const SizedBox(width: 8),
                      _buildFiltro('Sin leer', _soloSinLeer,
                          count: sinLeerCount),
                    ],
                  ),
                ),

                // Lista
                Expanded(
                  child: filtradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 48,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                _soloSinLeer
                                    ? 'No tienes notificaciones sin leer'
                                    : 'No tienes notificaciones',
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtradas.length,
                          itemBuilder: (context, index) {
                            final notif = filtradas[index];
                            final leida = notif['leida'] == true;
                            final tipo = notif['tipo'] ?? '';
                            final titulo = notif['titulo'] ?? '';
                            final mensaje = notif['mensaje'] ?? '';
                            final fecha = notif['created_at'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                if (!leida) _marcarLeida(notif['id']);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: leida
                                      ? null
                                      : Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(
                                          top: 6, right: 8),
                                      decoration: BoxDecoration(
                                        color: leida
                                            ? Colors.transparent
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_iconTipo(tipo),
                                          color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(tipo.toUpperCase(),
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.primary
                                                          .withValues(
                                                              alpha: 0.8))),
                                              Text(_tiempoRelativo(fecha),
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .textSecondary)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(titulo,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: leida
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color:
                                                      AppColors.textPrimary)),
                                          const SizedBox(height: 4),
                                          Text(mensaje,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltro(String label, bool activo, {int count = 0}) {
    return GestureDetector(
      onTap: () => setState(() => _soloSinLeer = label == 'Sin leer'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: activo ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: activo ? AppColors.white : AppColors.textSecondary)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activo
                      ? AppColors.white.withValues(alpha: 0.3)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
