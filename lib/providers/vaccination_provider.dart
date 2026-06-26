import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/vaccination_model.dart';
import '../services/local_db_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class VaccinationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final LocalDbService _localDbService = LocalDbService.instance;
  final Connectivity _connectivity = Connectivity();

  List<VaccinationModel> _onlineVaccinations = [];
  List<VaccinationModel> _offlineVaccinations = [];
  int _pendingSyncCount = 0;
  bool _isLoading = false;
  bool _isSyncing = false;

  List<VaccinationModel> get onlineVaccinations => _onlineVaccinations;
  List<VaccinationModel> get offlineVaccinations => _offlineVaccinations;
  int get pendingSyncCount => _pendingSyncCount;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  VaccinationProvider() {
    _initConnectivityListener();
    _loadPendingCount();
  }

  // Carga inicial del contador de pendientes
  Future<void> _loadPendingCount() async {
    _pendingSyncCount = await _localDbService.getPendingCount();
    _offlineVaccinations = await _localDbService.getPendingVaccinations();
    notifyListeners();
  }

  // Listener para conectividad: sincroniza automáticamente al recuperar conexión
  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
      if (isOnline) {
        print('Conexión de red detectada. Iniciando sincronización automática...');
        syncPendingVaccinations();
      }
    });
  }

  // Escuchar stream de vacunaciones según rol y sector
  void listenToVaccinations({String? sectorId, String? vacunadorId}) {
    _firestoreService.getVaccinations(sectorId: sectorId, vacunadorId: vacunadorId).listen((list) {
      _onlineVaccinations = list;
      notifyListeners();
    });
  }

  // Registrar Vacunación (Maneja Online y Offline)
  Future<bool> registerVaccination({
    required String propietarioNombre,
    required String propietarioCedula,
    required String propietarioTelefono,
    required String mascotaTipo,
    required String mascotaNombre,
    required int mascotaEdad,
    required String mascotaSexo,
    required String vacunaAplicada,
    required String observaciones,
    required String localPhotoPath,
    required double latitud,
    required double longitud,
    required String vacunadorId,
    required String sectorId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final vaccinationId = const Uuid().v4();
    final fechaHora = DateTime.now();

    // 1. Verificar conectividad
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.isNotEmpty &&
        connectivityResult.any((result) => result != ConnectivityResult.none);

    if (isOnline) {
      try {
        // --- FLUJO ONLINE ---
        // A. Subir foto a Firebase Storage
        final fotoUrl = await _storageService.uploadVaccinationPhoto(localPhotoPath, vaccinationId);

        // B. Crear modelo con URL online
        final vaccination = VaccinationModel(
          id: vaccinationId,
          propietarioNombre: propietarioNombre,
          propietarioCedula: propietarioCedula,
          propietarioTelefono: propietarioTelefono,
          mascotaTipo: mascotaTipo,
          mascotaNombre: mascotaNombre,
          mascotaEdad: mascotaEdad,
          mascotaSexo: mascotaSexo,
          vacunaAplicada: vacunaAplicada,
          observaciones: observaciones,
          fotoUrl: fotoUrl,
          latitud: latitud,
          longitud: longitud,
          fechaHora: fechaHora,
          vacunadorId: vacunadorId,
          sectorId: sectorId,
          syncState: 1, // Sincronizado
        );

        // C. Guardar en Firestore
        await _firestoreService.uploadVaccinationRecord(vaccination);

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        print('Error en registro online: $e. Reintentando guardar localmente...');
        // Si falla por algún problema técnico, caemos en flujo offline para no perder el registro
      }
    }

    // --- FLUJO OFFLINE (Si está desconectado o falló la subida) ---
    try {
      // A. Copiar foto a almacenamiento de la aplicación para persistencia local a largo plazo
      final appDocDir = await getApplicationDocumentsDirectory();
      final offlinePhotosDir = Directory(path.join(appDocDir.path, 'offline_photos'));
      if (!await offlinePhotosDir.exists()) {
        await offlinePhotosDir.create(recursive: true);
      }

      final fileName = '$vaccinationId.jpg';
      final newLocalPath = path.join(offlinePhotosDir.path, fileName);
      await File(localPhotoPath).copy(newLocalPath);

      // B. Crear modelo con la ruta local persistida
      final vaccinationOffline = VaccinationModel(
        id: vaccinationId,
        propietarioNombre: propietarioNombre,
        propietarioCedula: propietarioCedula,
        propietarioTelefono: propietarioTelefono,
        mascotaTipo: mascotaTipo,
        mascotaNombre: mascotaNombre,
        mascotaEdad: mascotaEdad,
        mascotaSexo: mascotaSexo,
        vacunaAplicada: vacunaAplicada,
        observaciones: observaciones,
        fotoUrl: newLocalPath, // Ruta de archivo local
        latitud: latitud,
        longitud: longitud,
        fechaHora: fechaHora,
        vacunadorId: vacunadorId,
        sectorId: sectorId,
        syncState: 0, // Pendiente de sincronizar
      );

      // C. Guardar en SQLite
      await _localDbService.insertVaccination(vaccinationOffline);

      // D. Actualizar contadores locales
      await _loadPendingCount();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error fatal en registro local offline: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sincronizar registros pendientes de forma secuencial
  Future<void> syncPendingVaccinations() async {
    if (_isSyncing) return;

    // Verificar si hay elementos antes de iniciar la sincronización
    final count = await _localDbService.getPendingCount();
    if (count == 0) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final pendingList = await _localDbService.getPendingVaccinations();
      print('Sincronizando ${pendingList.length} registros pendientes...');

      for (var vaccination in pendingList) {
        // Verificar que siga habiendo conexión en cada iteración
        final connectivityResult = await _connectivity.checkConnectivity();
        final isOnline = connectivityResult.isNotEmpty &&
            connectivityResult.any((result) => result != ConnectivityResult.none);
        
        if (!isOnline) {
          print('Conexión perdida durante la sincronización.');
          break;
        }

        try {
          // 1. Subir la imagen de la mascota
          final fotoUrl = await _storageService.uploadVaccinationPhoto(vaccination.fotoUrl, vaccination.id);

          // 2. Crear modelo sincronizado
          final syncedVaccination = vaccination.copyWith(
            fotoUrl: fotoUrl,
            syncState: 1,
          );

          // 3. Subir registro a Firestore
          await _firestoreService.uploadVaccinationRecord(syncedVaccination);

          // 4. Eliminar de SQLite
          await _localDbService.deleteVaccination(vaccination.id);

          // 5. Eliminar archivo local de imagen para liberar almacenamiento del dispositivo
          final localFile = File(vaccination.fotoUrl);
          if (await localFile.exists()) {
            await localFile.delete();
          }
        } catch (itemError) {
          print('Error al sincronizar registro individual (ID: ${vaccination.id}): $itemError');
          // Continuamos con el siguiente registro si uno en particular falla
        }
      }
    } catch (e) {
      print('Error durante proceso general de sincronización: $e');
    } finally {
      await _loadPendingCount();
      _isSyncing = false;
      notifyListeners();
    }
  }
}
