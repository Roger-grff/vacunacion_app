import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_proveedor.dart';
import '../../providers/vacunacion_proveedor.dart';
import '../../providers/sector_proveedor.dart';
import '../../models/sector_modelo.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    // Iniciar escucha de vacunaciones según rol y sector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final vacProvider = Provider.of<VaccinationProvider>(context, listen: false);
      final user = auth.userModel;

      if (user != null) {
        if (user.rol == 'coordinador_campana') {
          vacProvider.listenToVaccinations();
        } else if (user.rol == 'coordinador_brigada') {
          vacProvider.listenToVaccinations(sectorId: user.sectorId);
        } else {
          vacProvider.listenToVaccinations(vacunadorId: user.uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final vacProvider = Provider.of<VaccinationProvider>(context);
    final sectorProvider = Provider.of<SectorProvider>(context);
    final user = authProvider.userModel;

    // Combinar listas online y offline de vacunación para estadísticas integrales
    final allVaccinations = [
      ...vacProvider.onlineVaccinations,
      ...vacProvider.offlineVaccinations,
    ];

    // Cálculos
    final total = allVaccinations.length;
    final perros = allVaccinations.where((v) => v.mascotaTipo == 'perro').length;
    final gatos = allVaccinations.where((v) => v.mascotaTipo == 'gato').length;

    // Vacunaciones por sector
    final sectorCounts = <String, int>{};
    for (var v in allVaccinations) {
      final sectorName = sectorProvider.sectors.firstWhere(
        (s) => s.id == v.sectorId,
        orElse: () => SectorModel(id: '', nombre: 'Sector Desconocido', parroquia: '', zona: '', activo: false),
      ).nombre;
      sectorCounts[sectorName] = (sectorCounts[sectorName] ?? 0) + 1;
    }

    // Vacunaciones por vacunador (solo para coordinadores)
    final vacunadorCounts = <String, int>{};
    for (var v in allVaccinations) {
      final name = v.nombrePropietario.isNotEmpty ? v.vacunadorId : 'Vacunador';
      vacunadorCounts[name] = (vacunadorCounts[name] ?? 0) + 1;
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await vacProvider.syncPendingVaccinations();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje de Bienvenida personalizado
              Text(
                'Hola, ${user?.nombres ?? 'Usuario'}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen de la campaña de vacunación',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Alerta de sincronización pendiente
              if (vacProvider.pendingSyncCount > 0)
                Card(
                  color: Colors.orange[100],
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off, color: Colors.orange, size: 36),
                    title: const Text(
                      'Registros pendientes de sincronizar',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD84315)),
                    ),
                    subtitle: Text('Tienes ${vacProvider.pendingSyncCount} registros guardados localmente.'),
                    trailing: ElevatedButton(
                      onPressed: vacProvider.isSyncing
                          ? null
                          : () => vacProvider.syncPendingVaccinations(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Subir'),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Tarjetas principales
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Vacunados',
                      value: '$total',
                      icon: Icons.assignment,
                      color: const Color(0xFF203A43),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Perros',
                      value: '$perros',
                      icon: Icons.pets,
                      color: Colors.brown[400]!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Gatos',
                      value: '$gatos',
                      icon: Icons.cruelty_free,
                      color: Colors.orange[400]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Estadísticas avanzadas
              const Text(
                'Vacunaciones por Sector',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
              ),
              const SizedBox(height: 8),
              if (sectorCounts.isEmpty)
                _buildEmptyState('No hay registros por sector aún.')
              else
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: sectorCounts.entries.map((entry) {
                        final percentage = total > 0 ? entry.value / total : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${entry.value} (${(percentage * 100).toStringAsFixed(1)}%)'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: percentage,
                                color: const Color(0xFF2C5364),
                                backgroundColor: Colors.grey[200],
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              
              if (user?.rol != 'vacunador') ...[
                const Text(
                  'Rendimiento por Vacunador (IDs)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                ),
                const SizedBox(height: 8),
                if (vacunadorCounts.isEmpty)
                  _buildEmptyState('No hay registros por vacunador aún.')
                else
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: vacunadorCounts.entries.map((entry) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF203A43),
                              foregroundColor: Colors.white,
                              child: Icon(Icons.person),
                            ),
                            title: Text('ID: ${entry.key.substring(0, min(8, entry.key.length))}...'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF203A43).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.value} vac.',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 36, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}

