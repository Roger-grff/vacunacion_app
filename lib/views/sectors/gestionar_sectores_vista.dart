import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sector_proveedor.dart';
import 'detalle_sector_vista.dart';

class ManageSectorsView extends StatefulWidget {
  const ManageSectorsView({super.key});

  @override
  State<ManageSectorsView> createState() => _ManageSectorsViewState();
}

class _ManageSectorsViewState extends State<ManageSectorsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectorProvider = Provider.of<SectorProvider>(context);
    final sectors = sectorProvider.sectors;

    // Filtrar los sectores según la búsqueda
    final filteredSectors = sectors.where((s) {
      final query = _searchQuery.toLowerCase();
      final name = s.nombre.toLowerCase();
      final parish = s.parroquia.toLowerCase();
      final zone = s.zona.toLowerCase();
      return name.contains(query) || parish.contains(query) || zone.contains(query);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Barra de Búsqueda
          if (sectors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar sector...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF203A43)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: sectors.isEmpty
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
                : filteredSectors.isEmpty
                    ? const Center(
                        child: Text(
                          "No se encontraron sectores",
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredSectors.length,
                        itemBuilder: (context, index) {
                          final sector = filteredSectors[index];

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetalleSectorVista(sector: sector),
                                  ),
                                );
                              },
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
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}