import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario_modelo.dart';
import '../models/sector_modelo.dart';
import '../models/vacunacion_modelo.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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
        cambioPassword: true, // Forzar cambio en primer inicio
      );

      await _firestore.collection('usuarios').doc(uid).set(userModel.toMap());

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
    Query query = _firestore.collection('usuarios');
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
    await _firestore.collection('usuarios').doc(uid).update({
      'sectorId': sectorId,
    });
  }

  // Actualizar datos completos de un usuario en Firestore
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('usuarios').doc(user.uid).update(user.toMap());
  }

  // Eliminar el documento de usuario en Firestore (revoca su acceso)
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('usuarios').doc(uid).delete();
  }

  // --- SECTORES ---

  // Crear Sector
  Future<void> createSector({
  required String nombre,
  required String parroquia,
  required String zona,
}) async {

  final docRef =
      _firestore.collection('sectores').doc();

  final sector = SectorModel(
    id: docRef.id,
    nombre: nombre,
    parroquia: parroquia,
    zona: zona,
    activo: true,
  );

  await docRef.set(sector.toMap());
}

 

  // Stream de Sectores
  Stream<List<SectorModel>> getSectors() {
    return _firestore.collection('sectores').orderBy('nombre', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SectorModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- VACUNACIONES ---

  // Guardar registro de vacunación en Firestore
  Future<void> uploadVaccinationRecord(VaccinationModel vaccination) async {
    await _firestore.collection('vacunaciones').doc(vaccination.id).set(vaccination.toMap());
  }

  // Editar / Corregir registro de vacunación
  Future<void> updateVaccinationRecord(VaccinationModel vaccination) async {
    await _firestore.collection('vacunaciones').doc(vaccination.id).update(vaccination.toMap());
  }

  Future<UserModel?> getUser(String uid) async {

  final doc =
      await _firestore
          .collection('usuarios')
          .doc(uid)
          .get();

  if (!doc.exists) return null;

  return UserModel.fromMap(
      doc.data()!,
      doc.id);
}

Future<SectorModel?> getSector(String id) async {
  final doc = await _firestore.collection('sectores').doc(id).get();
  if (!doc.exists) return null;

  return SectorModel.fromMap(doc.data()!, doc.id);
}

// Obtener vacunaciones en base al rol y permisos
  Stream<List<VaccinationModel>> getVaccinations({String? sectorId, String? vacunadorId}) {
    Query query = _firestore.collection('vacunaciones');

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

