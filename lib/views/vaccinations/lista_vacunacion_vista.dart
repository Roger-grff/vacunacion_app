import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/autenticacion_proveedor.dart';
import '../../providers/vacunacion_proveedor.dart';
import '../../models/vacunacion_modelo.dart';
import '../../models/usuario_modelo.dart';
import 'registrar_vacunacion_vista.dart';
import 'detalle_vacunacion_vista.dart';

class VaccinationListView extends StatefulWidget {
  const VaccinationListView({super.key});

  @override
  State<VaccinationListView> createState() => _VaccinationListViewState();
}

class _VaccinationListViewState extends State<VaccinationListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    final filteredRecords = allRecords.where((record) {
      final query = _searchQuery.toLowerCase();
      final petName = record.mascotaNombre.toLowerCase();
      final ownerName = record.nombrePropietario.toLowerCase();
      final ownerCedula = record.propietarioCedula;
      final vaccine = record.vacunaAplicada.toLowerCase();
      return petName.contains(query) || ownerName.contains(query) || ownerCedula.contains(query) || vaccine.contains(query);
    }).toList();

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
      body: Column(
        children: [
          // Barra de Búsqueda
          if (allRecords.isNotEmpty)
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
                  hintText: 'Buscar por mascota, dueño, cédula o vacuna...',
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
            child: allRecords.isEmpty
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
                : filteredRecords.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron registros de vacunación.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                final canEdit = _canEditRecord(user, record);
                final isOffline = record.syncState == 0;
                final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(record.fechaHora);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetalleVacunacionVista(record: record),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Foto mascota
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildMascotaFoto(record.fotoUrl, record.mascotaTipo),
                          ),
                          const SizedBox(width: 12),
                          // Info central
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      record.mascotaTipo == 'perro' ? Icons.pets : Icons.cruelty_free,
                                      color: record.mascotaTipo == 'perro' ? Colors.brown : Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        record.mascotaNombre.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (isOffline)
                                      const Chip(
                                        label: Text(
                                          'Offline',
                                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: Colors.orange,
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )
                                    else
                                      const Icon(Icons.cloud_done, color: Colors.green, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${record.mascotaTipo == 'perro' ? 'Perro' : 'Gato'} • ${record.mascotaSexo} • ${record.mascotaEdad} años',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    children: [
                                      const TextSpan(text: 'Vacuna: '),
                                      TextSpan(
                                        text: record.vacunaAplicada,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C5364),
                                        ),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dueño: ${record.nombrePropietario}',
                                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: Color(0xFF2C5364)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        '[${record.latitud.toStringAsFixed(4)}, ${record.longitud.toStringAsFixed(4)}]',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF2C5364)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      dateFormatted,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Botón de edición o ver más
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (canEdit)
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF203A43)),
                                  tooltip: 'Editar Registro',
                                  onPressed: () => _navigateToEdit(record),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.only(top: 24.0, left: 8.0),
                                  child: Icon(Icons.chevron_right, color: Colors.grey),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMascotaFoto(String fotoUrl, String tipo) {
    if (fotoUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: tipo == 'perro' ? Colors.brown[100] : Colors.orange[100],
        child: Icon(
          tipo == 'perro' ? Icons.pets : Icons.cruelty_free,
          color: tipo == 'perro' ? Colors.brown[700] : Colors.orange[700],
          size: 30,
        ),
      );
    }

    if (fotoUrl.startsWith('http') || fotoUrl.startsWith('https')) {
      return Image.network(
        fotoUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(fotoUrl),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }
}

