import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'guardia_escaneo_screen.dart';
import 'guardia_acceso_historial_screen.dart';
import 'guardia_perfil_screen.dart';

class GuardiaHomeScreen extends StatefulWidget {
  const GuardiaHomeScreen({super.key});

  @override
  State<GuardiaHomeScreen> createState() => _GuardiaHomeScreenState();
}

class _GuardiaHomeScreenState extends State<GuardiaHomeScreen> {
  int _currentIndex = 0;
  final _inicioKey = GlobalKey<_GuardiaInicioScreenState>();
  final _historialKey = GlobalKey<GuardiaAccesoHistorialScreenState>();

  void _navegarA(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GuardiaEscaneoScreen()),
      ).then((_) {
        _inicioKey.currentState?._cargar();
        _historialKey.currentState?.recargar();
      });
      return;
    }
    setState(() => _currentIndex = index);
    _recargarPantalla(index);
  }

  // Recarga la pantalla que se acaba de seleccionar
  void _recargarPantalla(int index) {
    // index 0 = inicio, index 2 = historial (por el hueco del escaneo en 1)
    if (index == 0) {
      _inicioKey.currentState?._cargar();
    } else if (index == 2) {
      _historialKey.currentState?.recargar();
    }
  }

  int get _stackIndex => _currentIndex > 1 ? _currentIndex - 1 : _currentIndex;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      GuardiaInicioScreen(key: _inicioKey, onNavigate: _navegarA),
      GuardiaAccesoHistorialScreen(key: _historialKey),
      const GuardiaPerfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuardiaEscaneoScreen()),
            ).then((_) {
              _inicioKey.currentState?._cargar();
              _historialKey.currentState?.recargar();
            });
            return;
          }
          setState(() => _currentIndex = index);
          _recargarPantalla(index);
        },
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Escaneo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
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

class GuardiaInicioScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const GuardiaInicioScreen({super.key, required this.onNavigate});

  @override
  State<GuardiaInicioScreen> createState() => _GuardiaInicioScreenState();
}

class _GuardiaInicioScreenState extends State<GuardiaInicioScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  Map<String, dynamic>? _usuario;
  int _ingresosHoy = 0;
  bool _loading = true;

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
      final resUser = await _api.get('/usuarios/$userId');

      int ingresosHoy = 0;
      try {
        final guardiaId = resUser.data['guardia']?['id'] ?? '';
        final hoy = DateTime.now();
        final fechaStr =
            '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
        final resIngresos = await _api.get(
          '${ApiConstants.ingresos}?fecha=$fechaStr&guardia_id=$guardiaId',
        );
        final ingresos = resIngresos.data as List;
        ingresosHoy = ingresos.length;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _usuario = resUser.data;
        _ingresosHoy = ingresosHoy;
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
        title: const Text('Urban App',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18)),
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
                      child: Row(
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
                                        : 'G',
                                    style: const TextStyle(
                                        fontSize: 24,
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule_outlined,
                                          color: AppColors.primary, size: 14),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.people_outline,
                                color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('INGRESOS DEL DÍA',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                              Text('$_ingresosHoy',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => widget.onNavigate(1),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner,
                                color: AppColors.white, size: 48),
                            SizedBox(height: 8),
                            Text('INICIAR\nESCANEO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ],
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
}
