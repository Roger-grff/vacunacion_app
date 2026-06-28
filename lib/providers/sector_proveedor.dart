import 'package:flutter/material.dart';
import '../models/sector_modelo.dart';
import '../models/usuario_modelo.dart';
import '../services/firestore_servicio.dart';

class SectorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<SectorModel> _sectors = [];
  List<UserModel> _coordinadoresDisponibles = [];
  List<UserModel> _vaccinators = [];
  bool _isLoading = false;

  List<SectorModel> get sectors => _sectors;
  List<UserModel> get coordinadoresDisponibles => _coordinadoresDisponibles;
  List<UserModel> get vaccinators => _vaccinators;
  bool get isLoading => _isLoading;

  SectorProvider() {
  _listenToSectors();
  _listenToCoordinators();
  _listenToVaccinators();
}
  //Filtra 
  // Escuchar cambios en los sectores
  void _listenToSectors() {
    _firestoreService.getSectors().listen((sectorsList) {
      _sectors = sectorsList;
      notifyListeners();
    });
  }

  // Escuchar coordinadores de brigada disponibles (para asignarlos a sectores)
  void _listenToCoordinators() {
    _firestoreService.getUsers(rol: 'coordinador_brigada').listen((usersList) {
      // Obtener todos los coordinadores de brigada
      _coordinadoresDisponibles = usersList;
      notifyListeners();
    });
  }

  void _listenToVaccinators() {
  _firestoreService
      .getUsers(rol: 'vacunador')
      .listen((usersList) {
    _vaccinators = usersList;
    notifyListeners();
  });
}

  // Crear un nuevo sector
Future<bool> createSector({
  required String nombre,
  required String parroquia,
  required String zona,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
    await _firestoreService.createSector(
      nombre: nombre,
      parroquia: parroquia,
      zona: zona,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  

  // Crear un nuevo usuario en la app (Coordinador o Vacunador)
  Future<String?> createUser({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String correo,
    required String rol,
    String? sectorId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      
      await _firestoreService.createUser(
        cedula: cedula,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        correo: correo,
        rol: rol,
        sectorId: sectorId,
        tempPassword: "Ecuador2026",
      );
      _isLoading = false;
      notifyListeners();
      // Retornar la clave temporal para que se le muestre en pantalla al administrador
      return "Ecuador2026";
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Reasignar un vacunador a otro sector
  Future<bool> reassignVaccinator(String uid, String? sectorId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateUserSector(uid, sectorId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Editar datos de un usuario existente
  Future<bool> editUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar un usuario (revocar acceso)
  Future<bool> deleteUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.deleteUser(uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  SectorModel? getSectorById(String id) {
  try {
    return _sectors.firstWhere((sector) => sector.id == id);
  } catch (_) {
    return null;
  }
}
}

