class HistoryRecord {
  final String id;
  final String? patientId;
  final DateTime timestamp;
  final double riskScore;
  final String classification;
  final String condition;
  final String? notes;
  final List<String> symptoms;
  final String? audioPath;
  final double confidence;
  final String? reportPath;

  HistoryRecord({
    required this.id,
    this.patientId,
    required this.timestamp,
    required this.riskScore,
    required this.classification,
    required this.condition,
    this.notes,
    this.symptoms = const [],
    this.audioPath,
    required this.confidence,
    this.reportPath,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    List<String> symptomsList = [];
    if (json['symptoms'] != null) {
      if (json['symptoms'] is String) {
        try {
          final decoded = Uri.decodeComponent(json['symptoms']);
          symptomsList = decoded.split(',').where((s) => s.isNotEmpty).toList();
        } catch (_) {
          symptomsList = json['symptoms'].toString().split(',').where((s) => s.isNotEmpty).toList();
        }
      } else if (json['symptoms'] is List) {
        symptomsList = List<String>.from(json['symptoms']);
      }
    }

    return HistoryRecord(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: json['patient_id'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      riskScore: (json['risk_score'] ?? 0.0).toDouble(),
      classification: json['classification'] ?? 'Unknown',
      condition: json['condition'] ?? 'Unknown',
      notes: json['notes'],
      symptoms: symptomsList,
      audioPath: json['audio_path'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reportPath: json['report_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'timestamp': timestamp.toIso8601String(),
      'risk_score': riskScore,
      'classification': classification,
      'condition': condition,
      'notes': notes,
      'symptoms': symptoms.join(','),
      'audio_path': audioPath,
      'confidence': confidence,
      'report_path': reportPath,
    };
  }

  HistoryRecord copyWith({
    String? id,
    String? patientId,
    DateTime? timestamp,
    double? riskScore,
    String? classification,
    String? condition,
    String? notes,
    List<String>? symptoms,
    String? audioPath,
    double? confidence,
    String? reportPath,
  }) {
    return HistoryRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      riskScore: riskScore ?? this.riskScore,
      classification: classification ?? this.classification,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      symptoms: symptoms ?? this.symptoms,
      audioPath: audioPath ?? this.audioPath,
      confidence: confidence ?? this.confidence,
      reportPath: reportPath ?? this.reportPath,
    );
  }
}
