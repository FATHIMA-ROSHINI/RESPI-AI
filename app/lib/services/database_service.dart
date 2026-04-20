import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/history_record.dart';
import '../models/patient.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      // Initialize sqflite for desktop platforms
      await getDatabasesPath();
      _isInitialized = true;
      debugPrint('Database service initialized');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      await initialize();
      _database = await _initDatabase();
      debugPrint('Database initialized successfully');
      return _database!;
    } catch (e) {
      debugPrint('Database initialization error: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      // Get the database path
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'resp_ai_history.db');
      debugPrint('Database path: $path');

      final db = await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      debugPrint('Database opened successfully');
      return db;
    } catch (e) {
      debugPrint('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE analysis_history ADD COLUMN symptoms TEXT');
      } catch (e) {
        debugPrint('Error upgrading database: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE analysis_history ADD COLUMN report_path TEXT');
      } catch (e) {
        debugPrint('Error upgrading database for report_path: $e');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS patients (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          age INTEGER,
          gender TEXT,
          phone TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          date_of_birth TEXT,
          medical_record_number TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS analysis_history (
          id TEXT PRIMARY KEY,
          patient_id TEXT,
          timestamp TEXT NOT NULL,
          risk_score REAL NOT NULL,
          classification TEXT NOT NULL,
          condition TEXT NOT NULL,
          confidence REAL NOT NULL,
          notes TEXT,
          symptoms TEXT,
          audio_path TEXT,
          report_path TEXT,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_history_patient ON analysis_history(patient_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_history_timestamp ON analysis_history(timestamp)');
      
      debugPrint('Tables created successfully');
    } catch (e) {
      debugPrint('Error creating table: $e');
    }
  }

  Future<void> insertRecord(HistoryRecord record) async {
    try {
      final db = await database;
      await db.insert(
        'analysis_history',
        record.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Record inserted: ${record.id}');
    } catch (e) {
      debugPrint('Error inserting record: $e');
      rethrow;
    }
  }

  Future<List<HistoryRecord>> getAllRecords() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'analysis_history',
        orderBy: 'timestamp DESC',
      );
      debugPrint('Found ${maps.length} records');
      return List.generate(maps.length, (i) {
        return HistoryRecord.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting records: $e');
      return [];
    }
  }

  Future<List<HistoryRecord>> getRecordsForRange(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'analysis_history',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'timestamp DESC',
      );

      return List.generate(maps.length, (i) {
        return HistoryRecord.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting records for range: $e');
      return [];
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final db = await database;
      await db.delete(
        'analysis_history',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting record: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('analysis_history');
    } catch (e) {
      debugPrint('Error clearing database: $e');
    }
  }

  Future<int> getRecordCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM analysis_history');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting record count: $e');
      return 0;
    }
  }

  Future<void> insertPatient(Patient patient) async {
    try {
      final db = await database;
      await db.insert(
        'patients',
        patient.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Patient inserted: ${patient.id}');
    } catch (e) {
      debugPrint('Error inserting patient: $e');
      rethrow;
    }
  }

  Future<List<Patient>> getAllPatients() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'patients',
        orderBy: 'name ASC',
      );
      debugPrint('Found ${maps.length} patients');
      return List.generate(maps.length, (i) {
        return Patient.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting patients: $e');
      return [];
    }
  }

  Future<Patient?> getPatient(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Patient.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting patient: $e');
      return null;
    }
  }

  Future<void> updatePatient(Patient patient) async {
    try {
      final db = await database;
      await db.update(
        'patients',
        patient.toJson(),
        where: 'id = ?',
        whereArgs: [patient.id],
      );
      debugPrint('Patient updated: ${patient.id}');
    } catch (e) {
      debugPrint('Error updating patient: $e');
      rethrow;
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      final db = await database;
      await db.delete(
        'patients',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Patient deleted: $id');
    } catch (e) {
      debugPrint('Error deleting patient: $e');
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'patients',
        where: 'name LIKE ? OR phone LIKE ? OR medical_record_number LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return List.generate(maps.length, (i) {
        return Patient.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error searching patients: $e');
      return [];
    }
  }

  Future<int> getPatientCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM patients');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting patient count: $e');
      return 0;
    }
  }

  Future<int> getRecordCountForPatient(String patientId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM analysis_history WHERE patient_id = ?',
        [patientId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting record count for patient: $e');
      return 0;
    }
  }
}
