import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'reservas_detalle_screen.dart';

class ReservasHistorialScreen extends StatefulWidget {
  final String residenteId;
  const ReservasHistorialScreen({super.key, required this.residenteId});

  @override
  State<ReservasHistorialScreen> createState() =>
      _ReservasHistorialScreenState();
}

class _ReservasHistorialScreenState extends State<ReservasHistorialScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _api = ApiService();
  late TabController _tabController;
  List _reservas = [];
  bool _loading = true;
  String _filtroEstado = 'todos';

  final List<Map<String, String>> _filtrosEstado = [
    {'key': 'todos', 'label': 'Todos'},
    {'key': 'completada', 'label': 'Completadas'},
    {'key': 'pendiente_pago', 'label': 'Por pagar'},
    {'key': 'pendiente', 'label': 'Pendientes'},
    {'key': 'confirmada', 'label': 'Aprobadas'},
    {'key': 'denegada', 'label': 'Rechazadas'},
    {'key': 'expirada', 'label': 'Expiradas'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _cargar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final res = await _api
          .get('${ApiConstants.reservas}/residente/${widget.residenteId}');
      if (!mounted) return;
      setState(() {
        _reservas = res.data as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _sinAcentos(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u');

  List _filtrar(String tipo) {
    List base;
    if (tipo == 'todos') {
      base = List.from(_reservas);
    } else if (tipo == 'futbol') {
      base = _reservas.where((r) {
        final n = _sinAcentos((r['area']?['nombre'] ?? '').toString());
        return n.contains('futbol');
      }).toList();
    } else if (tipo == 'basket') {
      base = _reservas.where((r) {
        final n = _sinAcentos((r['area']?['nombre'] ?? '').toString());
        return n.contains('basket') || n.contains('basquet');
      }).toList();
    } else {
      base = _reservas.where((r) {
        final n = _sinAcentos((r['area']?['nombre'] ?? '').toString());
        return n.contains('evento') || n.contains('salon');
      }).toList();
    }

    if (_filtroEstado == 'todos') return base;
    return base.where((r) => r['estado'] == _filtroEstado).toList();
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return AppColors.success;
      case 'completada':
        return AppColors.primary;
      case 'pendiente':
        return Colors.orange;
      case 'pendiente_pago':
        return const Color(0xFFE8830C); // naranja más intenso
      case 'cancelada':
        return Colors.grey;
      case 'denegada':
        return AppColors.error;
      case 'expirada':
        return Colors.grey;
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
      case 'pendiente':
        return 'PENDIENTE';
      case 'pendiente_pago':
        return 'PENDIENTE DE PAGO';
      case 'cancelada':
        return 'CANCELADA';
      case 'denegada':
        return 'RECHAZADA';
      case 'expirada':
        return 'EXPIRADA';
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
        title: const Text('Historial de Reservas',
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
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Fútbol'),
            Tab(text: 'Básquet'),
            Tab(text: 'Salón de Eventos'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros de estado
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filtrosEstado.length,
                      itemBuilder: (context, index) {
                        final filtro = _filtrosEstado[index];
                        final isSelected = _filtroEstado == filtro['key'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _filtroEstado = filtro['key']!),
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
                      _buildLista(_filtrar('todos')),
                      _buildLista(_filtrar('futbol')),
                      _buildLista(_filtrar('basket')),
                      _buildLista(_filtrar('salon')),
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
        child: Text('No hay reservas registradas',
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
          final area = reserva['area'] ?? {};
          final nombreArea = area['nombre'] ?? 'Área';
          final estado = reserva['estado'] ?? '';
          final fechaReserva =
              reserva['fecha_reserva']?.toString().substring(0, 10) ?? '';
          final horaInicio =
              reserva['hora_inicio']?.toString().substring(11, 16) ?? '';
          final horaFin =
              reserva['hora_fin']?.toString().substring(11, 16) ?? '';

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReservasDetalleScreen(
                  reserva: reserva,
                  residenteId: widget.residenteId,
                ),
              ),
            ).then((_) => _cargar()),
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
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorEstado(estado),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombreArea,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        Text('$fechaReserva  ·  $horaInicio - $horaFin',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _colorEstado(estado).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_labelEstado(estado),
                        style: TextStyle(
                            fontSize: 9,
                            color: _colorEstado(estado),
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.remove_red_eye_outlined,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
