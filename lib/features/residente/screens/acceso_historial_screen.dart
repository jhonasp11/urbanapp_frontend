import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'acceso_detalle_screen.dart';
import 'package:dio/dio.dart';

class AccesoHistorialScreen extends StatefulWidget {
  final String userId;
  const AccesoHistorialScreen({super.key, required this.userId});

  @override
  State<AccesoHistorialScreen> createState() => _AccesoHistorialScreenState();
}

class _AccesoHistorialScreenState extends State<AccesoHistorialScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  List _codigos = [];
  bool _loading = true;
  bool _anulando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final res = await _api.get(
          '${ApiConstants.generarQr.replaceAll('/generar', '')}/residente/${widget.userId}');
      if (!mounted) return;
      setState(() {
        _codigos = res.data as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List _filtrar(String estado) {
    if (estado == 'todos') return List.from(_codigos);
    return _codigos.where((c) => c['estado'] == estado).toList();
  }

  Future<void> _anularCodigo(String codigoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Código QR'),
        content: const Text(
            'El código QR quedará anulado y no podrá ser usado. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (_anulando) return;
    setState(() => _anulando = true);

    try {
      await _api.patch('/codigos-qr/$codigoId/anular',
          data: {'residente_id': widget.userId});
      if (!mounted) return;
      setState(() => _anulando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código QR anulado exitosamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _cargar();
    } catch (e) {
      if (mounted) {
        setState(() => _anulando = false);
        String mensaje = 'Error al anular el código';
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
        title: const Text('Historial de Accesos',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Activos'),
            Tab(text: 'Usados'),
            Tab(text: 'Expirados'),
            Tab(text: 'Anulados'),
            Tab(text: 'Bloqueados'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(_filtrar('todos')),
                _buildLista(_filtrar('activo')),
                _buildLista(_filtrar('usado')),
                _buildLista(_filtrar('expirado')),
                _buildLista(_filtrar('anulado')),
                _buildLista(_filtrar('bloqueado')),
              ],
            ),
    );
  }

  Widget _buildLista(List codigos) {
    if (codigos.isEmpty) {
      return const Center(
        child: Text('No hay accesos en esta categoría',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: codigos.length,
        itemBuilder: (context, index) {
          final codigo = codigos[index];
          final visitante = codigo['visitante'] ?? {};
          final nombre = visitante['nombre_visitante'] ??
              visitante['nombre'] ??
              'Visitante';
          final estado = codigo['estado'] ?? 'activo';
          final fechaInicio = codigo['fecha_inicio']
                  ?.toString()
                  .substring(0, 16)
                  .replaceFirst('T', ' ') ??
              '';
          final fechaFin = codigo['fecha_fin']
                  ?.toString()
                  .substring(0, 16)
                  .replaceFirst('T', ' ') ??
              '';
          final esActivo = estado == 'activo';

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccesoDetalleScreen(codigo: codigo),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            Text('Inicio: $fechaInicio',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                            Text('Fin: $fechaFin',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _colorEstado(estado).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _colorEstado(estado)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                  if (esActivo) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AccesoDetalleScreen(codigo: codigo),
                              ),
                            ),
                            icon: const Icon(Icons.share_outlined, size: 14),
                            label: const Text('Ver y Compartir',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _anulando
                                ? null
                                : () => _anularCodigo(codigo['id']),
                            icon: const Icon(Icons.block_outlined, size: 14),
                            label: const Text('Anular',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
