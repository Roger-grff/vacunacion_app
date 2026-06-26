import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vaccination_provider.dart';
import '../auth/login_view.dart';

class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key});

  void _syncData(BuildContext context, VaccinationProvider syncProvider) async {
    Navigator.of(context).pop(); // Cerrar drawer
    
    // Mostrar loading dialog de sincronización
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Consumer<VaccinationProvider>(
          builder: (context, provider, _) {
            return AlertDialog(
              title: const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Sincronizando...'),
                ],
              ),
              content: Text(
                'Subiendo ${provider.pendingSyncCount} registros y fotos pendientes.',
              ),
              actions: [
                if (!provider.isSyncing)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cerrar'),
                  ),
              ],
            );
          },
        );
      },
    );

    // Iniciar sincronización
    await syncProvider.syncPendingVaccinations();

    // Actualizar snackbar con el resultado
    if (context.mounted) {
      final finalPending = syncProvider.pendingSyncCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            finalPending == 0
                ? '¡Sincronización completada exitosamente!'
                : 'Sincronización incompleta. Quedan $finalPending registros pendientes.',
          ),
          backgroundColor: finalPending == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final vaccinationProvider = Provider.of<VaccinationProvider>(context);
    final user = authProvider.userModel;

    String formatRole(String? rol) {
      switch (rol) {
        case 'coordinador_campana':
          return 'Coordinador de Campaña';
        case 'coordinador_brigada':
          return 'Coordinador de Brigada';
        case 'vacunador':
          return 'Vacunador';
        default:
          return 'Usuario';
      }
    }

    return Drawer(
      child: Column(
        children: [
          // Cabecera del Drawer con perfil del usuario y colores modernos
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.nombres.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203A43),
                ),
              ),
            ),
            accountName: Text(
              user?.nombreCompleto ?? 'Cargando...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.correo ?? ''),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formatRole(user?.rol),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Opciones del Menú
          ListTile(
            leading: const Icon(Icons.sync, color: Color(0xFF203A43)),
            title: const Text('Sincronización Offline'),
            subtitle: Text('${vaccinationProvider.pendingSyncCount} pendientes'),
            trailing: vaccinationProvider.pendingSyncCount > 0
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${vaccinationProvider.pendingSyncCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
                : null,
            onTap: () => _syncData(context, vaccinationProvider),
          ),
          
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Color(0xFF203A43)),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.of(context).pop();
              // Mostrar información del perfil en un diálogo simple
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Configuración de Perfil'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cédula: ${user?.cedula}'),
                      const SizedBox(height: 8),
                      Text('Nombre: ${user?.nombreCompleto}'),
                      const SizedBox(height: 8),
                      Text('Teléfono: ${user?.telefono}'),
                      const SizedBox(height: 8),
                      Text('Correo: ${user?.correo}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Spacer(),
          const Divider(),
          
          // Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
