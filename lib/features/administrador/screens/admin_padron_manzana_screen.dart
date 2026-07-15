import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminPadronManzanaScreen extends StatefulWidget {
  final String manzana;
  const AdminPadronManzanaScreen({super.key, required this.manzana});

  @override
  State<AdminPadronManzanaScreen> createState() =>
      _AdminPadronManzanaScreenState();
}

class _AdminPadronManzanaScreenState extends State<AdminPadronManzanaScreen> {
  final _api = ApiService();
  List _padron = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/usuarios/padron/manzana/${widget.manzana}');
      if (!mounted) return;
      setState(() {
        _padron = res.data as List;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
        title: Text('Padrón - Manzana ${widget.manzana}',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: _padron.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.people_outline,
                            size: 56,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                              'No hay residentes reales en la manzana ${widget.manzana}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _padron.length,
                      itemBuilder: (context, i) {
                        final r = _padron[i];
                        final activo = r['activo'] == true;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
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
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text('V${r['villa']}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['nombres'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text('Cédula: ${r['cedula']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                    Text(
                                        'Mz ${r['manzana']} · Villa ${r['villa']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (activo
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(activo ? 'ACTIVO' : 'INACTIVO',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: activo
                                            ? AppColors.success
                                            : AppColors.error)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
