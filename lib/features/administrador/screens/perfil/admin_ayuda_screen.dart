import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class AdminAyudaScreen extends StatelessWidget {
  const AdminAyudaScreen({super.key});

  // Datos de los desarrolladores
  static const List<Map<String, String>> _desarrolladores = [
    {
      'nombre': 'Jhonas López Panta',
      'rol': 'Desarrollador',
      'whatsapp': '593978897935',
      'correo': 'vrjhonas.lopez@gmail.com',
    },
    {
      'nombre': 'Belky Piedra Jiménez',
      'rol': 'Desarrolladora',
      'whatsapp': '593980634788',
      'correo': 'belkypiedraj@gmail.com',
    },
  ];

  Future<void> _abrirWhatsApp(
      BuildContext context, String numero, String nombre) async {
    final mensaje = Uri.encodeComponent(
        'Hola $nombre, necesito ayuda con la aplicación UrbanApp.');
    final uri = Uri.parse('https://wa.me/$numero?text=$mensaje');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _abrirCorreo(BuildContext context, String correo) async {
    final asunto = Uri.encodeComponent('Soporte UrbanApp');
    final cuerpo =
        Uri.encodeComponent('Hola, necesito ayuda con la aplicación UrbanApp.');
    final uri = Uri.parse('mailto:$correo?subject=$asunto&body=$cuerpo');

    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el correo'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        title: const Text('Ayuda y Soporte',
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
            // Encabezado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.support_agent_outlined,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Equipo de Desarrollo UrbanApp',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Si necesitas ayuda o quieres reportar un problema, contáctanos por WhatsApp o correo.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('CONTACTAR AL EQUIPO',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
            ),

            ..._desarrolladores.map((dev) => _buildTarjetaDev(context, dev)),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaDev(BuildContext context, Map<String, String> dev) {
    final nombre = dev['nombre']!;
    final rol = dev['rol']!;
    final whatsapp = dev['whatsapp']!;
    final correo = dev['correo']!;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'D';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Datos del desarrollador
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(inicial,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(rol,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botones de contacto
          Row(
            children: [
              Expanded(
                child: _buildBotonContacto(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _abrirWhatsApp(context, whatsapp, nombre),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonContacto(
                  icon: Icons.email_outlined,
                  label: 'Correo',
                  color: AppColors.primary,
                  onTap: () => _abrirCorreo(context, correo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonContacto({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
