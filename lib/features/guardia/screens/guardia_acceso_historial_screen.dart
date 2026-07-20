import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'guardia_bitacora_screen.dart';
import 'guardia_ingreso_detalle_screen.dart';
import 'package:dio/dio.dart';

class GuardiaAccesoHistorialScreen extends StatefulWidget {
  const GuardiaAccesoHistorialScreen({super.key});

  @override
  State<GuardiaAccesoHistorialScreen> createState() =>
      GuardiaAccesoHistorialScreenState();
}

class GuardiaAccesoHistorialScreenState
    extends State<GuardiaAccesoHistorialScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  late TabController _tabController;

  List<dynamic> _ingresos = [];
  bool _loading = true;
  bool _abriendoBitacora = false;
  String _filtro = 'hoy';
  String _filtroTipo = 'todos';
  String _guardiaId = '';
  DateTimeRange? _rangoFechas;

  // Aplica el filtro de tab (tipo/estado) sobre los ingresos ya filtrados por fecha
  List<dynamic> get _ingresosFiltrados => _filtrarPorTipo(_filtroTipo);

  List<dynamic> _filtrarPorTipo(String tipo) {
    if (tipo == 'todos') return _ingresos;
    if (tipo == 'automatico') {
      return _ingresos
          .where((i) =>
              i['tipo_ingreso'] == 'automatico' && i['estado'] != 'denegado')
          .toList();
    }
    if (tipo == 'manual') {
      return _ingresos
          .where(
              (i) => i['tipo_ingreso'] == 'manual' && i['estado'] != 'denegado')
          .toList();
    }
    if (tipo == 'denegado') {
      return _ingresos.where((i) => i['estado'] == 'denegado').toList();
    }
    return _ingresos;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filtroTipo = [
            'todos',
            'automatico',
            'manual',
            'denegado'
          ][_tabController.index];
        });
      }
    });
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

  // Método público para recargar desde el home al cambiar de pestaña
  void recargar() {
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final resUser = await _api.get('/usuarios/$userId');
      _guardiaId = resUser.data['guardia']?['id'] ?? '';

      String fechaDesde = '';
      String fechaHasta = '';
      final hoy = DateTime.now();

      if (_filtro == 'hoy') {
        fechaDesde = _formatFecha(hoy);
        fechaHasta = _formatFecha(hoy);
      } else if (_filtro == 'ayer') {
        final ayer = hoy.subtract(const Duration(days: 1));
        fechaDesde = _formatFecha(ayer);
        fechaHasta = _formatFecha(ayer);
      } else if (_filtro == 'rango' && _rangoFechas != null) {
        fechaDesde = _formatFecha(_rangoFechas!.start);
        fechaHasta = _formatFecha(_rangoFechas!.end);
      }

      final res = await _api.get(
        '${ApiConstants.ingresos}?fecha=$fechaDesde&fecha_hasta=$fechaHasta&guardia_id=$_guardiaId',
      );
      if (!mounted) return;
      setState(() {
        _ingresos = res.data as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatFecha(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatHora(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildLista(String tipo) {
    final lista = _filtrarPorTipo(tipo);
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined,
                size: 56,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('Sin registros',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (context, i) => _buildTarjeta(lista[i]),
      ),
    );
  }

  Widget _buildTarjeta(Map<String, dynamic> ingreso) {
    final tieneIncidencia = ingreso['observacion_incidencia'] != null &&
        ingreso['observacion_incidencia'].toString().isNotEmpty;
    final esDenegado = ingreso['estado'] == 'denegado';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuardiaIngresoDetalleScreen(ingreso: ingreso),
        ),
      ),
      child: Container(
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
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (esDenegado ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline,
                  color: esDenegado ? AppColors.error : AppColors.primary,
                  size: 20),
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
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        esDenegado
                            ? Icons.block
                            : (tieneIncidencia
                                ? Icons.warning_amber_outlined
                                : Icons.check_circle_outline),
                        size: 12,
                        color: esDenegado
                            ? AppColors.error
                            : (tieneIncidencia
                                ? AppColors.error
                                : AppColors.success),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        esDenegado
                            ? 'Denegado'
                            : (tieneIncidencia
                                ? 'Incidencia reportada'
                                : 'Sin novedades'),
                        style: TextStyle(
                          fontSize: 11,
                          color: esDenegado
                              ? AppColors.error
                              : (tieneIncidencia
                                  ? AppColors.error
                                  : AppColors.success),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatHora(ingreso['hora_ingreso']),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Icon(Icons.remove_red_eye_outlined,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarRango() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (rango != null) {
      setState(() {
        _rangoFechas = rango;
        _filtro = 'rango';
      });
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Historial de Accesos',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18)),
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
            Tab(text: 'Automáticos'),
            Tab(text: 'Manuales'),
            Tab(text: 'Denegados'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFiltroChip('hoy', 'Hoy'),
                const SizedBox(width: 8),
                _buildFiltroChip('ayer', 'Ayer'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _seleccionarRango,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _filtro == 'rango'
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filtro == 'rango'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range_outlined,
                            size: 14,
                            color: _filtro == 'rango'
                                ? Colors.white
                                : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Rango de Fechas',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _filtro == 'rango'
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total badge
          if (!_loading)
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('REGISTROS GUARDADOS',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('TOTAL: ${_ingresosFiltrados.length} REGISTROS',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

          // Lista con swipe entre tabs
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLista('todos'),
                      _buildLista('automatico'),
                      _buildLista('manual'),
                      _buildLista('denegado'),
                    ],
                  ),
          ),

          // Botón Bitácora Digital
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _abriendoBitacora ? null : _abrirBitacora,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('BITÁCORA DIGITAL',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
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

  Future<void> _abrirBitacora() async {
    if (_abriendoBitacora) return;
    setState(() => _abriendoBitacora = true);
    try {
      final resEstado = await _api.get('/bitacora/estado/$_guardiaId');
      final bitacoraActiva = resEstado.data['bitacora_activa'];
      if (bitacoraActiva == null) {
        if (!mounted) return;
        setState(() => _abriendoBitacora = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay una bitácora activa en este momento'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final resBitacora = await _api.get('/bitacora/${bitacoraActiva['id']}');
      final ingresos = (resBitacora.data['ingresos'] as List?) ?? [];
      if (!mounted) return;
      setState(() => _abriendoBitacora = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuardiaBitacoraScreen(
            guardiaId: _guardiaId,
            ingresos: ingresos,
            bitacoraId: bitacoraActiva['id'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _abriendoBitacora = false);
      String mensaje = 'Error al cargar la bitácora';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          mensaje = data['message'].toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildFiltroChip(String valor, String label) {
    final activo = _filtro == valor;
    return GestureDetector(
      onTap: () {
        setState(() => _filtro = valor);
        _cargar();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
