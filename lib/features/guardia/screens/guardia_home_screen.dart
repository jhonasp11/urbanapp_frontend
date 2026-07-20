import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'guardia_escaneo_screen.dart';
import 'guardia_acceso_historial_screen.dart';
import 'guardia_perfil_screen.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class GuardiaHomeScreen extends StatefulWidget {
  const GuardiaHomeScreen({super.key});

  @override
  State<GuardiaHomeScreen> createState() => _GuardiaHomeScreenState();
}

class _GuardiaHomeScreenState extends State<GuardiaHomeScreen>
    with WidgetsBindingObserver {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  int _currentIndex = 0;
  final _inicioKey = GlobalKey<_GuardiaInicioScreenState>();
  final _historialKey = GlobalKey<GuardiaAccesoHistorialScreenState>();

  bool _loading = true;
  bool _mostrarNav = false; // true solo si hay bitácora activa
  String _bitacoraId = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificar();
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => _verificarSilencioso());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _verificar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verificar() async {
    setState(() => _loading = true);
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final resUser = await _api.get('/usuarios/$userId');
      final guardiaId = resUser.data['guardia']?['id'] ?? '';

      Map<String, dynamic>? estado;
      try {
        final resEstado = await _api.get('/bitacora/estado/$guardiaId');
        estado = resEstado.data as Map<String, dynamic>;
      } catch (_) {}

      final enTurno = estado?['en_turno'] ?? false;
      final bitacoraActiva = estado?['bitacora_activa'];
      final cerradaPorVer = estado?['bitacora_cerrada_por_ver'];

      if (!mounted) return;
      setState(() {
        _bitacoraId = bitacoraActiva?['id'] ?? '';
        // Solo muestra el nav completo si está en turno, con bitácora activa y sin pantalla de cierre pendiente
        _mostrarNav =
            enTurno && bitacoraActiva != null && cerradaPorVer == null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verificarSilencioso() async {
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final resUser = await _api.get('/usuarios/$userId');
      final guardiaId = resUser.data['guardia']?['id'] ?? '';

      Map<String, dynamic>? estado;
      try {
        final resEstado = await _api.get('/bitacora/estado/$guardiaId');
        estado = resEstado.data as Map<String, dynamic>;
      } catch (_) {}

      final enTurno = estado?['en_turno'] ?? false;
      final bitacoraActiva = estado?['bitacora_activa'];
      final cerradaPorVer = estado?['bitacora_cerrada_por_ver'];
      final nuevoMostrarNav =
          enTurno && bitacoraActiva != null && cerradaPorVer == null;

      if (!mounted) return;
      // Solo actualiza si cambió, para no reconstruir innecesariamente
      if (nuevoMostrarNav != _mostrarNav) {
        setState(() {
          _bitacoraId = bitacoraActiva?['id'] ?? '';
          _mostrarNav = nuevoMostrarNav;
        });
        // Refresca la pantalla de inicio para que muestre el estado correcto
        _inicioKey.currentState?._cargar();
      }
    } catch (_) {}
  }

  void _navegarA(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuardiaEscaneoScreen(bitacoraId: _bitacoraId),
        ),
      ).then((_) {
        _inicioKey.currentState?._cargar();
        _historialKey.currentState?.recargar();
      });
      return;
    }
    setState(() => _currentIndex = index);
    _recargarPantalla(index);
  }

  void _recargarPantalla(int index) {
    if (index == 0) {
      _inicioKey.currentState?._cargar();
    } else if (index == 2) {
      _historialKey.currentState?.recargar();
    }
  }

  int get _stackIndex => _currentIndex > 1 ? _currentIndex - 1 : _currentIndex;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Sin bitácora activa (fuera de turno, iniciar bitácora o turno culminado)
    // → pantalla completa SIN barra de navegación
    if (!_mostrarNav) {
      return GuardiaInicioScreen(
        key: _inicioKey,
        onNavigate: _navegarA,
        onEstadoCambiado: _verificar,
      );
    }

    // Con bitácora activa → nav completo
    final List<Widget> screens = [
      GuardiaInicioScreen(
        key: _inicioKey,
        onNavigate: _navegarA,
        onEstadoCambiado: _verificar,
      ),
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
              MaterialPageRoute(
                builder: (_) => GuardiaEscaneoScreen(bitacoraId: _bitacoraId),
              ),
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
  final VoidCallback? onEstadoCambiado;
  const GuardiaInicioScreen({
    super.key,
    required this.onNavigate,
    this.onEstadoCambiado,
  });

  @override
  State<GuardiaInicioScreen> createState() => _GuardiaInicioScreenState();
}

