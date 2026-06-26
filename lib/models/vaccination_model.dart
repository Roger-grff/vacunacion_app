import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationModel {
  final String id;
  final String propietarioNombre;
  final String propietarioCedula;
  final String propietarioTelefono;
  final String mascotaTipo; // 'perro' | 'gato'
  final String mascotaNombre;
  final int mascotaEdad;
  final String mascotaSexo;
  final String vacunaAplicada;
  final String observaciones;
  final String fotoUrl; // URL de Firebase Storage o ruta local de archivo si no está sincronizado
  final double latitud;
  final double longitud;
  final DateTime fechaHora;
  final String vacunadorId;
  final String sectorId;
  final int syncState; // 0 = pendiente de sincronizar, 1 = sincronizado

  VaccinationModel({
    required this.id,
    required this.propietarioNombre,
    required this.propietarioCedula,
    required this.propietarioTelefono,
    required this.mascotaTipo,
    required this.mascotaNombre,
    required this.mascotaEdad,
    required this.mascotaSexo,
    required this.vacunaAplicada,
    required this.observaciones,
    required this.fotoUrl,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
    required this.vacunadorId,
    required this.sectorId,
    this.syncState = 1,
  });

  factory VaccinationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return VaccinationModel(
      id: id,
      propietarioNombre: map['propietarioNombre'] ?? '',
      propietarioCedula: map['propietarioCedula'] ?? '',
      propietarioTelefono: map['propietarioTelefono'] ?? '',
      mascotaTipo: map['mascotaTipo'] ?? 'perro',
      mascotaNombre: map['mascotaNombre'] ?? '',
      mascotaEdad: map['mascotaEdad'] is int
          ? map['mascotaEdad']
          : int.tryParse(map['mascotaEdad']?.toString() ?? '0') ?? 0,
      mascotaSexo: map['mascotaSexo'] ?? '',
      vacunaAplicada: map['vacunaAplicada'] ?? '',
      observaciones: map['observaciones'] ?? '',
      fotoUrl: map['fotoUrl'] ?? '',
      latitud: (map['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (map['longitud'] as num?)?.toDouble() ?? 0.0,
      fechaHora: parseDateTime(map['fechaHora']),
      vacunadorId: map['vacunadorId'] ?? '',
      sectorId: map['sectorId'] ?? '',
      syncState: map['syncState'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propietarioNombre': propietarioNombre,
      'propietarioCedula': propietarioCedula,
      'propietarioTelefono': propietarioTelefono,
      'mascotaTipo': mascotaTipo,
      'mascotaNombre': mascotaNombre,
      'mascotaEdad': mascotaEdad,
      'mascotaSexo': mascotaSexo,
      'vacunaAplicada': vacunaAplicada,
      'observaciones': observaciones,
      'fotoUrl': fotoUrl,
      'latitud': latitud,
      'longitud': longitud,
      'fechaHora': fechaHora.toIso8601String(),
      'vacunadorId': vacunadorId,
      'sectorId': sectorId,
      'syncState': syncState,
    };
  }

  // Copia el modelo con un nuevo estado de sincronización y URL de foto
  VaccinationModel copyWith({
    String? fotoUrl,
    int? syncState,
  }) {
    return VaccinationModel(
      id: id,
      propietarioNombre: propietarioNombre,
      propietarioCedula: propietarioCedula,
      propietarioTelefono: propietarioTelefono,
      mascotaTipo: mascotaTipo,
      mascotaNombre: mascotaNombre,
      mascotaEdad: mascotaEdad,
      mascotaSexo: mascotaSexo,
      vacunaAplicada: vacunaAplicada,
      observaciones: observaciones,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      latitud: latitud,
      longitud: longitud,
      fechaHora: fechaHora,
      vacunadorId: vacunadorId,
      sectorId: sectorId,
      syncState: syncState ?? this.syncState,
    );
  }
}
