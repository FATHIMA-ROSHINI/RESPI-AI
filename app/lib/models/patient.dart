class Patient {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? phone;
  final String? notes;
  final DateTime createdAt;
  final DateTime? dateOfBirth;
  final String? medicalRecordNumber;

  Patient({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.phone,
    this.notes,
    required this.createdAt,
    this.dateOfBirth,
    this.medicalRecordNumber,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'],
      gender: json['gender'],
      phone: json['phone'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.tryParse(json['date_of_birth']) 
          : null,
      medicalRecordNumber: json['medical_record_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'medical_record_number': medicalRecordNumber,
    };
  }

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? notes,
    DateTime? createdAt,
    DateTime? dateOfBirth,
    String? medicalRecordNumber,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      medicalRecordNumber: medicalRecordNumber ?? this.medicalRecordNumber,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
