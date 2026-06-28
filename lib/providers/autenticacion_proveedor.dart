import 'package:flutter/material.dart';
import '../models/usuario_modelo.dart';
import '../services/autenticacion_servicio.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isInitialLoading = true;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get userModel => _userModel;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.currentUser != null && _userModel != null;
  bool get forcePasswordChange => _userModel?.cambioPassword ?? false;

  AuthProvider() {
    _initUser();
  }

  // Inicializa el estado del usuario al abrir la app si ya tiene sesión
  Future<void> _initUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      _isInitialLoading = true;
      notifyListeners();
      _userModel = await _authService.getUserData(user.uid);
    }
    _isInitialLoading = false;
    notifyListeners();
  }

  // Iniciar Sesión
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(email, password);
      _userModel = await _authService.getUserData(credential.user!.uid);
      
      if (_userModel == null) {
        throw Exception('El usuario no existe en la base de datos de vacunación.');
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  // Cambiar Contraseña Obligatoria
  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePasswordAndCompleteOnboarding(newPassword);
      // Recargar datos locales
      if (_userModel != null) {
        _userModel = UserModel(
          uid: _userModel!.uid,
          cedula: _userModel!.cedula,
          nombres: _userModel!.nombres,
          apellidos: _userModel!.apellidos,
          telefono: _userModel!.telefono,
          correo: _userModel!.correo,
          rol: _userModel!.rol,
          sectorId: _userModel!.sectorId,
          cambioPassword: false,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Recuperar Contraseña por Correo
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cerrar Sesión
  Future<void> logout() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }
}

