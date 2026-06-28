import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sector_proveedor.dart';

class ManageSectorsView extends StatelessWidget {
  const ManageSectorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final sectorProvider = Provider.of<SectorProvider>(context);
    final sectors = sectorProvider.sectors;

    return Scaffold(
      body: sectors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_city,
                    size: 70,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "No hay sectores registrados",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
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
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF203A43),
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      sector.nombre.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Parroquia: ${sector.parroquia}"),
                          Text("Zona: ${sector.zona}"),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                sector.activo
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: sector.activo
                                    ? Colors.green
                                    : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sector.activo ? "Activo" : "Inactivo",
                                style: TextStyle(
                                  color: sector.activo
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}