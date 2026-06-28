class SectorModel {
  final String id;
  final String nombre;
  final String parroquia;
  final String zona;
  final bool activo;

  SectorModel({
    required this.id,
    required this.nombre,
    required this.parroquia,
    required this.zona,
    required this.activo,
  });

  factory SectorModel.fromMap(Map<String, dynamic> map, String id) {
    return SectorModel(
      id: id,
      nombre: map['nombre'] ?? '',
      parroquia: map['parroquia'] ?? '',
      zona: map['zona'] ?? '',
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'parroquia': parroquia,
      'zona': zona,
      'activo': activo,
    };
  }
}