import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'admin_detalle_solicitud_screen.dart';

class AdminUsuariosRegistradosScreen extends StatefulWidget {
  const AdminUsuariosRegistradosScreen({super.key});

  @override
  State<AdminUsuariosRegistradosScreen> createState() =>
      _AdminUsuariosRegistradosScreenState();
}

class _AdminUsuariosRegistradosScreenState
    extends State<AdminUsuariosRegistradosScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  late TabController _tabController;
  List _usuarios = [];
  bool _loading = true;
  String _filtroEstado = 'todos';

  final List<Map<String, String>> _filtrosEstado = [
    {'key': 'todos', 'label': 'Todos'},
    {'key': 'aprobado', 'label': 'Activos'},
    {'key': 'rechazado', 'label': 'Rechazados'},
    {'key': 'desactivado', 'label': 'Desactivados'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final miId = await _storage.read(key: 'usuario_id') ?? '';
      final res = await _api.get('/usuarios/todos');
      if (!mounted) return;
      setState(() {
        // Excluir mi propia cuenta de administrador
        _usuarios = (res.data as List).where((u) => u['id'] != miId).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List _filtrar(String rol) {
    List base;
    if (rol == 'todos') {
      base = List.from(_usuarios);
    } else {
      base = _usuarios.where((u) => u['rol'] == rol).toList();
    }
    if (_filtroEstado == 'todos') return base;
    return base.where((u) => u['estado'] == _filtroEstado).toList();
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return AppColors.success;
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return AppColors.error;
      case 'desactivado':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return 'ACTIVO';
      case 'pendiente':
        return 'PENDIENTE';
      case 'rechazado':
        return 'RECHAZADO';
      case 'desactivado':
        return 'DESACTIVADO';
      default:
        return estado.toUpperCase();
    }
  }

  String _labelRol(String rol) {
    switch (rol) {
      case 'residente':
        return 'Residente';
      case 'guardia':
        return 'Guardia';
      case 'administrador':
        return 'Administrador';
      default:
        return rol;
    }
  }

  // Obtiene la foto del usuario sin importar el rol
  String _fotoDe(Map usuario) {
    return (usuario['residente']?['foto_url'] ??
            usuario['guardia']?['foto_url'] ??
            usuario['administrador']?['foto_url'] ??
            '')
        .toString();
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
        title: const Text('Usuarios Registrados',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Residentes'),
            Tab(text: 'Guardias'),
            Tab(text: 'Administradores'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros de estado
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filtrosEstado.length,
                      itemBuilder: (context, index) {
                        final filtro = _filtrosEstado[index];
                        final isSelected = _filtroEstado == filtro['key'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _filtroEstado = filtro['key']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                filtro['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLista(_filtrar('todos')),
                      _buildLista(_filtrar('residente')),
                      _buildLista(_filtrar('guardia')),
                      _buildLista(_filtrar('administrador')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLista(List usuarios) {
    if (usuarios.isEmpty) {
      return const Center(
        child: Text('No hay usuarios en esta categoría',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final usuario = usuarios[index];
          final nombres = usuario['nombres'] ?? '';
          final apellidos = usuario['apellidos'] ?? '';
          final rol = usuario['rol'] ?? '';
          final estado = usuario['estado'] ?? '';
          final fotoUrl = _fotoDe(usuario);

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminDetalleSolicitudScreen(
                  usuario: usuario,
                  onActualizado: _cargar,
                ),
              ),
            ).then((_) => _cargar()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                    child: fotoUrl.isEmpty
                        ? Text(
                            nombres.isNotEmpty ? nombres[0].toUpperCase() : 'U',
                            style: const TextStyle(
                                fontSize: 18,
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
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        Text(_labelRol(rol),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _colorEstado(estado).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_labelEstado(estado),
                        style: TextStyle(
                            fontSize: 9,
                            color: _colorEstado(estado),
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.remove_red_eye_outlined,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
