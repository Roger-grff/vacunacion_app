import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario_modelo.dart';

class DummyDataService {
  // Función para cargar datos de prueba completos en tu proyecto Firebase
  static Future<Map<String, String>> loadDummyData() async {
    final firestore = FirebaseFirestore.instance;
    final results = <String, String>{};

    try {
      print('Iniciando carga de datos iniciales...');

      // 1. Crear Sectores con IDs fijos
final sectores = [
  {
    'id': 'la_carolina',
    'nombre': 'La Carolina',
    'parroquia': 'Iñaquito',
    'zona': 'Norte',
    'activo': true,
  },
  {
    'id': 'la_mariscal',
    'nombre': 'La Mariscal',
    'parroquia': 'Mariscal Sucre',
    'zona': 'Centro',
    'activo': true,
  },
  {
    'id': 'quitumbe',
    'nombre': 'Quitumbe',
    'parroquia': 'Quitumbe',
    'zona': 'Sur',
    'activo': true,
  },
  {
    'id': 'calderon',
    'nombre': 'Calderón',
    'parroquia': 'Calderón',
    'zona': 'Norte',
    'activo': true,
  },
  {
    'id': 'carcelen',
    'nombre': 'Carcelén',
    'parroquia': 'Carcelén',
    'zona': 'Norte',
    'activo': true,
  },
  {
    'id': 'conocoto',
    'nombre': 'Conocoto',
    'parroquia': 'Conocoto',
    'zona': 'Valle',
    'activo': true,
  },
  {
    'id': 'cumbaya',
    'nombre': 'Cumbayá',
    'parroquia': 'Cumbayá',
    'zona': 'Valle',
    'activo': true,
  },
  {
    'id': 'tumbaco',
    'nombre': 'Tumbaco',
    'parroquia': 'Tumbaco',
    'zona': 'Valle',
    'activo': true,
  },
  {
    'id': 'chillogallo',
    'nombre': 'Chillogallo',
    'parroquia': 'Chillogallo',
    'zona': 'Sur',
    'activo': true,
  },
  {
    'id': 'guamani',
    'nombre': 'Guamaní',
    'parroquia': 'Guamaní',
    'zona': 'Sur',
    'activo': true,
  },
];

for (var sec in sectores) {
  await firestore.collection('sectores').doc(sec['id'] as String).set({
    'nombre': sec['nombre'],
    'parroquia': sec['parroquia'],
    'zona': sec['zona'],
    'activo': sec['activo'],
  });
}

results['Sectores'] = '${sectores.length} sectores creados correctamente';

      

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
          'sectorId': 'la_carolina',
        },
        {
          'email': 'coordinador.sur@test.com',
          'cedula': '1733445566',
          'nombres': 'Diego Fernando',
          'apellidos': 'Torres Ortiz',
          'telefono': '0996665555',
          'rol': 'coordinador_brigada',
          'sectorId': 'quitumbe',
        },
        {
          'email': 'vacunador.norte1@test.com',
          'cedula': '1744556677',
          'nombres': 'Esteban Jose',
          'apellidos': 'Pazmiño Mora',
          'telefono': '0995554444',
          'rol': 'vacunador',
          'sectorId': 'la_carolina',
        },
        {
          'email': 'vacunador.sur1@test.com',
          'cedula': '1755667788',
          'nombres': 'Fabiola Maria',
          'apellidos': 'Luna Vélez',
          'telefono': '0994443333',
          'rol': 'vacunador',
          'sectorId': 'quitumbe',
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
            password: 'Ecuador2026', // Contraseña genérica de prueba para todos
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
//users
        // Registrar en Firestore
        final userModel = UserModel(
          uid: uid,
          cedula: u['cedula'] as String,
          nombres: u['nombres'] as String,
          apellidos: u['apellidos'] as String,
          telefono: u['telefono'] as String,
          correo: u['email'] as String,
          rol: u['rol'] as String,
          sectorId: u['sectorId'],
          cambioPassword: true, // Listo para usar, sin obligar cambio para agilizar pruebas
        );

        await firestore.collection('usuarios').doc(uid).set(userModel.toMap());
      }
      results['Usuarios'] = 'Usuarios creados con contraseña genérica: "Ecuador2026"';

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
          'sectorId': 'la_carolina',
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
          'sectorId': 'quitumbe',
        }
      ];

      for (var v in vacunacionesSemilla) {
        await firestore.collection('vacunaciones').doc(v['id'] as String).set(v);
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

