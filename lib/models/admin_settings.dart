import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettings {
  final String id;
  final String emailUsername;
  final String emailPassword;
  final String emailDisplayName;
  final String smsApiKey;
  final String smsFrom;
  final bool emailEnabled;
  final bool smsEnabled;

  AdminSettings({
    required this.id,
    this.emailUsername = '',
    this.emailPassword = '',
    this.emailDisplayName = 'Pet Clinic',
    this.smsApiKey = '',
    this.smsFrom = '',
    this.emailEnabled = true,
    this.smsEnabled = false,
  });

  // Convert AdminSettings object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'emailUsername': emailUsername,
      'emailPassword': emailPassword,
      'emailDisplayName': emailDisplayName,
      'smsApiKey': smsApiKey,
      'smsFrom': smsFrom,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
    };
  }

  // Create an AdminSettings object from a Firestore snapshot
  factory AdminSettings.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AdminSettings(
      id: doc.id,
      emailUsername: data['emailUsername'] ?? '',
      emailPassword: data['emailPassword'] ?? '',
      emailDisplayName: data['emailDisplayName'] ?? 'Pet Clinic',
      smsApiKey: data['smsApiKey'] ?? '',
      smsFrom: data['smsFrom'] ?? '',
      emailEnabled: data['emailEnabled'] ?? true,
      smsEnabled: data['smsEnabled'] ?? false,
    );
  }

  // Create a copy of this settings with updated fields
  AdminSettings copyWith({
    String? id,
    String? emailUsername,
    String? emailPassword,
    String? emailDisplayName,
    String? smsApiKey,
    String? smsFrom,
    bool? emailEnabled,
    bool? smsEnabled,
  }) {
    return AdminSettings(
      id: id ?? this.id,
      emailUsername: emailUsername ?? this.emailUsername,
      emailPassword: emailPassword ?? this.emailPassword,
      emailDisplayName: emailDisplayName ?? this.emailDisplayName,
      smsApiKey: smsApiKey ?? this.smsApiKey,
      smsFrom: smsFrom ?? this.smsFrom,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
    );
  }
}
