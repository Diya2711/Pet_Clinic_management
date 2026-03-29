import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/email_service.dart';
import 'services/firebase_service.dart';
import 'services/pdf_service.dart';
import 'models/appointment.dart';
import 'models/admin_settings.dart';

// Command-line interface for sending appointment confirmations
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

  print('\n=== Pet Clinic Confirmation Tool ===\n');

  // Create services
  final EmailService emailService = EmailService();
  final FirebaseService firebaseService = FirebaseService();
  final PdfService pdfService = PdfService();

  // Check admin settings first
  print('Checking admin settings...');
  AdminSettings settings = await firebaseService.getAdminSettings();

  if (!settings.emailEnabled ||
      settings.emailUsername.isEmpty ||
      settings.emailPassword.isEmpty) {
    print('\nWARNING: Email settings are not configured properly.');
    print('Current settings:');
    print('- Email Enabled: ${settings.emailEnabled}');
    print(
        '- Email Username: ${settings.emailUsername.isEmpty ? "Not set" : settings.emailUsername}');
    print(
        '- Email Password: ${settings.emailPassword.isEmpty ? "Not set" : "Set"}');

    // Ask if user wants to update settings
    print('\nDo you want to update email settings now? (y/n)');
    String? response = stdin.readLineSync()?.toLowerCase();

    if (response == 'y' || response == 'yes') {
      settings = await _promptForEmailSettings(settings, firebaseService);
    } else {
      print(
          '\nContinuing with current settings. Email functionality may not work.');
    }
  } else {
    print('Email settings are configured.');
  }

  // Menu loop
  bool exit = false;
  while (!exit) {
    print('\n===== MENU =====');
    print('1. Send confirmation for existing appointment');
    print('2. Send test email');
    print('3. Create and send new test appointment');
    print('4. View/Update email settings');
    print('5. Exit');
    print('\nEnter your choice (1-5):');

    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        await _sendConfirmationForExistingAppointment(
            firebaseService, emailService, pdfService);
        break;
      case '2':
        await _sendTestEmail(emailService);
        break;
      case '3':
        await _createAndSendTestAppointment(
            firebaseService, emailService, pdfService);
        break;
      case '4':
        settings = await _promptForEmailSettings(settings, firebaseService);
        break;
      case '5':
        exit = true;
        print('Exiting program. Goodbye!');
        break;
      default:
        print('Invalid choice. Please enter a number between 1 and 5.');
    }
  }
}

// Function to prompt for and update email settings
Future<AdminSettings> _promptForEmailSettings(
    AdminSettings currentSettings, FirebaseService firebaseService) async {
  print('\n=== Email Settings Update ===');

  print('Enter Gmail address (current: ${currentSettings.emailUsername}):');
  String? emailUsername = stdin.readLineSync();
  if (emailUsername == null || emailUsername.isEmpty) {
    emailUsername = currentSettings.emailUsername;
  }

  print('Enter Gmail app password:');
  print(
      '(For Gmail, you need to use an App Password, not your regular password)');
  print('Learn more: https://support.google.com/accounts/answer/185833');
  String? emailPassword = stdin.readLineSync();
  if (emailPassword == null || emailPassword.isEmpty) {
    emailPassword = currentSettings.emailPassword;
  }

  print('Enter display name (current: ${currentSettings.emailDisplayName}):');
  String? displayName = stdin.readLineSync();
  if (displayName == null || displayName.isEmpty) {
    displayName = currentSettings.emailDisplayName;
  }

  print(
      'Enable email notifications? (y/n) (current: ${currentSettings.emailEnabled ? "yes" : "no"})');
  String? enableEmailStr = stdin.readLineSync()?.toLowerCase();
  bool enableEmail = enableEmailStr == 'y' || enableEmailStr == 'yes'
      ? true
      : (enableEmailStr == 'n' || enableEmailStr == 'no'
          ? false
          : currentSettings.emailEnabled);

  // Create updated settings
  AdminSettings updatedSettings = AdminSettings(
    id: currentSettings.id,
    emailUsername: emailUsername,
    emailPassword: emailPassword,
    emailDisplayName: displayName,
    smsApiKey: currentSettings.smsApiKey,
    smsFrom: currentSettings.smsFrom,
    emailEnabled: enableEmail,
    smsEnabled: currentSettings.smsEnabled,
  );

  try {
    // Update settings in Firestore
    await firebaseService.updateAdminSettings(updatedSettings);
    print('Email settings updated successfully!');
  } catch (e) {
    print('Error updating settings: $e');
  }

  return updatedSettings;
}

