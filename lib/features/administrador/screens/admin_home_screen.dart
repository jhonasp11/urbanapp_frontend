import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/screens/notificaciones_screen.dart';
import 'admin_gestion_usuarios_screen.dart';
import 'admin_pagos_screen.dart';
import 'admin_reportes_screen.dart';
import 'admin_perfil_screen.dart';
import 'admin_gestion_reservas_screen.dart';
import 'admin_gestion_alicuotas_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 2;

  void _navegarA(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const AdminGestionUsuariosScreen(),
      const AdminPagosScreen(),
      AdminInicioScreen(onNavigate: _navegarA),
      const AdminReportesScreen(),
      const AdminPerfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        backgroundColor: AppColors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            activeIcon: Icon(Icons.manage_accounts),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Pagos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class AdminInicioScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const AdminInicioScreen({super.key, required this.onNavigate});

  @override
  State<AdminInicioScreen> createState() => _AdminInicioScreenState();
}

class _AdminInicioScreenState extends State<AdminInicioScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  Map<String, dynamic>? _usuario;
  int _totalResidentes = 0;
  int _pagosPendientes = 0;
  int _notificacionesSinLeer = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final resUser = await _api.get('/usuarios/$userId');

      int totalResidentes = 0;
      int pagosPendientes = 0;
      int sinLeer = 0;

      try {
        final resResidentes = await _api.get('/usuarios/residentes');
        totalResidentes = (resResidentes.data as List).length;
      } catch (_) {}

      try {
        final resPagos = await _api.get('/pagos');
        final pagos = resPagos.data as List;
        pagosPendientes = pagos.where((p) => p['estado'] == 'pendiente').length;
      } catch (_) {}

      try {
        final resNotif =
            await _api.get('${ApiConstants.notificaciones}/usuario/$userId');
        final todas = resNotif.data as List;
        sinLeer = todas.where((n) => n['leida'] == false).length;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _usuario = resUser.data;
        _totalResidentes = totalResidentes;
        _pagosPendientes = pagosPendientes;
        _notificacionesSinLeer = sinLeer;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombres = _usuario?['nombres'] ?? '';
    final apellidos = _usuario?['apellidos'] ?? '';
    final fotoUrl = _usuario?['administrador']?['foto_url'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Urban App',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary),
                onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificacionesScreen()))
                    .then((_) => _cargar()),
              ),
              if (_notificacionesSinLeer > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
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
                                        color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bienvenido, Admin $nombres $apellidos',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                const Text(
                                    'Tu panel de control para la gestión residencial de hoy.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTarjetaResumen(
                            icono: Icons.people_outline,
                            titulo: 'TOTAL RESIDENTES REGISTRADOS',
                            valor: '$_totalResidentes',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTarjetaResumen(
                            icono: Icons.payments_outlined,
                            titulo: 'PAGOS PENDIENTES DE REVISAR',
                            valor: '$_pagosPendientes',
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Módulos Principales',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _buildModulo(
                      icono: Icons.manage_accounts_outlined,
                      titulo: 'Creación y Gestión de Usuarios',
                      subtitulo:
                          'Validar cuentas de residentes y crear accesos para guardias.',
                      onTap: () => widget.onNavigate(0),
                    ),
                    const SizedBox(height: 8),
                    _buildModulo(
                      icono: Icons.payments_outlined,
                      titulo: 'Validar Pagos',
                      subtitulo: 'Revisión de pagos pendientes.',
                      onTap: () => widget.onNavigate(1),
                    ),
                    const SizedBox(height: 8),
                    _buildModulo(
                      icono: Icons.calendar_today_outlined,
                      titulo: 'Gestión de Reservas',
                      subtitulo: 'Confirmar reservas de áreas deportivas.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminGestionReservasScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModulo(
                      icono: Icons.bar_chart_outlined,
                      titulo: 'Ver Reportes',
                      subtitulo: 'Estadísticas mensuales.',
                      onTap: () => widget.onNavigate(3),
                    ),
                    const SizedBox(height: 8),
                    _buildModulo(
                      icono: Icons.receipt_long_outlined,
                      titulo: 'Gestión de Alícuotas',
                      subtitulo:
                          'Generar alícuotas mensuales para todos los residentes.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminGestionAlicuotasScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTarjetaResumen({
    required IconData icono,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Container(
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(valor,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildModulo({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
