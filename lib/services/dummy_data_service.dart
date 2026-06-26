import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/sector_model.dart';
import '../models/vaccination_model.dart';

class DummyDataService {
  // Función para cargar datos de prueba completos en tu proyecto Firebase
  static Future<Map<String, String>> loadDummyData() async {
    final firestore = FirebaseFirestore.instance;
    final results = <String, String>{};

    try {
      print('Iniciando carga de datos iniciales...');

      // 1. Crear Sectores con IDs fijos para relacionar
      final sectores = [
        {'id': 'sec_norte', 'nombre': 'Sector Norte'},
        {'id': 'sec_sur', 'nombre': 'Sector Sur'},
        {'id': 'sec_centro', 'nombre': 'Sector Centro'},
      ];

      for (var sec in sectores) {
        await firestore.collection('sectors').doc(sec['id']).set({
          'nombre': sec['nombre'],
          'coordinadorBrigadaId': sec['id'] == 'sec_norte' 
              ? 'uid_coord_norte' 
              : (sec['id'] == 'sec_sur' ? 'uid_coord_sur' : null),
          'creadoEn': DateTime.now().toIso8601String(),
        });
      }
      results['Sectores'] = '3 sectores creados (Norte, Sur, Centro)';

      // 2. Crear Usuarios en Firebase Auth y Firestore
      // Lista de usuarios semilla
      final usuariosSemilla = [
        {
          'email': 'admi@admi.com',
          'cedula': '000000000',
          'nombres': 'Administrador',
          'apellidos': 'admi',
          'telefono': '0999999999',
          'rol': 'coordinador_campana',
          'sectorId': null,
        },
        {
          'email': 'coordinador.campana@test.com',
          'cedula': '1711223344',
          'nombres': 'Carlos Ariel',
          'apellidos': 'Mendoza Ruiz',
          'telefono': '0998887777',
          'rol': 'coordinador_campana',
          'sectorId': null,
        },
        {
          'email': 'coordinador.norte@test.com',
          'cedula': '1722334455',
          'nombres': 'Beatriz Elena',
          'apellidos': 'Gómez Castro',
          'telefono': '0997776666',
          'rol': 'coordinador_brigada',
          'sectorId': 'sec_norte',
        },
        {
          'email': 'coordinador.sur@test.com',
          'cedula': '1733445566',
          'nombres': 'Diego Fernando',
          'apellidos': 'Torres Ortiz',
          'telefono': '0996665555',
          'rol': 'coordinador_brigada',
          'sectorId': 'sec_sur',
        },
        {
          'email': 'vacunador.norte1@test.com',
          'cedula': '1744556677',
          'nombres': 'Esteban Jose',
          'apellidos': 'Pazmiño Mora',
          'telefono': '0995554444',
          'rol': 'vacunador',
          'sectorId': 'sec_norte',
        },
        {
          'email': 'vacunador.sur1@test.com',
          'cedula': '1755667788',
          'nombres': 'Fabiola Maria',
          'apellidos': 'Luna Vélez',
          'telefono': '0994443333',
          'rol': 'vacunador',
          'sectorId': 'sec_sur',
        }
      ];

      // Inicializar una app secundaria para registrar los usuarios en Auth sin cerrar la sesión actual
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = await Firebase.initializeApp(
          name: 'DummyUserCreator',
          options: Firebase.app().options,
        );
      } catch (_) {
        secondaryApp = Firebase.app('DummyUserCreator');
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      for (var u in usuariosSemilla) {
        String uid;
        try {
          // Registrar en Auth
          final cred = await secondaryAuth.createUserWithEmailAndPassword(
            email: u['email'] as String,
            password: 'password123', // Contraseña genérica de prueba para todos
          );
          uid = cred.user!.uid;
        } on FirebaseAuthException catch (authErr) {
          // Si el usuario ya existe en Auth, intentamos buscar su UID o usamos uno aproximado
          if (authErr.code == 'email-already-in-use') {
            print('El correo ${u['email']} ya está registrado en Firebase Auth.');
            // Actualizamos en Firestore usando el UID del usuario registrado si es posible,
            // de lo contrario usamos un ID estático o saltamos.
            continue;
          } else {
            rethrow;
          }
        }

        // Registrar en Firestore
        final userModel = UserModel(
          uid: uid,
          cedula: u['cedula'] as String,
          nombres: u['nombres'] as String,
          apellidos: u['apellidos'] as String,
          telefono: u['telefono'] as String,
          correo: u['email'] as String,
          rol: u['rol'] as String,
          sectorId: u['sectorId'] as String?,
          cambioPasswordObligatorio: false, // Listo para usar, sin obligar cambio para agilizar pruebas
        );

        await firestore.collection('users').doc(uid).set(userModel.toMap());
      }
      results['Usuarios'] = 'Usuarios creados con contraseña genérica: "password123"';

      // 3. Crear algunos registros históricos de vacunación de ejemplo
      final vacunacionesSemilla = [
        {
          'id': 'vac_demo_1',
          'propietarioNombre': 'Mariana de Jesús',
          'propietarioCedula': '1709876543',
          'propietarioTelefono': '0984321098',
          'mascotaTipo': 'perro',
          'mascotaNombre': 'Toby',
          'mascotaEdad': 3,
          'mascotaSexo': 'Macho',
          'vacunaAplicada': 'Antirrábica Anual',
          'observaciones': 'Mascota sana, dócil durante la aplicación.',
          'fotoUrl': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&q=80&w=400',
          'latitud': -0.180653,
          'longitud': -78.467832,
          'fechaHora': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'vacunadorId': 'vacunador_norte_demo',
          'sectorId': 'sec_norte',
        },
        {
          'id': 'vac_demo_2',
          'propietarioNombre': 'Andrés Felipe',
          'propietarioCedula': '1701234567',
          'propietarioTelefono': '0976543210',
          'mascotaTipo': 'gato',
          'mascotaNombre': 'Mimi',
          'mascotaEdad': 2,
          'mascotaSexo': 'Hembra',
          'vacunaAplicada': 'Triple Felina',
          'observaciones': 'Requiere refuerzo en 21 días.',
          'fotoUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=400',
          'latitud': -0.198254,
          'longitud': -78.489124,
          'fechaHora': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'vacunadorId': 'vacunador_sur_demo',
          'sectorId': 'sec_sur',
        }
      ];

      for (var v in vacunacionesSemilla) {
        await firestore.collection('vaccinations').doc(v['id'] as String).set(v);
      }
      results['Vacunaciones'] = '2 vacunaciones de prueba cargadas con coordenadas en mapa';

      print('Carga de datos completada con éxito.');
    } catch (e) {
      print('Error al cargar datos dummy: $e');
      results['Error'] = e.toString();
    }

    return results;
  }
}
