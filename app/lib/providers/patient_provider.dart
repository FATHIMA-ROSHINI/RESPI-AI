import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../services/database_service.dart';

class PatientState {
  final List<Patient> patients;
  final Patient? selectedPatient;
  final bool isLoading;
  final String? error;

  PatientState({
    this.patients = const [],
    this.selectedPatient,
    this.isLoading = false,
    this.error,
  });

  PatientState copyWith({
    List<Patient>? patients,
    Patient? selectedPatient,
    bool? isLoading,
    String? error,
    bool clearSelectedPatient = false,
  }) {
    return PatientState(
      patients: patients ?? this.patients,
      selectedPatient: clearSelectedPatient ? null : (selectedPatient ?? this.selectedPatient),
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PatientNotifier extends Notifier<PatientState> {
  late final DatabaseService _db;

  @override
  PatientState build() {
    _db = ref.read(databaseServiceProvider);
    _loadPatients();
    return PatientState(isLoading: true);
  }

  Future<void> _loadPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final patients = await _db.getAllPatients();
      state = state.copyWith(patients: patients, isLoading: false);
      debugPrint('Loaded ${patients.length} patients from database');
    } catch (e) {
      debugPrint('Error loading patients: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Patient?> addPatient({
    required String name,
    int? age,
    String? gender,
    String? phone,
    String? notes,
    DateTime? dateOfBirth,
    String? medicalRecordNumber,
  }) async {
    final patient = Patient(
      id: const Uuid().v4(),
      name: name,
      age: age,
      gender: gender,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now(),
      dateOfBirth: dateOfBirth,
      medicalRecordNumber: medicalRecordNumber,
    );

    try {
      await _db.insertPatient(patient);
      await _loadPatients();
      debugPrint('Patient added: ${patient.id}');
      return patient;
    } catch (e) {
      debugPrint('Error adding patient: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> updatePatient(Patient patient) async {
    try {
      await _db.updatePatient(patient);
      await _loadPatients();
      if (state.selectedPatient?.id == patient.id) {
        state = state.copyWith(selectedPatient: patient);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating patient: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deletePatient(String id) async {
    try {
      await _db.deletePatient(id);
      if (state.selectedPatient?.id == id) {
        state = state.copyWith(clearSelectedPatient: true);
      }
      await _loadPatients();
      return true;
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void selectPatient(Patient? patient) {
    if (patient == null) {
      state = state.copyWith(clearSelectedPatient: true);
    } else {
      state = state.copyWith(selectedPatient: patient);
    }
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedPatient: true);
  }

  Future<List<Patient>> searchPatients(String query) async {
    if (query.isEmpty) {
      return state.patients;
    }
    try {
      return await _db.searchPatients(query);
    } catch (e) {
      debugPrint('Error searching patients: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    await _loadPatients();
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final patientProvider = NotifierProvider<PatientNotifier, PatientState>(
  () => PatientNotifier(),
);
