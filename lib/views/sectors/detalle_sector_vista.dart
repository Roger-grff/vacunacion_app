import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sector_modelo.dart';
import '../../models/usuario_modelo.dart';
import '../../providers/sector_proveedor.dart';
import '../users/detalle_usuario_vista.dart';

class DetalleSectorVista extends StatefulWidget {
  final SectorModel sector;

  const DetalleSectorVista({super.key, required this.sector});

  @override
  State<DetalleSectorVista> createState() => _DetalleSectorVistaState();
}

class _DetalleSectorVistaState extends State<DetalleSectorVista> {
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

    // 1. Encontrar el coordinador de brigada asignado a este sector
    UserModel? coordinator;
    try {
      coordinator = sectorProvider.coordinadoresDisponibles.firstWhere(
        (c) => c.sectorId == widget.sector.id,
      );
    } catch (_) {
      coordinator = null;
    }

    // 2. Filtrar los vacunadores asignados a este sector
    final allSectorVaccinators = sectorProvider.vaccinators.where(
      (v) => v.sectorId == widget.sector.id,
    ).toList();

    // 3. Aplicar filtro de búsqueda sobre los vacunadores
    final filteredVaccinators = allSectorVaccinators.where((v) {
      final query = _searchQuery.toLowerCase();
      final fullName = v.nombreCompleto.toLowerCase();
      final phone = v.telefono;
      final cedula = v.cedula;
      return fullName.contains(query) || phone.contains(query) || cedula.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sector.nombre.toUpperCase()),
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
      body: CustomScrollView(
        slivers: [
          // Sección 1: Información General del Sector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_city, color: Color(0xFF203A43)),
                          SizedBox(width: 8),
                          Text(
                            'Información Geográfica',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Nombre Sector:', widget.sector.nombre.toUpperCase(), isHighlight: true),
                      _buildInfoRow('Parroquia:', widget.sector.parroquia),
                      _buildInfoRow('Zona / Distrito:', widget.sector.zona),
                      _buildInfoRow(
                        'Estado de Actividad:',
                        widget.sector.activo ? 'Activo / En Campaña' : 'Inactivo',
                        valueColor: widget.sector.activo ? Colors.green[800] : Colors.red[800],
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sección 2: Coordinador de Brigada Asignado
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: Color(0xFF203A43)),
                          SizedBox(width: 8),
                          Text(
                            'Coordinador de Brigada',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (coordinator == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Sin Coordinador Asignado actualmente.',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        )
                      else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2C5364),
                            foregroundColor: Colors.white,
                            child: Text('${coordinator.nombres[0]}${coordinator.apellidos[0]}'.toUpperCase()),
                          ),
                          title: Text(
                            coordinator.nombreCompleto.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Tél: ${coordinator.telefono}\nEmail: ${coordinator.correo}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetalleUsuarioVista(user: coordinator!),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Cabecera de la sección de Vacunadores y Caja de Búsqueda
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vacunadores Asignados',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                      ),
                      Chip(
                        label: Text(
                          '${allSectorVaccinators.length} Total',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF203A43),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Input de búsqueda
                  if (allSectorVaccinators.isNotEmpty)
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar vacunador en este sector...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF203A43)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Lista de Vacunadores
          if (allSectorVaccinators.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No hay vacunadores asignados a este sector.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ),
            )
          else if (filteredVaccinators.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No se encontraron vacunadores con ese criterio.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vaccinator = filteredVaccinators[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2C5364).withOpacity(0.1),
                          foregroundColor: const Color(0xFF2C5364),
                          child: Text('${vaccinator.nombres[0]}${vaccinator.apellidos[0]}'.toUpperCase()),
                        ),
                        title: Text(
                          vaccinator.nombreCompleto.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text('Teléfono: ${vaccinator.telefono}\nC.I: ${vaccinator.cedula}', style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetalleUsuarioVista(user: vaccinator),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                childCount: filteredVaccinators.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
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
                color: valueColor ?? (isHighlight ? const Color(0xFF2C5364) : Colors.black87),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
