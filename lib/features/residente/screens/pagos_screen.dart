import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'pagos_historial_screen.dart';
import 'subir_comprobante_screen.dart';
import 'estado_cuenta_screen.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  bool _loading = true;
  List _pendientes = [];
  String _residenteId = '';
  Set<String> _alicuotasConPagoPendiente = {};

  // Titularidad de la villa
  bool _esTitular = true;
  String _nombreTitular = '';
  bool _hayTitular = true;
  String _titularResidenteId = '';

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
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final residenteId = await _storage.read(key: 'residente_id') ?? '';
      _residenteId = residenteId;
      final titularFlag = await _storage.read(key: 'titular') ?? 'true';
      _esTitular = titularFlag == 'true';
      if (residenteId.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Residente NO titular: consulta las alícuotas y pagos de la villa (del titular)
      if (!_esTitular) {
        final resVilla =
            await _api.get('${ApiConstants.alicuotas}/villa/$residenteId');
        final data = resVilla.data as Map<String, dynamic>;
        final hayTitular = data['hay_titular'] == true;
        final alicuotas = (data['alicuotas'] as List?) ?? [];
        final pagos = (data['pagos'] as List?) ?? [];

        final alicuotasConPagoPendiente = <String>{};
        for (final pago in pagos) {
          if (pago['estado'] == 'pendiente') {
            final pagosAlicuotas = pago['pagos_alicuotas'] as List? ?? [];
            for (final pa in pagosAlicuotas) {
              alicuotasConPagoPendiente.add(pa['alicuota_id'].toString());
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _hayTitular = hayTitular;
          _nombreTitular = (data['titular_nombre'] ?? '').toString();
          _titularResidenteId = (data['titular_residente_id'] ?? '').toString();
          _pendientes =
              alicuotas.where((a) => a['estado'] == 'pendiente').toList()
                ..sort((a, b) {
                  final anioA = a['anio'] ?? 0;
                  final anioB = b['anio'] ?? 0;
                  final mesA = a['mes'] ?? 0;
                  final mesB = b['mes'] ?? 0;
                  if (anioA != anioB) return anioA.compareTo(anioB);
                  return mesA.compareTo(mesB);
                });
          _alicuotasConPagoPendiente = alicuotasConPagoPendiente;
          _loading = false;
        });
        return;
      }

      // Residente titular: flujo normal con sus propias alícuotas y pagos
      final resAlicuotas =
          await _api.get('${ApiConstants.alicuotas}/residente/$residenteId');
      final resPagos =
          await _api.get('${ApiConstants.pagos}/residente/$residenteId');

      final alicuotas = resAlicuotas.data as List;
      final pagos = resPagos.data as List;

      // IDs de alícuotas que tienen pago pendiente
      final alicuotasConPagoPendiente = <String>{};
      for (final pago in pagos) {
        if (pago['estado'] == 'pendiente') {
          final pagosAlicuotas = pago['pagos_alicuotas'] as List? ?? [];
          for (final pa in pagosAlicuotas) {
            alicuotasConPagoPendiente.add(pa['alicuota_id'].toString());
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _pendientes =
            alicuotas.where((a) => a['estado'] == 'pendiente').toList()
              ..sort((a, b) {
                final anioA = a['anio'] ?? 0;
                final anioB = b['anio'] ?? 0;
                final mesA = a['mes'] ?? 0;
                final mesB = b['mes'] ?? 0;
                if (anioA != anioB) return anioA.compareTo(anioB);
                return mesA.compareTo(mesB);
              });
        _alicuotasConPagoPendiente = alicuotasConPagoPendiente;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalDeuda => _pendientes.fold(0.0,
      (sum, a) => sum + (double.tryParse((a['monto'] ?? 0).toString()) ?? 0.0));

  // Determina si una alícuota está vencida comparando su fecha de
  // vencimiento con la fecha actual. Vencida = hoy es posterior al vencimiento.
  bool _estaVencida(String fechaVencimiento) {
    if (fechaVencimiento.isEmpty) return false;
    try {
      final venc = DateTime.parse(fechaVencimiento);
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      // Vencida solo si hoy es estrictamente posterior a la fecha de vencimiento
      return hoy.isAfter(venc);
    } catch (_) {
      return false;
    }
  }

  // Formatea 'YYYY-MM-DD' a 'DD/MM/YYYY'
  String _fechaLegible(String iso) {
    if (iso.length < 10) return iso;
    return '${iso.substring(8, 10)}/${iso.substring(5, 7)}/${iso.substring(0, 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final alDia = _pendientes.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Módulo de Pagos',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
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
                    if (!_esTitular) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _hayTitular
                                    ? 'La alícuota de tu villa es gestionada por el titular: $_nombreTitular. Solo el titular puede subir el pago.'
                                    : 'Tu villa no tiene un titular asignado actualmente. Contacta al administrador.',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: alDia
                          ? Row(
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
                                            fontSize: 36,
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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
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
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('SALDO PENDIENTE',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${_totalDeuda.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 36,
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
                                        color: AppColors.error
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('PENDIENTE',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Lista de meses pendientes
                                ..._pendientes.map((a) {
                                  final mes = a['mes'] ?? 0;
                                  final anio = a['anio'] ?? '';
                                  final nombreMes =
                                      mes > 0 && mes <= 12 ? _meses[mes] : '';
                                  final monto = double.tryParse(
                                          (a['monto'] ?? 0).toString()) ??
                                      0.0;
                                  final vencimiento = a['fecha_vencimiento']
                                          ?.toString()
                                          .substring(0, 10) ??
                                      '';
                                  final tienePagoPendiente =
                                      _alicuotasConPagoPendiente
                                          .contains(a['id'].toString());

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: tienePagoPendiente
                                          ? Colors.orange
                                              .withValues(alpha: 0.05)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: tienePagoPendiente
                                          ? Border.all(
                                              color: Colors.orange
                                                  .withValues(alpha: 0.3))
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('$nombreMes $anio',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary)),
                                            if (vencimiento.isNotEmpty)
                                              Text(
                                                  _estaVencida(vencimiento)
                                                      ? 'Venció: ${_fechaLegible(vencimiento)}'
                                                      : 'Vence: ${_fechaLegible(vencimiento)}',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: _estaVencida(
                                                              vencimiento)
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color: _estaVencida(
                                                              vencimiento)
                                                          ? AppColors.error
                                                          : AppColors
                                                              .textSecondary)),
                                            if (tienePagoPendiente)
                                              const Text(
                                                  'En revisión por el administrador',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.orange,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                          ],
                                        ),
                                        Text('\$${monto.toStringAsFixed(2)}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: tienePagoPendiente
                                                    ? Colors.orange
                                                    : (_estaVencida(vencimiento)
                                                        ? AppColors.error
                                                        : AppColors
                                                            .textPrimary))),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Solo el titular puede subir el pago
                                      if (!_esTitular) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(_nombreTitular.isEmpty
                                                ? 'Solo el titular de la villa puede subir el pago.'
                                                : 'Solo el titular ($_nombreTitular) puede subir el pago. Avísale para que lo gestione.'),
                                            backgroundColor: AppColors.primary,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }
                                      final alicuotasDisponibles = _pendientes
                                          .where((a) =>
                                              !_alicuotasConPagoPendiente
                                                  .contains(a['id'].toString()))
                                          .toList();

                                      if (alicuotasDisponibles.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Todos tus pagos están en revisión por el administrador'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SubirComprobanteScreen(
                                            alicuotas: alicuotasDisponibles,
                                            residenteId: _residenteId,
                                            totalDeuda: alicuotasDisponibles.fold(
                                                0.0,
                                                (sum, a) =>
                                                    sum +
                                                    (double.tryParse(
                                                            (a['monto'] ?? 0)
                                                                .toString()) ??
                                                        0.0)),
                                          ),
                                        ),
                                      ).then((_) => _cargar());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: const Text('Subir Comprobante',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Historial de Pagos',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PagosHistorialScreen(
                                userId: _esTitular
                                    ? _residenteId
                                    : _titularResidenteId,
                                nombreTitular:
                                    _esTitular ? null : _nombreTitular),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Consulta tu Historial de Pagos',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EstadoCuentaScreen(residenteId: _residenteId),
                          ),
                        ),
                        icon: const Icon(Icons.description_outlined,
                            size: 18, color: AppColors.primary),
                        label: const Text('Estado de Cuenta',
                            style: TextStyle(
                                fontSize: 15,
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'El saldo puede variar según la aprobación o rechazo de tus pagos por parte del administrador.',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Los pagos pueden tardar hasta 24 horas hábiles en verse reflejados en su historial de pagos.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
