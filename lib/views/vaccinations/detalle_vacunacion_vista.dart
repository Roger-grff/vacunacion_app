import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vacunacion_modelo.dart';

class DetalleVacunacionVista extends StatelessWidget {
  final VaccinationModel record;

  const DetalleVacunacionVista({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(record.fechaHora);
    final isOffline = record.syncState == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Vacunación'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cabecera con Foto de Mascota
            _buildFotoHeader(context),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Estado de sincronización
                  _buildSyncStatusBadge(isOffline),
                  const SizedBox(height: 16),

                  // 2. Sección: Datos de la Mascota
                  _buildSectionCard(
                    title: 'Datos de la Mascota',
                    icon: Icons.pets,
                    color: Colors.brown[400]!,
                    children: [
                      _buildDetailRow('Nombre:', record.mascotaNombre.toUpperCase(), isBoldValue: true),
                      _buildDetailRow('Especie:', record.mascotaTipo == 'perro' ? 'Perro 🐶' : 'Gato 🐱'),
                      _buildDetailRow('Sexo:', record.mascotaSexo),
                      _buildDetailRow('Edad:', '${record.mascotaEdad} años'),
                      if (record.observaciones.isNotEmpty)
                        _buildDetailRow('Observaciones:', record.observaciones, isItalic: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Sección: Datos del Propietario
                  _buildSectionCard(
                    title: 'Datos del Propietario',
                    icon: Icons.person_outline,
                    color: const Color(0xFF203A43),
                    children: [
                      _buildDetailRow('Dueño:', record.nombrePropietario, isBoldValue: true),
                      _buildDetailRow('Cédula (C.I.):', record.propietarioCedula),
                      _buildDetailRow('Teléfono:', record.propietarioTelefono),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Sección: Datos de la Vacunación y Ubicación
                  _buildSectionCard(
                    title: 'Registro de Vacunación',
                    icon: Icons.vaccines_outlined,
                    color: Colors.teal[600]!,
                    children: [
                      _buildDetailRow('Vacuna Aplicada:', record.vacunaAplicada, isBoldValue: true, valueColor: Colors.teal[800]),
                      _buildDetailRow('Fecha y Hora:', dateFormatted),
                      _buildDetailRow('Coordenadas GPS:', '📍 [${record.latitud.toStringAsFixed(6)}, ${record.longitud.toStringAsFixed(6)}]'),
                      _buildDetailRow('ID Vacunador:', record.vacunadorId, isCode: true),
                      _buildDetailRow('ID Sector:', record.sectorId, isCode: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoHeader(BuildContext context) {
    Widget imageWidget;

    if (record.fotoUrl.isEmpty) {
      imageWidget = Container(
        color: record.mascotaTipo == 'perro' ? Colors.brown[100] : Colors.orange[100],
        child: Icon(
          record.mascotaTipo == 'perro' ? Icons.pets : Icons.cruelty_free,
          color: record.mascotaTipo == 'perro' ? Colors.brown[700] : Colors.orange[700],
          size: 100,
        ),
      );
    } else if (record.fotoUrl.startsWith('http') || record.fotoUrl.startsWith('https')) {
      imageWidget = Image.network(
        record.fotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      );
    } else {
      imageWidget = Image.file(
        File(record.fotoUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: imageWidget,
    );
  }

  Widget _buildSyncStatusBadge(bool isOffline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isOffline ? Colors.orange[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOffline ? Colors.orange : Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.cloud_done,
            color: isOffline ? Colors.orange[800] : Colors.green[800],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isOffline ? 'Guardado Local (Pendiente Sincronizar)' : 'Sincronizado con la Nube',
            style: TextStyle(
              color: isOffline ? Colors.orange[900] : Colors.green[900],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBoldValue = false,
    bool isItalic = false,
    bool isCode = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                fontFamily: isCode ? 'Courier' : null,
                color: valueColor ?? Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
