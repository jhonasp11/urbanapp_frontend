import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'admin_pago_detalle_screen.dart';

class AdminPagosValidadosScreen extends StatefulWidget {
  const AdminPagosValidadosScreen({super.key});

  @override
  State<AdminPagosValidadosScreen> createState() =>
      _AdminPagosValidadosScreenState();
}

class _AdminPagosValidadosScreenState extends State<AdminPagosValidadosScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  final _busquedaController = TextEditingController();

  late TabController _tabController;
  List _pagos = [];
  bool _loading = true;
  String _miUsuarioId = '';
  String _filtroAdmin = 'todos'; // todos | mios | otros
  String _busqueda = '';

  final List<Map<String, String>> _filtrosAdmin = [
    {'key': 'todos', 'label': 'Todos'},
    {'key': 'mios', 'label': 'Validados por mí'},
    {'key': 'otros', 'label': 'Validados por otros'},
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
      final res = await _api.get('/pagos/validados');
      if (!mounted) return;
      setState(() {
        _pagos = res.data as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List _filtrar(String tipoPago) {
    return _pagos.where((p) {
      // Filtro por tipo (tab)
      if (p['tipo_pago'] != tipoPago) return false;

      // Filtro por admin (chips)
      final adminUsuarioId =
          (p['administrador']?['usuario_id'] ?? '').toString();
      if (_filtroAdmin == 'mios' && adminUsuarioId != _miUsuarioId) {
        return false;
      }
      if (_filtroAdmin == 'otros' && adminUsuarioId == _miUsuarioId) {
        return false;
      }

      // Filtro por búsqueda (nombre + apellido + cédula)
      if (_busqueda.isNotEmpty) {
        final usuario = p['residente']?['usuario'] ?? {};
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

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return AppColors.success;
      case 'rechazado':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return 'APROBADO';
      case 'rechazado':
        return 'RECHAZADO';
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
        title: const Text('Pagos Validados',
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
            Tab(text: 'Alícuotas'),
            Tab(text: 'Salón de Eventos'),
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
                      _buildLista(_filtrar('alicuota')),
                      _buildLista(_filtrar('reserva')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLista(List pagos) {
    if (pagos.isEmpty) {
      return const Center(
        child: Text('No hay pagos en esta categoría',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pagos.length,
        itemBuilder: (context, index) {
          final pago = pagos[index];
          final residente = pago['residente'] ?? {};
          final usuario = residente['usuario'] ?? {};
          final nombres = usuario['nombres'] ?? '';
          final apellidos = usuario['apellidos'] ?? '';
          final manzana = residente['manzana'] ?? '';
          final villa = residente['villa'] ?? '';
          final fotoUrl = (residente['foto_url'] ?? '').toString();
          final monto =
              double.tryParse((pago['monto_pagado'] ?? 0).toString()) ?? 0.0;
          final fecha = _formatFecha(pago['fecha_validacion']);
          final estado = (pago['estado'] ?? '').toString();
          final adminUsuario = pago['administrador']?['usuario'] ?? {};
          final adminNombres = adminUsuario['nombres'] ?? '';
          final adminApellidos = adminUsuario['apellidos'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminDetallePagoScreen(
                    pago: pago,
                    onActualizado: _cargar,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
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
                                      fontSize: 18,
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('$nombres $apellidos',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _colorEstado(estado)
                                          .withValues(alpha: 0.12),
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
                              const SizedBox(height: 2),
                              Text('Mz $manzana - Villa $villa',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(fecha,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary)),
                                  Text('\$${monto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
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
            ),
          );
        },
      ),
    );
  }
}
