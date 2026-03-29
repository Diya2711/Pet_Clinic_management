import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  requested, // Initial request from user
  confirmed, // Approved by admin
  cancelled // Cancelled by user or admin
}

class Appointment {
  final String id;
  final String petName;
  final String ownerName;
  final String petType;
  final String serviceType;
  final DateTime date;
  final String time;
  final String status;
  final String contactPhone;
  final String contactEmail;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? confirmationId;

  Appointment({
    required this.id,
    required this.petName,
    required this.ownerName,
    required this.petType,
    required this.serviceType,
    required this.date,
    required this.time,
    this.status = 'requested',
    this.contactPhone = '',
    this.contactEmail = '',
    this.notes = '',
    DateTime? createdAt,
    this.updatedAt,
    this.confirmationId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Appointment object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'petName': petName,
      'ownerName': ownerName,
      'petType': petType,
      'serviceType': serviceType,
      'date': Timestamp.fromDate(date),
      'time': time,
      'status': status,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'confirmationId': confirmationId,
    };
  }

  // Create an Appointment object from a Firestore snapshot
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Appointment(
      id: doc.id,
      petName: data['petName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      petType: data['petType'] ?? '',
      serviceType: data['serviceType'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      status: data['status'] ?? 'requested',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      confirmationId: data['confirmationId'],
    );
  }

  // Create a copy of this appointment with updated fields
  Appointment copyWith({
    String? id,
    String? petName,
    String? ownerName,
    String? petType,
    String? serviceType,
    DateTime? date,
    String? time,
    String? status,
    String? contactPhone,
    String? contactEmail,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? confirmationId,
  }) {
    return Appointment(
      id: id ?? this.id,
      petName: petName ?? this.petName,
      ownerName: ownerName ?? this.ownerName,
      petType: petType ?? this.petType,
      serviceType: serviceType ?? this.serviceType,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      confirmationId: confirmationId ?? this.confirmationId,
    );
  }
}
