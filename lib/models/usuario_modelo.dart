class UserModel {
  final String uid;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String correo;
  final String rol; // 'coordinador_campana', 'coordinador_brigada', 'vacunador'
  final String? sectorId;
  final bool cambioPassword;

  UserModel({
    required this.uid,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.correo,
    required this.rol,
    this.sectorId,
    required this.cambioPassword,
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      cedula: map['cedula'] ?? '',
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      rol: map['rol'] ?? 'vacunador',
      sectorId: map['sectorId'],
      cambioPassword: map['cambioPassword'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'correo': correo,
      'rol': rol,
      'sectorId': sectorId,
      'cambioPassword': cambioPassword,
    };
  }
}
