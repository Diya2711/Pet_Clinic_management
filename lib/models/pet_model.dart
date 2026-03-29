class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String type; // e.g., "Dog", "Cat", etc.
  final String breed;
  final DateTime dateOfBirth;
  final String gender;
  final double weight;
  final List<MedicalRecord> medicalHistory;
  final String? photoUrl;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.breed,
    required this.dateOfBirth,
    required this.gender,
    required this.weight,
    this.medicalHistory = const [],
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'type': type,
      'breed': breed,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'medicalHistory': medicalHistory.map((record) => record.toMap()).toList(),
      'photoUrl': photoUrl,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      breed: map['breed'] ?? '',
      dateOfBirth: DateTime.parse(
          map['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      gender: map['gender'] ?? '',
      weight: (map['weight'] ?? 0.0).toDouble(),
      medicalHistory: (map['medicalHistory'] as List<dynamic>?)
              ?.map((record) =>
                  MedicalRecord.fromMap(record as Map<String, dynamic>))
              .toList() ??
          [],
      photoUrl: map['photoUrl'],
    );
  }
}

class MedicalRecord {
  final String id;
  final DateTime date;
  final String diagnosis;
  final String treatment;
  final String doctorName;
  final List<String> medications;
  final String? notes;
  final List<String>? attachments; // URLs to medical reports, X-rays, etc.

  MedicalRecord({
    required this.id,
    required this.date,
    required this.diagnosis,
    required this.treatment,
    required this.doctorName,
    required this.medications,
    this.notes,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'diagnosis': diagnosis,
      'treatment': treatment,
      'doctorName': doctorName,
      'medications': medications,
      'notes': notes,
      'attachments': attachments,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      diagnosis: map['diagnosis'] ?? '',
      treatment: map['treatment'] ?? '',
      doctorName: map['doctorName'] ?? '',
      medications: List<String>.from(map['medications'] ?? []),
      notes: map['notes'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
    );
  }
}
