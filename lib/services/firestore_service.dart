import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/sector_model.dart';
import '../models/vaccination_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generador de contraseña inicial aleatoria con prefijo "VTE"
  String generateTempPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final buffer = StringBuffer('VTE');
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  // Crear usuario (Coordinador o Vacunador) usando una app secundaria de Firebase para no desloguear al coordinador actual
  Future<String> createUser({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String correo,
    required String rol,
    String? sectorId,
    required String tempPassword,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Crear una instancia de app secundaria para Firebase Auth
      final appName = 'TempUserCreator_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 2. Registrar el usuario en Firebase Auth
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: correo,
        password: tempPassword,
      );

      final uid = userCredential.user!.uid;

      // 3. Crear el documento del usuario en Cloud Firestore
      final userModel = UserModel(
        uid: uid,
        cedula: cedula,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        correo: correo,
        rol: rol,
        sectorId: sectorId,
        cambioPasswordObligatorio: true, // Forzar cambio en primer inicio
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      return uid;
    } catch (e) {
      print('Error al crear usuario en Firebase: $e');
      rethrow;
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  // Obtener usuarios por rol (o todos si se omiten parámetros)
  Stream<List<UserModel>> getUsers({String? sectorId, String? rol}) {
    Query query = _firestore.collection('users');
    if (sectorId != null) {
      query = query.where('sectorId', isEqualTo: sectorId);
    }
    if (rol != null) {
      query = query.where('rol', isEqualTo: rol);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Actualizar sector de un usuario (para reasignación de vacunadores)
  Future<void> updateUserSector(String uid, String? sectorId) async {
    await _firestore.collection('users').doc(uid).update({
      'sectorId': sectorId,
    });
  }

  // --- SECTORES ---

  // Crear Sector
  Future<void> createSector(String nombre) async {
    final docRef = _firestore.collection('sectors').doc();
    final sector = SectorModel(
      id: docRef.id,
      nombre: nombre,
      creadoEn: DateTime.now(),
    );
    await docRef.set(sector.toMap());
  }

  // Asignar Coordinador de Brigada a un sector
  Future<void> assignCoordinatorToSector(String sectorId, String coordinatorId) async {
    // 1. Asignar el coordinador en el sector
    await _firestore.collection('sectors').doc(sectorId).update({
      'coordinadorBrigadaId': coordinatorId,
    });

    // 2. Actualizar el sectorId en el usuario coordinador
    await _firestore.collection('users').doc(coordinatorId).update({
      'sectorId': sectorId,
    });
  }

  // Stream de Sectores
  Stream<List<SectorModel>> getSectors() {
    return _firestore.collection('sectors').orderBy('creadoEn', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SectorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // --- VACUNACIONES ---

  // Guardar registro de vacunación en Firestore
  Future<void> uploadVaccinationRecord(VaccinationModel vaccination) async {
    await _firestore.collection('vaccinations').doc(vaccination.id).set(vaccination.toMap());
  }

  // Editar / Corregir registro de vacunación
  Future<void> updateVaccinationRecord(VaccinationModel vaccination) async {
    await _firestore.collection('vaccinations').doc(vaccination.id).update(vaccination.toMap());
  }

  // Obtener vacunaciones en base al rol y permisos
  Stream<List<VaccinationModel>> getVaccinations({String? sectorId, String? vacunadorId}) {
    Query query = _firestore.collection('vaccinations');

    if (sectorId != null) {
      query = query.where('sectorId', isEqualTo: sectorId);
    }
    if (vacunadorId != null) {
      query = query.where('vacunadorId', isEqualTo: vacunadorId);
    }

    return query.orderBy('fechaHora', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
