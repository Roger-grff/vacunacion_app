import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario_modelo.dart';
import '../../models/sector_modelo.dart';
import '../../providers/sector_proveedor.dart';

class DetalleUsuarioVista extends StatelessWidget {
  final UserModel user;

  const DetalleUsuarioVista({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final sectorProvider = Provider.of<SectorProvider>(context, listen: false);
    final sectorName = sectorProvider.sectors.firstWhere(
      (s) => s.id == user.sectorId,
      orElse: () => SectorModel(id: '', nombre: 'Sin Asignar / Global', parroquia: '', zona: '', activo: false),
    ).nombre;

    String formatRole(String rol) {
      if (rol == 'coordinador_campana') return 'Coordinador de Campaña';
      if (rol == 'coordinador_brigada') return 'Coordinador de Brigada';
      return 'Vacunador / Brigadista';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Usuario'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar de Perfil Estilizado
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF203A43),
                    child: Text(
                      '${user.nombres[0]}${user.apellidos[0]}'.toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.nombreCompleto.toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(
                      formatRole(user.rol),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF2C5364),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card: Información Personal y de Contacto
            _buildInfoCard(
              title: 'Información de Contacto',
              icon: Icons.contact_mail_outlined,
              children: [
                _buildInfoRow('Cédula de Identidad:', user.cedula),
                _buildInfoRow('Correo Electrónico:', user.correo),
                _buildInfoRow('Teléfono Móvil:', user.telefono),
              ],
            ),
            const SizedBox(height: 16),

            // Card: Detalles Administrativos
            _buildInfoCard(
              title: 'Detalles Administrativos',
              icon: Icons.admin_panel_settings_outlined,
              children: [
                _buildInfoRow('Sector Asignado:', sectorName, isHighlight: true),
                _buildInfoRow('ID de Usuario (UID):', user.uid, isCode: true),
                _buildInfoRow(
                  'Primer Inicio de Sesión:',
                  user.cambioPassword ? 'Clave Temporal Pendiente' : 'Clave Personalizada Establecida',
                  valueColor: user.cambioPassword ? Colors.orange[800] : Colors.green[800],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF203A43), size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                ),
              ],
            ),
            const Divider(height: 24),
            Column(
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isCode = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                fontFamily: isCode ? 'Courier' : null,
                color: valueColor ?? (isHighlight ? const Color(0xFF2C5364) : Colors.black87),
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
