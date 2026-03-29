import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/admin_settings.dart';
import 'services/firebase_service.dart';

// This script updates the admin settings with email credentials
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDI8l3La00qff4C8VcT3d4dzPjHfMLHkg0",
      appId: "1:688423885289:web:8ea81d5178c944f6935378",
      messagingSenderId: "688423885289",
      projectId: "pet-clinic-382e3",
    ),
  );

  print('Firebase initialized successfully');

  // Create service
  final FirebaseService firebaseService = FirebaseService();

  try {
    // Get current settings
    final currentSettings = await firebaseService.getAdminSettings();
    print('Current admin settings:');
    print('Email enabled: ${currentSettings.emailEnabled}');
    print('Email username: ${currentSettings.emailUsername}');
    print('Email display name: ${currentSettings.emailDisplayName}');

    // Update with new settings
    // You should replace these values with your actual Gmail credentials
    final updatedSettings = AdminSettings(
      id: currentSettings.id,
      emailUsername:
          'your.email@gmail.com', // Replace with actual Gmail address
      emailPassword:
          'your-app-password', // Replace with app password (not regular password)
      emailDisplayName: 'Pet Clinic Services',
      smsApiKey:
          'your-sms-api-key', // Replace with actual SMS API key if needed
      smsFrom: 'PetClinic',
      emailEnabled: true,
      smsEnabled: false, // Set to true if you want to enable SMS
    );

    // Update settings in Firestore
    await firebaseService.updateAdminSettings(updatedSettings);
    print('Admin settings updated successfully!');

    // Verify the update
    final verifySettings = await firebaseService.getAdminSettings();
    print('Updated admin settings:');
    print('Email enabled: ${verifySettings.emailEnabled}');
    print('Email username: ${verifySettings.emailUsername}');
    print('Email display name: ${verifySettings.emailDisplayName}');

    print(
        '\nIMPORTANT: Replace the placeholder values with your actual Gmail credentials before running this script.');
    print(
        'For Gmail, you need to use an App Password, not your regular password.');
    print('Learn more: https://support.google.com/accounts/answer/185833');
  } catch (e) {
    print('Error updating admin settings: $e');
  }
}
