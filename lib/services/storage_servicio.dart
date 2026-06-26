import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sube una imagen local a Firebase Storage y retorna su URL de descarga pública
  Future<String> uploadVaccinationPhoto(String localImagePath, String vaccinationId) async {
    final file = File(localImagePath);
    if (!await file.exists()) {
      throw Exception('El archivo de foto local no existe: $localImagePath');
    }

    final ref = _storage.ref().child('vaccinations').child('$vaccinationId.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
