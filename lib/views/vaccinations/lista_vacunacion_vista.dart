import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/autenticacion_proveedor.dart';
import '../../providers/vacunacion_proveedor.dart';
import '../../models/vacunacion_modelo.dart';
import '../../models/usuario_modelo.dart';
import 'registrar_vacunacion_vista.dart';

class VaccinationListView extends StatefulWidget {
  const VaccinationListView({super.key});

  @override
  State<VaccinationListView> createState() => _VaccinationListViewState();
}

class _VaccinationListViewState extends State<VaccinationListView> {
  @override
  void initState() {
    super.initState();
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

  // Comprobar si el usuario actual tiene permisos para editar un registro específico
  bool _canEditRecord(UserModel? user, VaccinationModel record) {
    if (user == null) return false;
    if (user.rol == 'coordinador_brigada' && user.sectorId == record.sectorId) {
      return true; // Coordinador puede editar cualquier registro de su sector
    }
    if (user.rol == 'vacunador' && record.vacunadorId == user.uid) {
      return true; // Vacunador puede editar solo sus propios registros
    }
    return false;
  }

  void _navigateToEdit(VaccinationModel record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterVaccinationView(vaccinationToEdit: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final vacProvider = Provider.of<VaccinationProvider>(context);
    final user = authProvider.userModel;

    // Combinar la lista en línea y pendientes locales para mostrarlas juntas
    final allRecords = [
      ...vacProvider.offlineVaccinations,
      ...vacProvider.onlineVaccinations,
    ];

    return Scaffold(
      floatingActionButton: user?.rol == 'vacunador'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterVaccinationView()),
                );
              },
              backgroundColor: const Color(0xFF203A43),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            )
          : null,
      body: allRecords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay registros de vacunación aún.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: allRecords.length,
              itemBuilder: (context, index) {
                final record = allRecords[index];
                final canEdit = _canEditRecord(user, record);
                final isOffline = record.syncState == 0;
                final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(record.fechaHora);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Tipo de mascota
                            Icon(
                              record.mascotaTipo == 'perro' ? Icons.pets : Icons.cruelty_free,
                              color: record.mascotaTipo == 'perro' ? Colors.brown : Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            // Nombre mascota
                            Text(
                              record.mascotaNombre.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Spacer(),
                            // Estado de sincronización
                            if (isOffline)
                              const Tooltip(
                                message: 'Guardado localmente (Offline)',
                                child: Chip(
                                  label: Text('Offline', style: TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                            else
                              const Icon(Icons.cloud_done, color: Colors.green, size: 20),
                          ],
                        ),
                        const Divider(),
                        // Detalles de Mascota
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Mascota: ${record.mascotaTipo == 'perro' ? 'Perro' : 'Gato'} • ${record.mascotaSexo} • ${record.mascotaEdad} años'),
                            Text('Vacuna: ${record.vacunaAplicada}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5364))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Detalles de Propietario
                        Text(
                          'Propietario: ${record.nombrePropietario} (C.I: ${record.propietarioCedula})',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                        Text(
                          'Teléfono: ${record.propietarioTelefono}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        // Observaciones
                        if (record.observaciones.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Obs: ${record.observaciones}',
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Ubicación y Fecha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📍 [${record.latitud.toStringAsFixed(4)}, ${record.longitud.toStringAsFixed(4)}]',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF2C5364)),
                            ),
                            Text(
                              dateFormatted,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        
                        // Botón de Edición
                        if (canEdit) ...[
                          const Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _navigateToEdit(record),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Corregir / Editar Registro'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF203A43),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

