import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sector_proveedor.dart';
import '../../models/sector_modelo.dart';

class ManageSectorsView extends StatefulWidget {
  const ManageSectorsView({super.key});

  @override
  State<ManageSectorsView> createState() => _ManageSectorsViewState();
}

class _ManageSectorsViewState extends State<ManageSectorsView> {
  final _sectorNameController = TextEditingController();

  @override
  void dispose() {
    _sectorNameController.dispose();
    super.dispose();
  }

  // Diálogo para crear un nuevo sector
  void _showCreateSectorDialog() {
    _sectorNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Sector'),
        content: TextField(
          controller: _sectorNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Sector',
            hintText: 'Ej. Sector Norte, Brigada A, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = _sectorNameController.text.trim();
              if (nombre.isEmpty) return;

              final provider = Provider.of<SectorProvider>(context, listen: false);
              final success = await provider.createSector(nombre);

              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Sector creado con éxito' : 'Error al crear sector'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF203A43)),
            child: const Text('Crear'),
          )
        ],
      ),
    );
  }

  // Diálogo para asignar coordinador
  void _showAssignCoordinatorDialog(SectorModel sector) {
    final provider = Provider.of<SectorProvider>(context, listen: false);
    final coordinadores = provider.coordinadoresDisponibles;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar Coord. a ${sector.nombre}'),
        content: coordinadores.isEmpty
            ? const Text('No hay coordinadores de brigada registrados en el sistema.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: coordinadores.length,
                  itemBuilder: (context, index) {
                    final coord = coordinadores[index];
                    final esAsignado = sector.coordinadorBrigadaId == coord.uid;

                    return ListTile(
                      title: Text(coord.nombreCompleto),
                      subtitle: Text(coord.correo),
                      trailing: esAsignado
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.add_circle_outline, color: Color(0xFF203A43)),
                      onTap: () async {
                        final success = await provider.assignCoordinator(sector.id, coord.uid);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Coordinador asignado con éxito' : 'Error al asignar'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectorProvider = Provider.of<SectorProvider>(context);
    final sectors = sectorProvider.sectors;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSectorDialog,
        backgroundColor: const Color(0xFF203A43),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Nuevo Sector'),
      ),
      body: sectors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay sectores creados todavía.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sectors.length,
              itemBuilder: (context, index) {
                final sector = sectors[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      sector.nombre.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sector.coordinadorBrigadaId != null
                                      ? 'Coordinador asignado (ID: ${sector.coordinadorBrigadaId!.substring(0, 8)}...)'
                                      : 'Sin coordinador asignado',
                                  style: TextStyle(
                                    color: sector.coordinadorBrigadaId != null ? Colors.black87 : Colors.red,
                                    fontWeight: sector.coordinadorBrigadaId != null ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.assignment_ind, color: Color(0xFF203A43)),
                      onPressed: () => _showAssignCoordinatorDialog(sector),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

