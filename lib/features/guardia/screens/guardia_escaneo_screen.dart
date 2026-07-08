import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/input_formatters.dart';
import 'guardia_ingreso_manual_screen.dart';
import 'guardia_reporte_incidencia_screen.dart';

class GuardiaEscaneoScreen extends StatefulWidget {
  const GuardiaEscaneoScreen({super.key});

  @override
  State<GuardiaEscaneoScreen> createState() => _GuardiaEscaneoScreenState();
}

class _GuardiaEscaneoScreenState extends State<GuardiaEscaneoScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _placaCtrl = TextEditingController();

  bool _procesando = false;
  String _estado = 'escaneando';
  Map<String, dynamic>? _resultadoEscaneo;
  String _guardiaId = '';
  final String _bitacoraId = '';
  int _intentosFallidos = 0;
  String _codigoQrId = '';

  @override
  void initState() {
    super.initState();
    _cargarGuardia();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _placaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarGuardia() async {
    final userId = await _storage.read(key: 'usuario_id') ?? '';
    try {
      final res = await _api.get('/usuarios/$userId');
      final guardia = res.data['guardia'] ?? {};
      setState(() => _guardiaId = guardia['id'] ?? '');
    } catch (_) {}
  }

  Future<void> _escanear(String codigoHash) async {
    if (_procesando || codigoHash.isEmpty || _estado != 'escaneando') return;

    setState(() => _procesando = true);
    await Future.delayed(const Duration(milliseconds: 500));
    _scannerController.stop();

    try {
      final res = await _api.post(ApiConstants.validarQr, data: {
        'codigo_hash': codigoHash,
      });

      if (!mounted) return;
      setState(() {
        _resultadoEscaneo = res.data;
        _codigoQrId = res.data['codigo_qr_id'] ?? '';
        _estado = 'valido';
        _procesando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
        _intentosFallidos++;
        if (_intentosFallidos >= 3) {
          _estado = 'denegado';
        } else {
          _estado = 'invalido';
        }
      });
    }
  }

  void _reintentar() {
    setState(() {
      _estado = 'escaneando';
      _resultadoEscaneo = null;
      _procesando = false;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _scannerController.start();
    });
  }

  Future<void> _registrarIngreso() async {
    if (_placaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la placa del vehículo para continuar'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_placaCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La placa ingresada no es válida'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    try {
      await _api.post(ApiConstants.confirmarIngreso, data: {
        'codigo_qr_id': _codigoQrId,
        'guardia_id': _guardiaId,
        'bitacora_id': _bitacoraId.isNotEmpty ? _bitacoraId : null,
        'placa_vehiculo': _placaCtrl.text.trim(),
      });

      if (!mounted) return;
      setState(() {
        _estado = 'registrado';
        _procesando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo registrar el ingreso. Intenta de nuevo.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _estado == 'escaneando' ? Colors.black : AppColors.background,
      appBar: _estado == 'escaneando'
          ? AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Escaneo QR',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () => _scannerController.toggleTorch(),
                ),
              ],
            )
          : AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text('Acceso de Visitantes',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 16)),
              centerTitle: true,
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_estado) {
      case 'valido':
        return _buildValido();
      case 'invalido':
        return _buildInvalido();
      case 'denegado':
        return _buildDenegado();
      case 'registrado':
        return _buildRegistrado();
      default:
        return _buildEscaner();
    }
  }

  Widget _buildEscaner() {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final codigo = barcodes.first.rawValue ?? '';
                if (codigo.isNotEmpty) _escanear(codigo);
              }
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Listo para escanear',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ])),
                const SizedBox(height: 8),
                const Text(
                    'Alinee el código QR del visitante dentro del recuadro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ])),
                const SizedBox(height: 32),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('ACCESO PRINCIPAL',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ])),
              ],
            ),
          ),
          if (_procesando) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildValido() {
    final visitante = _resultadoEscaneo?['visitante'] ?? {};
    final nombreVisitante = visitante['nombre_visitante'] ?? '';
    final residente = _resultadoEscaneo?['residente'] ?? {};
    final nombreResidente =
        '${residente['nombres'] ?? ''} ${residente['apellidos'] ?? ''}'.trim();
    final manzana = residente['manzana'] ?? '';
    final villa = residente['villa'] ?? '';
    final horaIngreso = DateTime.now();

    return Container(
      color: AppColors.background,
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 12),
            const Text('Código Válido',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success)),
            const Text('Acceso permitido en urbanización',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFila(
                      Icons.person_outline, 'Visitante', nombreVisitante),
                  _buildFila(
                      Icons.people_outline, 'Residente', nombreResidente),
                  _buildFila(Icons.home_outlined, 'Dirección destino',
                      'Manzana $manzana, Villa $villa'),
                  _buildFila(Icons.access_time_outlined, 'Hora de ingreso',
                      '${horaIngreso.hour.toString().padLeft(2, '0')}:${horaIngreso.minute.toString().padLeft(2, '0')}'),
                  _buildFila(
                      Icons.login_outlined, 'Tipo de ingreso', 'AUTOMÁTICO'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
              child: TextField(
                controller: _placaCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [PlacaFormatter()],
                decoration: InputDecoration(
                  labelText: 'Placa del vehículo *',
                  hintText: 'Ej. ABC-1234',
                  prefixIcon: const Icon(Icons.directions_car_outlined,
                      color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Vehículos: ABC-1234 (con guión)  ·  Motos: AB123C (sin guión)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _registrarIngreso,
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text('Registrar Ingreso',
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
    );
  }

  Widget _buildInvalido() {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined,
                color: AppColors.error, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Código No Válido o Expirado',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error)),
          const SizedBox(height: 8),
          Text(
              'Intento $_intentosFallidos de 3. El código QR no es válido o ha expirado.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _reintentar,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Reintentar Escaneo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _buildDenegado() {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block_outlined,
                color: AppColors.error, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Ingreso Denegado',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error)),
          const SizedBox(height: 8),
          const Text(
              'Se ha alcanzado el número máximo de intentos (3/3). El sistema ha denegado el acceso automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuardiaReporteIncidenciaScreen(
                    guardiaId: _guardiaId,
                  ),
                ),
              ),
              icon: const Icon(Icons.report_outlined),
              label: const Text('Generar Reporte de Incidencia',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GuardiaIngresoManualScreen(guardiaId: _guardiaId),
                ),
              ),
              icon: const Icon(Icons.person_add_outlined,
                  color: AppColors.primary),
              label: const Text('Realizar Ingreso Manual',
                  style: TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrado() {
    final visitante = _resultadoEscaneo?['visitante'] ?? {};
    final nombreVisitante = visitante['nombre_visitante'] ?? '';
    final residente = _resultadoEscaneo?['residente'] ?? {};
    final nombreResidente =
        '${residente['nombres'] ?? ''} ${residente['apellidos'] ?? ''}'.trim();
    final manzana = residente['manzana'] ?? '';
    final villa = residente['villa'] ?? '';
    final horaIngreso = DateTime.now();
    final placa = _placaCtrl.text.trim();

    return Container(
      color: AppColors.background,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Ingreso Registrado Correctamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success)),
          const SizedBox(height: 8),
          const Text('El acceso ha sido validado y registrado en el sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFila(Icons.person_outline, 'Visitante', nombreVisitante),
                _buildFila(Icons.people_outline, 'Residente', nombreResidente),
                _buildFila(Icons.home_outlined, 'Dirección',
                    'Manzana $manzana, Villa $villa'),
                _buildFila(Icons.directions_car_outlined, 'Placa', placa),
                _buildFila(Icons.access_time_outlined, 'Hora',
                    '${horaIngreso.hour.toString().padLeft(2, '0')}:${horaIngreso.minute.toString().padLeft(2, '0')}'),
                _buildFila(Icons.login_outlined, 'Ingreso', 'AUTOMÁTICO'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Finalizar →',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFila(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(valor,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
