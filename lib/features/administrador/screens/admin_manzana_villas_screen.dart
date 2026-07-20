import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminManzanaVillasScreen extends StatefulWidget {
  final int numeroManzana;
  const AdminManzanaVillasScreen({super.key, required this.numeroManzana});

  @override
  State<AdminManzanaVillasScreen> createState() =>
      _AdminManzanaVillasScreenState();
}

class _AdminManzanaVillasScreenState extends State<AdminManzanaVillasScreen> {
  final _api = ApiService();
  final _busquedaController = TextEditingController();

  List _villas = [];
  bool _loading = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _busquedaController.addListener(() {
      setState(() => _busqueda = _busquedaController.text.trim().toLowerCase());
    });
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res =
          await _api.get('/manzanas/numero/${widget.numeroManzana}/detalle');
      if (!mounted) return;
      setState(() {
        _villas = res.data['villas'] as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Filtra villas por número de villa o por nombre/cédula de algún residente
  List _villasFiltradas() {
    if (_busqueda.isEmpty) return _villas;
    return _villas.where((v) {
      final numeroVilla = v['villa'].toString();
      if (numeroVilla.contains(_busqueda)) return true;
      final residentes = (v['residentes'] as List?) ?? [];
      return residentes.any((r) {
        final nombre = (r['nombres'] ?? '').toString().toLowerCase();
        final cedula = (r['cedula'] ?? '').toString().toLowerCase();
        return nombre.contains(_busqueda) || cedula.contains(_busqueda);
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final villas = _villasFiltradas();
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
        title: Text('Manzana ${widget.numeroManzana}',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Buscador
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _busquedaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por villa, nombre o cédula',
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
                Expanded(
                  child: villas.isEmpty
                      ? const Center(
                          child: Text('No se encontraron villas',
                              style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: villas.length,
                            itemBuilder: (context, i) {
                              final v = villas[i];
                              final numeroVilla = v['villa'];
                              final residentes =
                                  (v['residentes'] as List?) ?? [];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cabecera de la villa
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text('$numeroVilla',
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          AppColors.primary)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text('Villa $numeroVilla',
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      AppColors.textPrimary)),
                                          const Spacer(),
                                          Text(
                                            residentes.isEmpty
                                                ? 'Sin residentes'
                                                : '${residentes.length} residente(s)',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (residentes.isNotEmpty) ...[
                                      const Divider(height: 1),
                                      ...residentes.map((r) {
                                        final tieneApp = r['tiene_app'] == true;
                                        final telefono =
                                            r['telefono']?.toString() ?? '';
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 12, 16, 12),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: AppColors
                                                    .primary
                                                    .withValues(alpha: 0.1),
                                                child: Text(
                                                  (r['nombres'] ?? 'R')
                                                      .toString()
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        '${r['nombres'] ?? ''}',
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .textPrimary)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                        'CI: ${r['cedula'] ?? ''}',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .textSecondary)),
                                                    Text(
                                                        'Tel: ${telefono.isEmpty ? 'No registrado' : telefono}',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .textSecondary)),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: tieneApp
                                                      ? AppColors.success
                                                          .withValues(
                                                              alpha: 0.12)
                                                      : Colors.orange
                                                          .withValues(
                                                              alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  tieneApp
                                                      ? 'CON APP'
                                                      : 'SIN APP',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: tieneApp
                                                          ? AppColors.success
                                                          : Colors.orange),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
