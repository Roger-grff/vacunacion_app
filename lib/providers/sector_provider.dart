import 'package:flutter/material.dart';
import '../models/sector_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class SectorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<SectorModel> _sectors = [];
  List<UserModel> _coordinadoresDisponibles = [];
  bool _isLoading = false;

  List<SectorModel> get sectors => _sectors;
  List<UserModel> get coordinadoresDisponibles => _coordinadoresDisponibles;
  bool get isLoading => _isLoading;

  SectorProvider() {
    _listenToSectors();
    _listenToCoordinators();
  }

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
      // Filtrar aquellos que no tengan un sector asignado aún, o listarlos todos
      _coordinadoresDisponibles = usersList;
      notifyListeners();
    });
  }

  // Crear un nuevo sector
  Future<bool> createSector(String nombre) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.createSector(nombre);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Asignar Coordinador a un Sector
  Future<bool> assignCoordinator(String sectorId, String coordinatorId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.assignCoordinatorToSector(sectorId, coordinatorId);
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
      final tempPassword = _firestoreService.generateTempPassword();
      await _firestoreService.createUser(
        cedula: cedula,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        correo: correo,
        rol: rol,
        sectorId: sectorId,
        tempPassword: tempPassword,
      );
      _isLoading = false;
      notifyListeners();
      // Retornar la clave temporal para que se le muestre en pantalla al administrador
      return tempPassword;
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
}
