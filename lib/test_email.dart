import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/email_service.dart';
import 'models/appointment.dart';
import 'services/firebase_service.dart';
import 'services/pdf_service.dart';

// This is a test script to manually send a confirmation email and SMS
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

  // Create a test appointment
  final testAppointment = Appointment(
    id: 'test-appointment-001',
    petName: 'Buddy',
    ownerName: 'John Doe',
    petType: 'Dog',
    serviceType: 'Vaccination',
    date: DateTime.now().add(const Duration(days: 2)),
    time: '10:30',
    status: 'confirmed',
    contactPhone: '+1234567890', // Replace with actual phone number
    contactEmail: 'test@example.com', // Replace with actual email
    notes: 'This is a test appointment',
    confirmationId: pdfService.generateConfirmationId(),
  );

  // Print appointment details
  print('Sending confirmation for appointment:');
  print('Pet Name: ${testAppointment.petName}');
  print('Owner: ${testAppointment.ownerName}');
  print(
      'Date: ${testAppointment.date.day}/${testAppointment.date.month}/${testAppointment.date.year}');
  print('Time: ${testAppointment.time}');
  print('Confirmation ID: ${testAppointment.confirmationId}');

  try {
    // First, check if admin settings are configured
    final adminSettings = await firebaseService.getAdminSettings();
    print('Retrieved admin settings:');
    print('Email enabled: ${adminSettings.emailEnabled}');
    print('Email username: ${adminSettings.emailUsername}');
    print('Email display name: ${adminSettings.emailDisplayName}');
    print('SMS enabled: ${adminSettings.smsEnabled}');

    if (!adminSettings.emailEnabled ||
        adminSettings.emailUsername.isEmpty ||
        adminSettings.emailPassword.isEmpty) {
      print('WARNING: Email settings are not properly configured!');
      print(
          'Please configure email settings in the admin panel before testing.');
    }

    // Send email confirmation
    print('Sending email confirmation...');
    await emailService.sendAppointmentConfirmation(testAppointment);
    print('Email confirmation sent successfully!');

    // Also send a request receipt for testing
    print('Sending email receipt...');
    await emailService.sendAppointmentRequestReceipt(testAppointment);
    print('Email receipt sent successfully!');

    // Optionally update the appointment in Firestore
    // Uncomment this if you want to update the actual database
    // print('Updating appointment in Firestore...');
    // await firebaseService.updateAppointment(testAppointment);
    // print('Appointment updated in Firestore successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
