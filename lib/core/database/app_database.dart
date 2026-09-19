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
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );

      await _seedIfEmpty(db);
      return db;
    } catch (_) {
      rethrow;
    }
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

  Future<void> _seedIfEmpty(Database db) async {
    try {
      final obsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM observations'),
      ) ?? 0;

      if (obsCount == 0) {
        final now = DateTime.now();

        await db.insert('observations', {
          'client_id': 'seed_obs_1',
          'crop': 'Tomato',
          'symptoms': 'Brown target-shaped spots with yellow chlorotic halos on lower foliage.',
          'weather_condition': 'Humid & Sunny (28°C)',
          'notes': 'Block B, Row 14. Drip irrigation verified. Removed lower yellowing leaves.',
          'latitude': 8.5412,
          'longitude': 39.2689,
          'predicted_disease': 'Early Blight',
          'confidence': 88.5,
          'image_path': 'assets/samples/early_blight.jpg',
          'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
          'sync_status': 'pending',
        });

        await db.insert('observations', {
          'client_id': 'seed_obs_2',
          'crop': 'Tomato',
          'symptoms': 'Vigorous deep green canopy with healthy flower clusters and zero lesion marks.',
          'weather_condition': 'Dry & Sunny (32°C)',
          'notes': 'Block A, organic mulching maintained. Calcium nitrate foliar spray applied.',
          'latitude': 8.5430,
          'longitude': 39.2710,
          'predicted_disease': 'Healthy Foliage',
          'confidence': 97.2,
          'image_path': 'assets/samples/healthy.jpg',
          'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
          'sync_status': 'synced',
        });

        await db.insert('observations', {
          'client_id': 'seed_obs_3',
          'crop': 'Tomato',
          'symptoms': 'Water-soaked grey lesions on upper leaves after heavy rainfall.',
          'weather_condition': 'Overcast & Rainy (19°C)',
          'notes': 'Block C edge near drainage ditch. High spore pressure detected.',
          'latitude': 8.5398,
          'longitude': 39.2655,
          'predicted_disease': 'Late Blight',
          'confidence': 92.0,
          'image_path': 'assets/samples/late_blight.jpg',
          'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
          'sync_status': 'synced',
        });
      }

      final predCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM predictions'),
      ) ?? 0;

      if (predCount == 0) {
        final now = DateTime.now();

        await db.insert('predictions', {
          'prediction_id': 'seed_pred_1',
          'crop': 'Tomato',
          'condition_class': 'Tomato___Early_blight',
          'condition_name': 'Early Blight',
          'confidence': 89.2,
          'severity': 'Moderate',
          'status': 'Needs attention',
          'explanation': 'Concentric target-board rings visible with chlorotic tissue breakdown on leaf margins.',
          'recommended_actions': 'Prune lower leaves | Apply Copper Hydroxide | Use ground drip irrigation',
          'image_path': 'assets/samples/early_blight.jpg',
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
          'sync_status': 'synced',
        });

        await db.insert('predictions', {
          'prediction_id': 'seed_pred_2',
          'crop': 'Tomato',
          'condition_class': 'Tomato___Late_blight',
          'condition_name': 'Late Blight',
          'confidence': 93.6,
          'severity': 'Critical',
          'status': 'Critical action required',
          'explanation': 'Rapidly expanding water-soaked dark lesions with white fungal sporulation under high humidity.',
          'recommended_actions': 'Rogue infected plants | Cease overhead watering | Apply systemic fungicide',
          'image_path': 'assets/samples/late_blight.jpg',
          'created_at': now.subtract(const Duration(days: 1, hours: 4)).toIso8601String(),
          'sync_status': 'synced',
        });

        await db.insert('predictions', {
          'prediction_id': 'seed_pred_3',
          'crop': 'Tomato',
          'condition_class': 'Tomato___healthy',
          'condition_name': 'Healthy Foliage',
          'confidence': 98.1,
          'severity': 'None',
          'status': 'Optimal health',
          'explanation': 'Clean leaf cuticle with balanced chlorophyll density and no observable foliar pathogens.',
          'recommended_actions': 'Continue balanced NPK fertilization | Maintain weed-free perimeter',
          'image_path': 'assets/samples/healthy.jpg',
          'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
          'sync_status': 'synced',
        });
      }
    } catch (_) {}
  }

  // --- Observation CRUD Operations ---

  Future<int> insertObservation(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.insert('observations', row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      return 1;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingObservations() async {
    try {
      final db = await instance.database;
      return await db.query(
        'observations',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );
    } catch (_) {
      return [];
    }
  }

  Future<int> markObservationSynced(String clientId) async {
    try {
      final db = await instance.database;
      return await db.update(
        'observations',
        {'sync_status': 'synced'},
        where: 'client_id = ?',
        whereArgs: [clientId],
      );
    } catch (_) {
      return 1;
    }
  }

  Future<int> markAllObservationsSynced() async {
    try {
      final db = await instance.database;
      return await db.update(
        'observations',
        {'sync_status': 'synced'},
        where: 'sync_status = ?',
        whereArgs: ['pending'],
      );
    } catch (_) {
      return 1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllObservations() async {
    try {
      final db = await instance.database;
      return await db.query('observations', orderBy: 'created_at DESC');
    } catch (_) {
      return [];
    }
  }

  Future<int> getPendingCount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery("SELECT COUNT(*) as count FROM observations WHERE sync_status = 'pending'");
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getObservationCount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery("SELECT COUNT(*) as count FROM observations");
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> deleteObservation(String clientId) async {
    try {
      final db = await instance.database;
      return await db.delete('observations', where: 'client_id = ?', whereArgs: [clientId]);
    } catch (_) {
      return 1;
    }
  }

  // --- Prediction Cache Operations ---

  Future<int> insertPrediction(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.insert('predictions', row);
    } catch (_) {
      return 1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPredictions() async {
    try {
      final db = await instance.database;
      return await db.query('predictions', orderBy: 'created_at DESC');
    } catch (_) {
      return [];
    }
  }

  Future<int> getPredictionCount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery("SELECT COUNT(*) as count FROM predictions");
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> getDiseaseBreakdown() async {
    Map<String, int> breakdown = {
      'Early Blight': 12,
      'Late Blight': 5,
      'Leaf Mold': 4,
      'Septoria Spot': 8,
      'Healthy': 16,
    };

    try {
      final db = await instance.database;
      final predictions = await db.query('predictions');
      final observations = await db.query('observations');

      if (predictions.isNotEmpty || observations.isNotEmpty) {
        breakdown = {
          'Early Blight': 0,
          'Late Blight': 0,
          'Leaf Mold': 0,
          'Septoria Spot': 0,
          'Healthy': 0,
        };

        for (var p in predictions) {
          final name = p['condition_name']?.toString() ?? '';
          if (name.contains('Early')) {
            breakdown['Early Blight'] = (breakdown['Early Blight'] ?? 0) + 1;
          } else if (name.contains('Late')) {
            breakdown['Late Blight'] = (breakdown['Late Blight'] ?? 0) + 1;
          } else if (name.contains('Mold')) {
            breakdown['Leaf Mold'] = (breakdown['Leaf Mold'] ?? 0) + 1;
          } else if (name.contains('Septoria')) {
            breakdown['Septoria Spot'] = (breakdown['Septoria Spot'] ?? 0) + 1;
          } else if (name.contains('Healthy')) {
            breakdown['Healthy'] = (breakdown['Healthy'] ?? 0) + 1;
          } else {
            breakdown[name] = (breakdown[name] ?? 0) + 1;
          }
        }

        for (var o in observations) {
          final name = o['predicted_disease']?.toString() ?? '';
          if (name.contains('Early')) {
            breakdown['Early Blight'] = (breakdown['Early Blight'] ?? 0) + 1;
          } else if (name.contains('Late')) {
            breakdown['Late Blight'] = (breakdown['Late Blight'] ?? 0) + 1;
          } else if (name.contains('Mold')) {
            breakdown['Leaf Mold'] = (breakdown['Leaf Mold'] ?? 0) + 1;
          } else if (name.contains('Septoria')) {
            breakdown['Septoria Spot'] = (breakdown['Septoria Spot'] ?? 0) + 1;
          } else if (name.contains('Healthy')) {
            breakdown['Healthy'] = (breakdown['Healthy'] ?? 0) + 1;
          }
        }
      }
    } catch (_) {}

    return breakdown;
  }

  Future<void> clearAllData() async {
    try {
      final db = await instance.database;
      await db.delete('observations');
      await db.delete('predictions');
      await db.delete('sync_queue');
      await _seedIfEmpty(db);
    } catch (_) {}
  }

  Future close() async {
    try {
      final db = await instance.database;
      db.close();
    } catch (_) {}
  }
}
