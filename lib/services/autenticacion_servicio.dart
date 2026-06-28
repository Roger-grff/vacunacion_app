import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_modelo.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual autenticado
  User? get currentUser => _auth.currentUser;

  // Iniciar sesión
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Obtener información adicional del usuario desde Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      print('Error al obtener datos de usuario: $e');
    }
    return null;
  }

  // Cambiar contraseña obligatoria (primer inicio de sesión)
  Future<void> changePasswordAndCompleteOnboarding(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      // 1. Actualizar contraseña en Firebase Auth
      await user.updatePassword(newPassword);
      
      // 2. Actualizar flag en Firestore
      await _firestore.collection('usuarios').doc(user.uid).update({
        'cambioPassword': false,
      });
    } else {
      throw Exception('No hay un usuario autenticado para cambiar la contraseña.');
    }
  }

  // Restablecer contraseña por correo electrónico
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

