import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import 'reservas_comprobante_screen.dart';

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

  final List<String> _horas = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  bool get _requierePago {
    final precio =
        widget.area['tarifa_reserva'] ?? widget.area['precio_reserva'];
    if (precio == null) return false;
    final valor = double.tryParse(precio.toString()) ?? 0.0;
    return valor > 0;
  }

  int get _duracionMax {
    final nombre = widget.area['nombre']?.toString().toLowerCase() ?? '';
    if (nombre.contains('evento')) return 4;
    return 2;
  }

  int get _duracionMin {
    final nombre = widget.area['nombre']?.toString().toLowerCase() ?? '';
    if (nombre.contains('evento')) return 3;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _duracion = _duracionMin;
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (fecha != null) setState(() => _fecha = fecha);
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
      final horaPartes = _horaInicio.split(':');
      final inicio = DateTime(
        _fecha!.year,
        _fecha!.month,
        _fecha!.day,
        int.parse(horaPartes[0]),
        int.parse(horaPartes[1]),
      );
      final fin = inicio.add(Duration(hours: _duracion));

      String pad(int n) => n.toString().padLeft(2, '0');
      final inicioStr =
          '${inicio.year}-${pad(inicio.month)}-${pad(inicio.day)}T${pad(inicio.hour)}:${pad(inicio.minute)}:00';
      final finStr =
          '${fin.year}-${pad(fin.month)}-${pad(fin.day)}T${pad(fin.hour)}:${pad(fin.minute)}:00';

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
        if (e.toString().contains('409') ||
            e.toString().contains('Ya existe una reserva')) {
          mensaje = 'Ya existe una reserva para esta área en esa fecha y hora';
        } else if (e.toString().contains('400')) {
          if (e.toString().contains('disponible')) {
            mensaje = 'El horario seleccionado no esta disponible';
          } else if (e.toString().contains('horas')) {
            mensaje = 'La duracion no es valida para esta área';
          } else if (e.toString().contains('horario')) {
            mensaje = 'El horario no es valido para esta área';
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
    final precio = widget.area['precio_reserva'];

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
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports_outlined,
                            color: Colors.white54, size: 48),
                        const SizedBox(height: 8),
                        Text('Áreas Sociales',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(nombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
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
              child: Text(nombre,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
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
                  child: DropdownButtonFormField<String>(
                    value: _horaInicio,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    items: _horas
                        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _horaInicio = v ?? _horaInicio),
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
                    onChanged: (v) =>
                        setState(() => _duracion = v ?? _duracion),
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