// Function to send confirmation for an existing appointment
Future<void> _sendConfirmationForExistingAppointment(
    FirebaseService firebaseService,
    EmailService emailService,
    PdfService pdfService) async {
  try {
    // Get all appointments
    final appointments = await firebaseService.getAppointments().first;

    if (appointments.isEmpty) {
      print('No appointments found in the database.');
      return;
    }

    // List all appointments for selection
    print('\n=== Available Appointments ===');
    for (int i = 0; i < appointments.length; i++) {
      final appointment = appointments[i];
      print('${i + 1}. ${appointment.petName} (${appointment.ownerName}) - '
          '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} '
          '${appointment.time} - Status: ${appointment.status}');
    }

    print('\nEnter appointment number to send confirmation:');
    String? selection = stdin.readLineSync();
    int selectionNum = int.tryParse(selection ?? '') ?? 0;

    if (selectionNum < 1 || selectionNum > appointments.length) {
      print('Invalid selection.');
      return;
    }

    // Get selected appointment
    Appointment selectedAppointment = appointments[selectionNum - 1];

    // Check if it already has a confirmation ID
    if (selectedAppointment.confirmationId == null ||
        selectedAppointment.status != 'confirmed') {
      print(
          '\nThis appointment is not confirmed yet. Do you want to confirm it? (y/n)');
      String? confirm = stdin.readLineSync()?.toLowerCase();

      if (confirm == 'y' || confirm == 'yes') {
        // Generate confirmation ID and update status
        final confirmationId = pdfService.generateConfirmationId();
        selectedAppointment = selectedAppointment.copyWith(
          status: 'confirmed',
          confirmationId: confirmationId,
          updatedAt: DateTime.now(),
        );

        // Update in Firestore
        await firebaseService.updateAppointment(selectedAppointment);
        print(
            'Appointment confirmed with ID: ${selectedAppointment.confirmationId}');
      } else {
        print('Appointment not confirmed. No email will be sent.');
        return;
      }
    }

    // Send email confirmation
    print(
        '\nSending confirmation email to ${selectedAppointment.contactEmail}...');
    await emailService.sendAppointmentConfirmation(selectedAppointment);
    print('Confirmation email sent successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

// Function to send a test email
Future<void> _sendTestEmail(EmailService emailService) async {
  print('\n=== Send Test Email ===');
  print('Enter recipient email address:');
  String? email = stdin.readLineSync();

  if (email == null || email.isEmpty) {
    print('No email provided. Aborting test.');
    return;
  }

  print('Sending test email to $email...');
  bool success = await emailService.testEmailConfiguration(email);

  if (success) {
    print('Test email sent successfully!');
  } else {
    print('Failed to send test email. Check configuration and try again.');
  }
}

// Function to create and send a test appointment
Future<void> _createAndSendTestAppointment(FirebaseService firebaseService,
    EmailService emailService, PdfService pdfService) async {
  print('\n=== Create Test Appointment ===');

  print('Enter pet name (default: Buddy):');
  String petName = stdin.readLineSync() ?? 'Buddy';

  print('Enter owner name (default: John Doe):');
  String ownerName = stdin.readLineSync() ?? 'John Doe';

  print('Enter email address:');
  String? email = stdin.readLineSync();
  if (email == null || email.isEmpty) {
    print('Email is required. Aborting test.');
    return;
  }

  print('Enter phone number (optional):');
  String phone = stdin.readLineSync() ?? '';

  // Create a test appointment
  final confirmationId = pdfService.generateConfirmationId();
  final testAppointment = Appointment(
    id: 'test-${DateTime.now().millisecondsSinceEpoch}',
    petName: petName,
    ownerName: ownerName,
    petType: 'Dog',
    serviceType: 'Vaccination',
    date: DateTime.now().add(const Duration(days: 2)),
    time: '10:30',
    status: 'confirmed',
    contactPhone: phone,
    contactEmail: email,
    notes: 'This is a test appointment',
    confirmationId: confirmationId,
  );

  print('\nAppointment details:');
  print('Pet: $petName');
  print('Owner: $ownerName');
  print('Email: $email');
  print('Confirmation ID: $confirmationId');

  try {
    // Add to Firestore (optional)
    print('\nDo you want to save this appointment to the database? (y/n)');
    String? saveToDb = stdin.readLineSync()?.toLowerCase();

    if (saveToDb == 'y' || saveToDb == 'yes') {
      final id = await firebaseService.addAppointment(testAppointment);
      print('Appointment saved to database with ID: $id');
    }

    // Send email confirmation
    print('Sending confirmation email...');
    await emailService.sendAppointmentConfirmation(testAppointment);
    print('Confirmation email sent successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
