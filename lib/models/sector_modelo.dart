import 'package:cloud_firestore/cloud_firestore.dart';

class SectorModel {
  final String id;
  final String nombre;
  final String? coordinadorBrigadaId;
  final DateTime creadoEn;

  SectorModel({
    required this.id,
    required this.nombre,
    this.coordinadorBrigadaId,
    required this.creadoEn,
  });

  factory SectorModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return SectorModel(
      id: id,
      nombre: map['nombre'] ?? '',
      coordinadorBrigadaId: map['coordinadorBrigadaId'],
      creadoEn: parseDateTime(map['creadoEn']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'coordinadorBrigadaId': coordinadorBrigadaId,
      'creadoEn': creadoEn.toIso8601String(), // Se puede guardar como String o Timestamp en Firestore
    };
  }
}
