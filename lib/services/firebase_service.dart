import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../models/admin_settings.dart';
import '../models/admin_user.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final CollectionReference _appointmentsCollection;
  final CollectionReference _settingsCollection;
  final CollectionReference _adminCollection;

  // Current logged in admin user
  AdminUser? _currentAdmin;

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal()
      : _firestore = FirebaseFirestore.instance,
        _appointmentsCollection =
            FirebaseFirestore.instance.collection('appointments'),
        _settingsCollection = FirebaseFirestore.instance.collection('settings'),
        _adminCollection = FirebaseFirestore.instance.collection('admins') {
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Get all appointments with error handling
  Stream<List<Appointment>> getAppointments() {
    try {
      return _appointmentsCollection
          .orderBy('date')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList();
      }).handleError((error) {
        print('Error fetching appointments: $error');
        // Return empty list on error
        return <Appointment>[];
      });
    } catch (e) {
      print('Error setting up appointments stream: $e');
      // Return empty stream on error
      return Stream.value(<Appointment>[]);
    }
  }

  // Get appointments filtered by status
  Stream<List<Appointment>> getAppointmentsByStatus(String status) {
    try {
      return _appointmentsCollection
          .where('status', isEqualTo: status)
          .snapshots()
          .map((snapshot) {
        final appointments = snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList();
        // Sort by date on the client side to avoid needing a composite index
        appointments.sort((a, b) => b.date.compareTo(a.date));
        return appointments;
      }).handleError((error) {
        print('Error fetching appointments by status: $error');
        // Return empty list on error
        return <Appointment>[];
      });
    } catch (e) {
      print('Error setting up appointments by status stream: $e');
      // Return empty stream on error
      return Stream.value(<Appointment>[]);
    }
  }

  // Add a new appointment with better error handling
  Future<String> addAppointment(Appointment appointment) async {
    try {
      DocumentReference docRef =
          await _appointmentsCollection.add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding appointment: $e');
      // Rethrow with more context
      throw 'Failed to add appointment: ${e.toString()}';
    }
  }

  // Update an existing appointment with better error handling
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _appointmentsCollection
          .doc(appointment.id)
          .update(appointment.toMap());
    } catch (e) {
      print('Error updating appointment: $e');
      throw 'Failed to update appointment: ${e.toString()}';
    }
  }

  // Delete an appointment with better error handling
  Future<void> deleteAppointment(String id) async {
    try {
      await _appointmentsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting appointment: $e');
      throw 'Failed to delete appointment: ${e.toString()}';
    }
  }

  // Get admin settings
  Future<AdminSettings> getAdminSettings() async {
    try {
      // Use a fixed document ID for admin settings
      const String adminSettingsId = 'admin_email_settings';

      DocumentSnapshot docSnapshot =
          await _settingsCollection.doc(adminSettingsId).get();

      if (docSnapshot.exists) {
        return AdminSettings.fromFirestore(docSnapshot);
      } else {
        // Create default settings if none exist
        AdminSettings defaultSettings = AdminSettings(id: adminSettingsId);
        await _settingsCollection
            .doc(adminSettingsId)
            .set(defaultSettings.toMap());
        return defaultSettings;
      }
    } catch (e) {
      print('Error getting admin settings: $e');
      // Return default settings on error
      return AdminSettings(id: 'admin_email_settings');
    }
  }

  // Update admin settings
  Future<void> updateAdminSettings(AdminSettings settings) async {
    try {
      await _settingsCollection.doc(settings.id).update(settings.toMap());
    } catch (e) {
      print('Error updating admin settings: $e');
      throw 'Failed to update admin settings: ${e.toString()}';
    }
  }

  // Hash password for security
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Admin Authentication Methods

  // Register a new admin user
  Future<AdminUser> registerAdmin(
      String username, String password, String email) async {
    try {
      // Check if username already exists
      final usernameCheck =
          await _adminCollection.where('username', isEqualTo: username).get();

      if (usernameCheck.docs.isNotEmpty) {
        throw 'Username already exists';
      }

      // Check if email already exists
      final emailCheck =
          await _adminCollection.where('email', isEqualTo: email).get();

      if (emailCheck.docs.isNotEmpty) {
        throw 'Email already exists';
      }

      // Create new admin with hashed password
      final hashedPassword = _hashPassword(password);

      final adminUser = AdminUser(
        id: '',
        username: username,
        password: hashedPassword,
        email: email,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Save to Firestore
      DocumentReference docRef = await _adminCollection.add(adminUser.toMap());

      // Get the admin with the updated ID
      final newAdmin = adminUser.copyWith(id: docRef.id);
      _currentAdmin = newAdmin; // Set as current admin

      return newAdmin;
    } catch (e) {
      print('Error registering admin: $e');
      throw 'Failed to register admin: ${e.toString()}';
    }
  }

  // Login admin
  Future<AdminUser> loginAdmin(String username, String password) async {
    try {
      // Hash password for comparison
      final hashedPassword = _hashPassword(password);

      // Find admin by username and password
      final querySnapshot =
          await _adminCollection.where('username', isEqualTo: username).get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Admin not found';
      }

      // Check each doc (should be only one) for password match
      for (var doc in querySnapshot.docs) {
        final admin = AdminUser.fromFirestore(doc);

        if (admin.password == hashedPassword) {
          // Update last login time
          await _adminCollection.doc(admin.id).update({
            'lastLogin': Timestamp.fromDate(DateTime.now()),
          });

          // Get updated admin
          final updatedAdmin = admin.copyWith(lastLogin: DateTime.now());
          _currentAdmin = updatedAdmin; // Set as current admin

          return updatedAdmin;
        }
      }

      throw 'Invalid password';
    } catch (e) {
      print('Error logging in admin: $e');
      throw 'Failed to login: ${e.toString()}';
    }
  }

  // Get current admin
  AdminUser? getCurrentAdmin() {
    return _currentAdmin;
  }

  // Check if an admin is logged in
  bool isAdminLoggedIn() {
    return _currentAdmin != null;
  }

  // Logout admin
  void logoutAdmin() {
    _currentAdmin = null;
  }

  // Check if any admin exists in the system
  Future<bool> adminExists() async {
    try {
      final querySnapshot = await _adminCollection.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if admin exists: $e');
      return false;
    }
  }

  // Search for appointments by email and confirmation ID
  Future<List<Appointment>> searchAppointmentByEmailAndId(
      String email, String confirmationId) async {
    try {
      final querySnapshot = await _appointmentsCollection
          .where('contactEmail', isEqualTo: email)
          .where('confirmationId', isEqualTo: confirmationId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching for appointment: $e');
      throw 'Failed to search for appointment: ${e.toString()}';
    }
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
    DateTime updatedAt,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      // If the appointment is marked as completed, update the pet type count
      if (newStatus == 'completed') {
        // Get the appointment to know the pet type
        final appointmentDoc = await _firestore
            .collection('appointments')
            .doc(appointmentId)
            .get();

        if (appointmentDoc.exists) {
          final appointment = Appointment.fromFirestore(appointmentDoc);

          // Update the pet type count in statistics
          await _updatePetTypeCount(appointment.petType);
        }
      }
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  Future<void> _updatePetTypeCount(String petType) async {
    try {
      // Get the current count
      final statsDoc =
          await _firestore.collection('statistics').doc('pet_types').get();

      if (statsDoc.exists) {
        // Update the count for the specific pet type
        await _firestore.collection('statistics').doc('pet_types').update({
          petType.toLowerCase(): FieldValue.increment(1),
        });
      } else {
        // Create new statistics document if it doesn't exist
        await _firestore.collection('statistics').doc('pet_types').set({
          petType.toLowerCase(): 1,
        });
      }
    } catch (e) {
      throw Exception('Failed to update pet type count: $e');
    }
  }
}
