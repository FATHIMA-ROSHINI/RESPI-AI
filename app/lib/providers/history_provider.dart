import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';

class HistoryState {
  final List<HistoryRecord> records;
  final bool isLoading;
  final String? selectedFilter;
  final String? error;

  HistoryState({
    this.records = const [],
    this.isLoading = false,
    this.selectedFilter = 'all',
    this.error,
  });

  HistoryState copyWith({
    List<HistoryRecord>? records,
    bool? isLoading,
    String? selectedFilter,
    String? error,
  }) {
    return HistoryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      error: error ?? this.error,
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  late final DatabaseService _db;
  bool _initialized = false;

  @override
  HistoryState build() {
    if (!_initialized) {
      _db = DatabaseService();
      _initialized = true;
      _loadRecords();
    }
    return HistoryState(isLoading: false);
  }

  Future<void> _loadRecords() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await _db.getAllRecords();
      state = state.copyWith(records: records, isLoading: false);
      debugPrint('Loaded ${records.length} records from database');
    } catch (e) {
      debugPrint('Error loading records: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addRecord(HistoryRecord record) async {
    try {
      await _db.insertRecord(record);
      await _loadRecords();
      debugPrint('Record added successfully');
      return true;
    } catch (e) {
      debugPrint('Error adding record: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<HistoryRecord?> addFromAnalysis({
    required double riskScore,
    required String classification,
    required String condition,
    required double confidence,
    List<String> symptoms = const [],
    String? notes,
    String? patientId,
  }) async {
    final record = HistoryRecord(
      id: const Uuid().v4(),
      patientId: patientId,
      timestamp: DateTime.now(),
      riskScore: riskScore,
      classification: classification,
      condition: condition,
      confidence: confidence,
      symptoms: symptoms,
      notes: notes,
    );
    
    try {
      await _db.insertRecord(record);
      await _loadRecords();
      debugPrint('Analysis saved to database: ${record.id}');
      return record;
    } catch (e) {
      debugPrint('Error saving analysis: $e');
      state = state.copyWith(error: 'Failed to save: $e');
      return null;
    }
  }

  Future<void> updateRecord(HistoryRecord record) async {
    try {
      await _db.insertRecord(record);
      await _loadRecords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _db.deleteRecord(id);
      await _loadRecords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> clearAll() async {
    try {
      await _db.clearAll();
      state = state.copyWith(records: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<HistoryRecord>> getRecordsForPatient(String patientId) async {
    try {
      final db = await _db.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'analysis_history',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'timestamp DESC',
      );
      return List.generate(maps.length, (i) {
        return HistoryRecord.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting records for patient: $e');
      return [];
    }
  }

  Future<void> setFilter(String filter) async {
    state = state.copyWith(selectedFilter: filter, isLoading: true);
    try {
      List<HistoryRecord> records;
      final now = DateTime.now();

      switch (filter) {
        case '7days':
          records = await _db.getRecordsForRange(
            now.subtract(const Duration(days: 7)),
            now,
          );
          break;
        case '30days':
          records = await _db.getRecordsForRange(
            now.subtract(const Duration(days: 30)),
            now,
          );
          break;
        default:
          records = await _db.getAllRecords();
      }

      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadRecords();
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  () => HistoryNotifier(),
);
