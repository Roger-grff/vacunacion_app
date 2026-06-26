import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/vaccination_model.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vaccinations_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vaccinations_offline (
        id TEXT PRIMARY KEY,
        propietarioNombre TEXT NOT NULL,
        propietarioCedula TEXT NOT NULL,
        propietarioTelefono TEXT NOT NULL,
        mascotaTipo TEXT NOT NULL,
        mascotaNombre TEXT NOT NULL,
        mascotaEdad INTEGER NOT NULL,
        mascotaSexo TEXT NOT NULL,
        vacunaAplicada TEXT NOT NULL,
        observaciones TEXT NOT NULL,
        fotoUrl TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        fechaHora TEXT NOT NULL,
        vacunadorId TEXT NOT NULL,
        sectorId TEXT NOT NULL,
        syncState INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertVaccination(VaccinationModel vaccination) async {
    final db = await instance.database;
    final map = vaccination.toMap();
    map['syncState'] = 0; // Aseguramos que se guarde como pendiente
    return await db.insert(
      'vaccinations_offline',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VaccinationModel>> getPendingVaccinations() async {
    final db = await instance.database;
    final result = await db.query(
      'vaccinations_offline',
      where: 'syncState = ?',
      whereArgs: [0],
    );

    return result.map((json) => VaccinationModel.fromMap(json, json['id'] as String)).toList();
  }

  Future<int> getPendingCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM vaccinations_offline WHERE syncState = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteVaccination(String id) async {
    final db = await instance.database;
    return await db.delete(
      'vaccinations_offline',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
