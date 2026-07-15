import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_gestion_usuarios_screen.dart';
import 'admin_crear_guardia_screen.dart';
import 'admin_gestion_reservas_screen.dart';
import 'admin_gestion_alicuotas_screen.dart';
import 'admin_gestion_manzanas_screen.dart';

class AdminGestionesScreen extends StatelessWidget {
  const AdminGestionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Gestiones Administrativas',
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
            const Text('Herramientas de administración',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _buildModulo(
              context,
              icono: Icons.security_outlined,
              titulo: 'Creación de Guardia',
              subtitulo: 'Registrar nuevos guardias de seguridad.',
              destino: const AdminCrearGuardiaScreen(),
            ),
            const SizedBox(height: 10),
            _buildModulo(
              context,
              icono: Icons.manage_accounts_outlined,
              titulo: 'Gestión de Usuarios',
              subtitulo: 'Validar residentes y administrar cuentas.',
              destino: const AdminGestionUsuariosScreen(),
            ),
            const SizedBox(height: 10),
            _buildModulo(
              context,
              icono: Icons.calendar_today_outlined,
              titulo: 'Gestión de Reservas',
              subtitulo: 'Confirmar reservas de áreas sociales.',
              destino: const AdminGestionReservasScreen(),
            ),
            const SizedBox(height: 10),
            _buildModulo(
              context,
              icono: Icons.receipt_long_outlined,
              titulo: 'Gestión de Alícuotas',
              subtitulo: 'Generar alícuotas mensuales.',
              destino: const AdminGestionAlicuotasScreen(),
            ),
            const SizedBox(height: 10),
            _buildModulo(
              context,
              icono: Icons.maps_home_work_outlined,
              titulo: 'Gestión de Manzanas',
              subtitulo: 'Crear manzanas y villas de la urbanización.',
              destino: const AdminGestionManzanasScreen(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModulo(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destino),
      ),
      borderRadius: BorderRadius.circular(12),
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
              child: Icon(icono, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
