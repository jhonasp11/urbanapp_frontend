import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../shared/screens/notificaciones_screen.dart';

class HomeContentScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeContentScreen({super.key, required this.onNavigate});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  Map<String, dynamic>? _usuario;
  List _pendientes = [];
  bool _loading = true;
  int _notificacionesSinLeer = 0;

  final List<String> _meses = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final userId = await _storage.read(key: 'usuario_id');
      final nombresGuardados = await _storage.read(key: 'nombres') ?? '';

      if (userId == null) {
        if (mounted) {
          setState(() {
            _usuario = {
              'nombres': nombresGuardados,
              'apellidos': '',
              'residente': {'manzana': '', 'villa': ''}
            };
            _loading = false;
          });
        }
        return;
      }

      final resUser = await _api.get('/usuarios/$userId');
      final residenteId = resUser.data?['residente']?['id'];
      if (residenteId != null) {
        await _storage.write(
            key: 'residente_id', value: residenteId.toString());
      }

      final residenteIdFinal = residenteId?.toString() ?? '';
      final esTitular = resUser.data?['residente']?['titular'] == true;

      // El no titular ve el saldo de la villa (alícuotas del titular)
      List alicuotasCargadas;
      if (esTitular) {
        final resAlicuota = await _api
            .get('${ApiConstants.alicuotas}/residente/$residenteIdFinal');
        alicuotasCargadas = resAlicuota.data as List;
      } else {
        final resVilla =
            await _api.get('${ApiConstants.alicuotas}/villa/$residenteIdFinal');
        alicuotasCargadas = (resVilla.data['alicuotas'] as List?) ?? [];
      }

      int sinLeer = 0;
      try {
        final resNotif =
            await _api.get('${ApiConstants.notificaciones}/usuario/$userId');
        final todas = resNotif.data as List;
        sinLeer = todas.where((n) => n['leida'] == false).length;
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _usuario = resUser.data;
        _pendientes =
            alicuotasCargadas.where((a) => a['estado'] == 'pendiente').toList();
        _notificacionesSinLeer = sinLeer;
        _loading = false;
      });
    } catch (e) {
      final nombresGuardados = await _storage.read(key: 'nombres') ?? '';
      if (mounted) {
        setState(() {
          _usuario = {
            'nombres': nombresGuardados,
            'apellidos': '',
            'residente': {'manzana': '', 'villa': ''}
          };
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nombres = _usuario?['nombres'] ?? '';
    final apellidos = _usuario?['apellidos'] ?? '';
    final fotoUrl = _usuario?['residente']?['foto_url'] ?? '';
    final manzana = _usuario?['residente']?['manzana'] ?? '';
    final villa = _usuario?['residente']?['villa'] ?? '';
    final alDia = _pendientes.isEmpty;
    final totalDeuda = _pendientes.fold(
        0.0,
        (sum, a) =>
            sum + (double.tryParse((a['monto'] ?? 0).toString()) ?? 0.0));

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
                    .then((_) => _cargarDatos()),
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
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenida
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
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage:
                          fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                      child: fotoUrl.isEmpty
                          ? Text(
                              nombres.isNotEmpty
                                  ? nombres[0].toUpperCase()
                                  : 'R',
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
                          Text('Bienvenido, $nombres $apellidos',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Residente - Manzana $manzana - Villa $villa',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alicuota
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen de Alícuota',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    if (alDia) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ESTADO DE ALÍCUOTA',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                              SizedBox(height: 4),
                              Text('Al día ✓',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success)),
                              SizedBox(height: 4),
                              Text('No tienes pagos pendientes',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                '${_meses[DateTime.now().month].toUpperCase()} ${DateTime.now().year}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SALDO PENDIENTE',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '\$${totalDeuda.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary),
                              ),
                              Text(
                                '${_pendientes.length} ${_pendientes.length == 1 ? 'mes pendiente' : 'meses pendientes'}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('REVISAR PAGOS',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => widget.onNavigate(0),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text('Subir Comprobante',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Accesos
              const Text('Mis Accesos',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _buildCard(
                icon: Icons.qr_code_2,
                title: 'Generar Nuevo Acceso QR',
                subtitle: 'Crea accesos para tus visitantes',
                onTap: () => widget.onNavigate(1),
              ),
              const SizedBox(height: 16),

              // Reservas
              const Text('Mis Reservas',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _buildCard(
                icon: Icons.calendar_today_outlined,
                title: 'Generar Nueva Reserva',
                subtitle: 'Crea nuevas reservas en nuestras áreas sociales',
                onTap: () => widget.onNavigate(3),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
