import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fieldai_offline.db');
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

  Future _createDB(Database db, int version) async {
    // 1. Observations table (Offline-first)
    await db.execute('''
      CREATE TABLE observations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL UNIQUE,
        crop TEXT NOT NULL,
        symptoms TEXT,
        weather_condition TEXT,
        notes TEXT,
        latitude REAL,
        longitude REAL,
        predicted_disease TEXT,
        confidence REAL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    // 2. Predictions cache table
    await db.execute('''
      CREATE TABLE predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prediction_id TEXT,
        crop TEXT NOT NULL,
        condition_class TEXT NOT NULL,
        condition_name TEXT NOT NULL,
        confidence REAL NOT NULL,
        severity TEXT,
        status TEXT,
        explanation TEXT,
        recommended_actions TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    // 3. Sync Queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL UNIQUE,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // --- Observation CRUD Operations ---

  Future<int> insertObservation(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('observations', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingObservations() async {
    final db = await instance.database;
    return await db.query(
      'observations',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<int> markObservationSynced(String clientId) async {
    final db = await instance.database;
    return await db.update(
      'observations',
      {'sync_status': 'synced'},
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllObservations() async {
    final db = await instance.database;
    return await db.query('observations', orderBy: 'created_at DESC');
  }

  Future<int> getPendingCount() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM observations WHERE sync_status = 'pending'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Prediction Cache Operations ---

  Future<int> insertPrediction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('predictions', row);
  }

  Future<List<Map<String, dynamic>>> getAllPredictions() async {
    final db = await instance.database;
    return await db.query('predictions', orderBy: 'created_at DESC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
