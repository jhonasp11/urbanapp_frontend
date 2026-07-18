import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'admin_detalle_reserva_screen.dart';

class AdminReservasValidadasScreen extends StatefulWidget {
  const AdminReservasValidadasScreen({super.key});

  @override
  State<AdminReservasValidadasScreen> createState() =>
      _AdminReservasValidadasScreenState();
}

class _AdminReservasValidadasScreenState
    extends State<AdminReservasValidadasScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  final _busquedaController = TextEditingController();

  late TabController _tabController;
  List _reservas = [];
  bool _loading = true;
  String _miUsuarioId = '';
  String _filtroAdmin = 'todos'; // todos | mios | otros
  String _busqueda = '';

  final List<Map<String, String>> _filtrosAdmin = [
    {'key': 'todos', 'label': 'Todas'},
    {'key': 'mios', 'label': 'Validadas por mí'},
    {'key': 'otros', 'label': 'Validadas por otros'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _busquedaController.addListener(() {
      setState(() => _busqueda = _busquedaController.text.trim().toLowerCase());
    });
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      _miUsuarioId = await _storage.read(key: 'usuario_id') ?? '';
      final res = await _api.get('/reservas/validadas');
      if (!mounted) return;
      setState(() {
        // Solo canchas (excluye el salón, que se gestiona por Pagos)
        _reservas = (res.data as List).where((r) {
          final tarifa =
              double.tryParse((r['area']?['tarifa_reserva'] ?? 0).toString()) ??
                  0.0;
          return tarifa == 0;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List _filtrar(String nombreArea) {
    return _reservas.where((r) {
      // Filtro por cancha (tab), por el nombre que envía la BD
      if ((r['area']?['nombre'] ?? '') != nombreArea) return false;

      // Filtro por admin (chips)
      final adminUsuarioId =
          (r['administrador']?['usuario_id'] ?? '').toString();
      if (_filtroAdmin == 'mios' && adminUsuarioId != _miUsuarioId) {
        return false;
      }
      if (_filtroAdmin == 'otros' && adminUsuarioId == _miUsuarioId) {
        return false;
      }

      // Filtro por búsqueda (nombre + apellido + cédula)
      if (_busqueda.isNotEmpty) {
        final usuario = r['residente']?['usuario'] ?? {};
        final nombres = (usuario['nombres'] ?? '').toString().toLowerCase();
        final apellidos = (usuario['apellidos'] ?? '').toString().toLowerCase();
        final cedula = (usuario['cedula'] ?? '').toString().toLowerCase();
        final texto = '$nombres $apellidos $cedula';
        if (!texto.contains(_busqueda)) return false;
      }

      return true;
    }).toList();
  }

  String _formatFecha(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr).toUtc();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatHora(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr).toUtc();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'confirmada':
      case 'completada':
        return AppColors.success;
      case 'denegada':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return 'APROBADA';
      case 'completada':
        return 'COMPLETADA';
      case 'denegada':
        return 'RECHAZADA';
      default:
        return estado.toUpperCase();
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
        title: const Text('Reservas Validadas',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Cancha de Fútbol'),
            Tab(text: 'Cancha de Básquet'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Buscador
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _busquedaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o cédula',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: AppColors.textSecondary),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _busquedaController.clear(),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Chips de filtro por admin
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filtrosAdmin.length,
                      itemBuilder: (context, index) {
                        final filtro = _filtrosAdmin[index];
                        final isSelected = _filtroAdmin == filtro['key'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _filtroAdmin = filtro['key']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                filtro['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLista(_filtrar('Cancha de Fútbol')),
                      _buildLista(_filtrar('Cancha de Básquet')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLista(List reservas) {
    if (reservas.isEmpty) {
      return const Center(
        child: Text('No hay reservas en esta categoría',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservas.length,
        itemBuilder: (context, index) {
          final reserva = reservas[index];
          final residente = reserva['residente'] ?? {};
          final usuario = residente['usuario'] ?? {};
          final nombres = usuario['nombres'] ?? '';
          final apellidos = usuario['apellidos'] ?? '';
          final manzana = residente['manzana'] ?? '';
          final villa = residente['villa'] ?? '';
          final fotoUrl = (residente['foto_url'] ?? '').toString();
          final area = reserva['area'] ?? {};
          final areaNombre = area['nombre'] ?? '';
          final fecha = _formatFecha(reserva['fecha_reserva']);
          final horaInicio = _formatHora(reserva['hora_inicio']);
          final horaFin = _formatHora(reserva['hora_fin']);
          final estado = (reserva['estado'] ?? '').toString();
          final adminUsuario = reserva['administrador']?['usuario'] ?? {};
          final adminNombres = adminUsuario['nombres'] ?? '';
          final adminApellidos = adminUsuario['apellidos'] ?? '';

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminDetalleReservaScreen(
                  reserva: reserva,
                  onActualizado: _cargar,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage:
                            fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                        child: fotoUrl.isEmpty
                            ? Text(
                                nombres.isNotEmpty
                                    ? nombres[0].toUpperCase()
                                    : 'R',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$nombres $apellidos',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text('Mz $manzana - Villa $villa',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _colorEstado(estado).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_labelEstado(estado),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _colorEstado(estado))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.sports_soccer_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(areaNombre,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(fecha,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('$horaInicio - $horaFin',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Validado por: $adminNombres $adminApellidos',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