class _GuardiaInicioScreenState extends State<GuardiaInicioScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  Map<String, dynamic>? _ultimaFinalizada;

  Map<String, dynamic>? _usuario;
  bool _loading = true;
  bool _iniciando = false;

  // Estado de bitácora/turno
  bool _enTurno = false;
  Map<String, dynamic>? _bitacoraActiva;
  Map<String, dynamic>? _bitacoraCerradaPorVer;
  Map<String, dynamic>? _turnoInfo;
  String _guardiaId = '';
  String get bitacoraId => _bitacoraActiva?['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final userId = await _storage.read(key: 'usuario_id') ?? '';
      final resUser = await _api.get('/usuarios/$userId');
      final guardiaId = resUser.data['guardia']?['id'] ?? '';

      Map<String, dynamic>? estado;
      try {
        final resEstado = await _api.get('/bitacora/estado/$guardiaId');
        estado = resEstado.data as Map<String, dynamic>;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _usuario = resUser.data;
        _guardiaId = guardiaId;
        _enTurno = estado?['en_turno'] ?? false;
        _turnoInfo = estado?['turno'];
        _bitacoraActiva = estado?['bitacora_activa'];
        _ultimaFinalizada = estado?['ultima_finalizada'];
        _bitacoraCerradaPorVer = estado?['bitacora_cerrada_por_ver'];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _iniciarBitacora() async {
    if (_iniciando) return;
    setState(() => _iniciando = true);
    try {
      await _api.post('/bitacora/iniciar', data: {'guardia_id': _guardiaId});
      await _cargar();
      widget.onEstadoCambiado?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _iniciando = false);
        String mensaje = 'No se pudo iniciar la bitácora';
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

  Future<void> _cerrarSesion() async {
    await _storage.deleteAll();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 1. Bitácora cerrada por ver → pantalla de turno culminado
    if (_bitacoraCerradaPorVer != null) {
      return _buildTurnoCulminado();
    }

    // 2. Fuera de turno → bloqueo total
    if (!_enTurno) {
      return _buildFueraDeTurno();
    }

    // 3. En turno sin bitácora iniciada → botón iniciar
    if (_bitacoraActiva == null) {
      return _buildIniciarBitacora();
    }

    // 4. En turno con bitácora activa → home normal
    return _buildHomeNormal();
  }

  Widget _buildHomeNormal() {
    final nombres = _usuario?['nombres'] ?? '';
    final apellidos = _usuario?['apellidos'] ?? '';
    final guardia = _usuario?['guardia'] ?? {};
    final fotoUrl = guardia['foto_url'] ?? '';
    final nombreTurno = _turnoInfo?['nombre'] ?? '';
    final horaInicio = _turnoInfo?['hora_inicio'] ?? '';
    final horaFin = _turnoInfo?['hora_fin'] ?? '';

    final resumen = _bitacoraActiva?['resumen'] ?? {};
    final total = resumen['total'] ?? 0;
    final automaticos = resumen['automaticos'] ?? 0;
    final manuales = resumen['manuales'] ?? 0;
    final incidencias = resumen['incidencias'] ?? 0;

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
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta guardia + turno
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage:
                          fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                      child: fotoUrl.isEmpty
                          ? Text(
                              nombres.isNotEmpty
                                  ? nombres[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary))
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
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
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
                                    color: AppColors.primary, size: 14),
                                const SizedBox(width: 6),
                                Text('$nombreTurno • $horaInicio - $horaFin',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
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

              const Text('Resumen del Turno',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                      child: _tarjetaResumen('Total Ingresos', '$total',
                          AppColors.primary, Icons.people_outline)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _tarjetaResumen('Automáticos', '$automaticos',
                          AppColors.success, Icons.qr_code_scanner_outlined)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _tarjetaResumen('Manuales', '$manuales',
                          Colors.orange, Icons.person_add_outlined)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _tarjetaResumen('Incidencias', '$incidencias',
                          AppColors.error, Icons.warning_amber_outlined)),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
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
                            offset: const Offset(0, 8)),
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
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaResumen(
      String label, String valor, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(valor,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // Pantalla: fuera de turno (bloqueo total)
  Widget _buildFueraDeTurno() {
    final nombreTurno = _turnoInfo?['nombre'] ?? '';
    final horaInicio = _turnoInfo?['hora_inicio'] ?? '';
    final horaFin = _turnoInfo?['hora_fin'] ?? '';
    final hayBitacora = _ultimaFinalizada != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.error, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Sistema Bloqueado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const Text(
                'Por seguridad, las funciones del sistema están bloqueadas fuera de tu horario de turno.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (nombreTurno.toString().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Tu turno: $nombreTurno ($horaInicio - $horaFin)',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Aviso + botón para descargar la última bitácora
              if (hayBitacora) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Puedes descargar tu última bitácora generada.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final bitacoraId = _ultimaFinalizada?['id'] ?? '';
                      if (bitacoraId.isEmpty) return;
                      try {
                        final token = await _storage.read(key: 'token') ?? '';
                        final url =
                            '${ApiConstants.baseUrl}/bitacora/$bitacoraId/pdf';
                        final dir = await getApplicationDocumentsDirectory();
                        final filePath = '${dir.path}/bitacora.pdf';
                        await Dio().download(
                          url,
                          filePath,
                          options: Options(
                              headers: {'Authorization': 'Bearer $token'}),
                        );
                        await OpenFilex.open(filePath);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al descargar el PDF'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        color: AppColors.primary),
                    label: const Text('Descargar última bitácora',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
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

  // Pantalla: iniciar bitácora
  Widget _buildIniciarBitacora() {
    final nombreTurno = _turnoInfo?['nombre'] ?? '';
    final horaInicio = _turnoInfo?['hora_inicio'] ?? '';
    final horaFin = _turnoInfo?['hora_fin'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined,
                    color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Iniciar Bitácora del Turno',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const Text(
                'Estás dentro de tu horario de turno. Inicia la bitácora para comenzar a registrar los accesos del día.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (nombreTurno.toString().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('$nombreTurno ($horaInicio - $horaFin)',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _iniciando ? null : _iniciarBitacora,
                  icon: _iniciando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar Bitácora',
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

  // Pantalla: turno culminado
  Widget _buildTurnoCulminado() {
    final b = _bitacoraCerradaPorVer ?? {};
    final total = b['total_ingresos'] ?? 0;
    final incidencias = b['total_incidencias'] ?? 0;
    final turno = b['turno'] ?? {};
    final nombreTurno = turno['nombre'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Turno Culminado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Tu turno $nombreTurno ha finalizado. Este es el resumen de tu bitácora.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _tarjetaResumen('Total Ingresos', '$total',
                          AppColors.primary, Icons.people_outline)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _tarjetaResumen('Incidencias', '$incidencias',
                          AppColors.error, Icons.warning_amber_outlined)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final bitacoraId = b['id'] ?? '';
                    if (bitacoraId.isEmpty) return;
                    try {
                      final token = await _storage.read(key: 'token') ?? '';
                      final url =
                          '${ApiConstants.baseUrl}/bitacora/$bitacoraId/pdf';
                      final dir = await getApplicationDocumentsDirectory();
                      final filePath = '${dir.path}/bitacora.pdf';
                      await Dio().download(
                        url,
                        filePath,
                        options: Options(
                            headers: {'Authorization': 'Bearer $token'}),
                      );
                      await OpenFilex.open(filePath);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al descargar el PDF'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Descargar Reporte PDF',
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _api.patch('/bitacora/${b['id']}/vista');
                    } catch (_) {}
                    await _cerrarSesion();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
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
