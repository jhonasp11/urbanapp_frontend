import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import 'reservas_comprobante_screen.dart';
import 'package:dio/dio.dart';

class ReservasNuevaScreen extends StatefulWidget {
  final Map<String, dynamic> area;
  final String residenteId;
  const ReservasNuevaScreen({
    super.key,
    required this.area,
    required this.residenteId,
  });

  @override
  State<ReservasNuevaScreen> createState() => _ReservasNuevaScreenState();
}

class _ReservasNuevaScreenState extends State<ReservasNuevaScreen> {
  final _api = ApiService();
  bool _isLoading = false;

  DateTime? _fecha;
  String _horaInicio = '09:00';
  int _duracion = 1;

  bool get _requierePago {
    final precio =
        widget.area['tarifa_reserva'] ?? widget.area['precio_reserva'];
    if (precio == null) return false;
    final valor = double.tryParse(precio.toString()) ?? 0.0;
    return valor > 0;
  }

  int get _duracionMax => widget.area['duracion_max_horas'] ?? 2;

  int get _duracionMin => widget.area['duracion_min_horas'] ?? 1;

  Map<String, dynamic>? get _horario {
    final h = widget.area['horarios'];
    if (h is List && h.isNotEmpty) return h.first as Map<String, dynamic>;
    return null;
  }

  int _horaDe(String? isoTime, int fallback) {
    if (isoTime == null) return fallback;
    try {
      return DateTime.parse(isoTime).toUtc().hour;
    } catch (_) {
      return int.tryParse(isoTime.split(':')[0]) ?? fallback;
    }
  }

  int get _horaAperturaMin => _horaDe(_horario?['hora_inicio']?.toString(), 7);

  int get _horaCierreMax => _horaDe(_horario?['hora_fin']?.toString(), 22);

  @override
  void initState() {
    super.initState();
    _duracion = _duracionMin;
    _horaInicio = '${_horaAperturaMin.toString().padLeft(2, '0')}:00';
  }

  Future<void> _seleccionarFecha() async {
    final anticipacion = widget.area['anticipacion_min_dias'] ?? 1;
    final minima = DateTime.now().add(Duration(days: anticipacion));
    final fecha = await showDatePicker(
      context: context,
      initialDate: minima,
      firstDate: minima,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (fecha != null) setState(() => _fecha = fecha);
  }

  // Selecciona la hora de inicio con una rueda de horas válidas del área
  Future<void> _seleccionarHoraInicio() async {
    // Horas donde la reserva cabe completa: desde apertura hasta (cierre - duración)
    final horaInicioMax = _horaCierreMax - _duracion;
    final List<int> horasDisponibles = [];
    for (int h = _horaAperturaMin; h <= horaInicioMax; h++) {
      horasDisponibles.add(h);
    }

    if (horasDisponibles.isEmpty) {
      _mostrarError('No hay horarios disponibles con esta duración');
      return;
    }

    // Índice inicial según la hora actual seleccionada
    final horaActual = int.parse(_horaInicio.split(':')[0]);
    int indiceInicial = horasDisponibles.indexOf(horaActual);
    if (indiceInicial < 0) indiceInicial = 0;

    int seleccionTemp = horasDisponibles[indiceInicial];

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Selecciona la hora de inicio',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Franja: ${_horaAperturaMin.toString().padLeft(2, '0')}:00 - ${_horaCierreMax.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: indiceInicial),
                    itemExtent: 44,
                    onSelectedItemChanged: (i) {
                      seleccionTemp = horasDisponibles[i];
                    },
                    children: horasDisponibles.map((h) {
                      final fin = h + _duracion;
                      return Center(
                        child: Text(
                          '${h.toString().padLeft(2, '0')}:00  →  ${fin.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _horaInicio =
                              '${seleccionTemp.toString().padLeft(2, '0')}:00';
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirmar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmarReserva() async {
    if (_fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha de reserva'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String pad(int n) => n.toString().padLeft(2, '0');

      final res = await _api.post(ApiConstants.reservas, data: {
        'residente_id': widget.residenteId,
        'area_id': widget.area['id'],
        'fecha_reserva':
            '${_fecha!.year}-${pad(_fecha!.month)}-${pad(_fecha!.day)}',
        'hora_inicio': _horaInicio,
        'hora_fin':
            '${(int.parse(_horaInicio.split(':')[0]) + _duracion).toString().padLeft(2, '0')}:00',
      });

      if (!mounted) return;

      if (_requierePago) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReservasComprobanteScreen(
              reserva: res.data,
              area: widget.area,
              residenteId: widget.residenteId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva confirmada exitosamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al crear la reserva';
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.area['nombre'] ?? '';
    final imagenUrl = (widget.area['imagen_url'] ?? '').toString();
    final capacidad = widget.area['capacidad_max'];
    final descripcion = (widget.area['descripcion'] ?? '').toString();

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
        title: const Text('Nueva Reserva',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header area
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagenUrl.isNotEmpty)
                    Image.network(
                      imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.sports_outlined,
                            color: Colors.white54, size: 48),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.sports_outlined,
                          color: Colors.white54, size: 48),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        if (capacidad != null)
                          Text('Capacidad: $capacidad personas',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Área social
            const Text('Área Social',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(descripcion,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fecha
            const Text('Fecha de Reserva',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _fecha != null
                          ? '${_fecha!.day.toString().padLeft(2, '0')}/${_fecha!.month.toString().padLeft(2, '0')}/${_fecha!.year}'
                          : 'mm/dd/yyyy',
                      style: TextStyle(
                          fontSize: 14,
                          color: _fecha != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Horario y duración
            const Text('Horario y Tiempo de Reserva',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _seleccionarHoraInicio,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            _horaInicio,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _duracion,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    items: List.generate(
                      _duracionMax - _duracionMin + 1,
                      (i) => DropdownMenuItem(
                        value: _duracionMin + i,
                        child: Text(
                            '${_duracionMin + i} ${_duracionMin + i == 1 ? 'Hora' : 'Horas'}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _duracion = v;
                        // Si la hora actual ya no cabe con la nueva duración, resetear a la apertura
                        final horaIni = int.parse(_horaInicio.split(':')[0]);
                        if (horaIni + _duracion > _horaCierreMax) {
                          _horaInicio =
                              '${_horaAperturaMin.toString().padLeft(2, '0')}:00';
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info precio
            if (_requierePago)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Esta área requiere pago de \$${double.tryParse((widget.area['tarifa_reserva'] ?? widget.area['precio_reserva'] ?? 0).toString())?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Confirmar Reserva',
              icon: Icons.check_circle_outline,
              isLoading: _isLoading,
              onPressed: _confirmarReserva,
            ),
          ],
        ),
      ),
    );
  }
}
