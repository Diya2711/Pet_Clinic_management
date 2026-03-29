import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/email_service.dart';
import 'services/firebase_service.dart';
import 'services/pdf_service.dart';
import 'models/appointment.dart';

// This script finds a specific appointment and manually sends a confirmation email
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

  // Create services
  final EmailService emailService = EmailService();
  final FirebaseService firebaseService = FirebaseService();
  final PdfService pdfService = PdfService();

  // Replace with the actual appointment ID
  const String appointmentId = 'APPOINTMENT_ID_HERE';

  try {
    // First, check if admin settings are configured
    final adminSettings = await firebaseService.getAdminSettings();
    print('Retrieved admin settings:');
    print('Email enabled: ${adminSettings.emailEnabled}');
    print('Email username: ${adminSettings.emailUsername}');

    if (!adminSettings.emailEnabled ||
        adminSettings.emailUsername.isEmpty ||
        adminSettings.emailPassword.isEmpty) {
      print('WARNING: Email settings are not properly configured!');
      print(
          'Please run update_admin_settings.dart first to configure email settings.');
      return;
    }

    // Get appointments stream
    final appointments = await firebaseService.getAppointments().first;

    // Find the target appointment or the first one if ID not specified
    Appointment? targetAppointment;

    if (appointmentId == 'APPOINTMENT_ID_HERE') {
      // If no specific ID, take the first appointment in the list
      if (appointments.isNotEmpty) {
        targetAppointment = appointments.first;
        print('Using the first appointment (ID: ${targetAppointment.id})');
      }
    } else {
      // Find appointment by ID
      targetAppointment = appointments.firstWhere(
        (appointment) => appointment.id == appointmentId,
        orElse: () =>
            throw Exception('Appointment with ID $appointmentId not found'),
      );
    }

    if (targetAppointment == null) {
      print('No appointments found in the database.');
      return;
    }

    // Print appointment details
    print('Found appointment:');
    print('ID: ${targetAppointment.id}');
    print('Pet Name: ${targetAppointment.petName}');
    print('Owner: ${targetAppointment.ownerName}');
    print('Email: ${targetAppointment.contactEmail}');
    print('Status: ${targetAppointment.status}');
    print('Confirmation ID: ${targetAppointment.confirmationId}');

    // Make sure the appointment has a confirmation ID
    Appointment appointmentToSend = targetAppointment;
    if (targetAppointment.confirmationId == null) {
      // Generate a confirmation ID if it doesn't have one
      final confirmationId = pdfService.generateConfirmationId();
      appointmentToSend = targetAppointment.copyWith(
        status: 'confirmed',
        confirmationId: confirmationId,
        updatedAt: DateTime.now(),
      );

      // Update appointment in Firestore
      print(
          'Updating appointment with confirmation ID: ${appointmentToSend.confirmationId}');
      await firebaseService.updateAppointment(appointmentToSend);
      print('Appointment updated in Firestore successfully!');
    }

    // Send email confirmation
    print('Sending email confirmation to ${appointmentToSend.contactEmail}...');
    await emailService.sendAppointmentConfirmation(appointmentToSend);
    print('Email confirmation sent successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
