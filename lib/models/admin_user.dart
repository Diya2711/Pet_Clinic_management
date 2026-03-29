import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String id;
  final String username;
  final String
      password; // Note: In a production app, never store plain passwords
  final String email;
  final String role; // 'admin', 'super_admin', etc.
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminUser({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    this.role = 'admin',
    this.isActive = true,
    DateTime? createdAt,
    this.lastLogin,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert AdminUser object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password, // In a real app, this should be hashed
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  // Create an AdminUser object from a Firestore snapshot
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AdminUser(
      id: doc.id,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'admin',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  // Create a copy of this user with updated fields
  AdminUser copyWith({
    String? id,
    String? username,
    String? password,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
