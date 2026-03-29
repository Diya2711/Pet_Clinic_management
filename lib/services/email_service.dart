import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/appointment.dart';
import '../models/admin_settings.dart';
import './firebase_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  // Singleton pattern
  static final EmailService _instance = EmailService._internal();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory EmailService() {
    return _instance;
  }

  EmailService._internal();

  // Get admin settings
  Future<AdminSettings> _getSettings() async {
    return await _firebaseService.getAdminSettings();
  }

  // Send appointment confirmation email using Firestore approach (for web)
  Future<void> sendAppointmentConfirmation(Appointment appointment) async {
    try {
      // Get admin settings
      AdminSettings settings = await _getSettings();

      // Check if email is enabled
      if (!settings.emailEnabled ||
          settings.emailUsername.isEmpty ||
          settings.emailPassword.isEmpty) {
        print('Email notifications are disabled or not configured');
        print(
            'Username: ${settings.emailUsername.isNotEmpty ? 'Provided' : 'Missing'}');
        print(
            'Password: ${settings.emailPassword.isNotEmpty ? 'Provided' : 'Missing'}');
        print('Email Enabled: ${settings.emailEnabled}');
        return;
      }

      print(
          'Preparing to send email from: ${settings.emailUsername} to: ${appointment.contactEmail}');

      // Create an email request document in Firestore
      // This is a workaround for the web platform limitations
      // A cloud function would pick this up and send the actual email
      try {
        // Format email content
        final emailContent = '''
          <h1>Appointment Confirmed</h1>
          <p>Dear ${appointment.ownerName},</p>
          <p>Your appointment for ${appointment.petName} has been confirmed.</p>
          
          <div style="background-color: #f2f9ff; padding: 15px; border: 1px solid #0077cc; border-radius: 5px; margin: 20px 0;">
            <h3 style="color: #0077cc; margin-top: 0;">Confirmation Details</h3>
            <p><strong>Confirmation ID:</strong> ${appointment.confirmationId}</p>
            <p><strong>Please save this confirmation ID.</strong> You will need it to check your appointment status.</p>
          </div>
          
          <h3>Appointment Details:</h3>
          <table style="border-collapse: collapse; width: 100%;">
            <tr>
              <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Service:</strong></td>
              <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.serviceType}</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Date:</strong></td>
              <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.date.day}/${appointment.date.month}/${appointment.date.year}</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Time:</strong></td>
              <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.time}</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Pet Name:</strong></td>
              <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.petName}</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Pet Type:</strong></td>
              <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.petType}</td>
            </tr>
          </table>
          
          <p>If you need to reschedule or cancel, please contact us at (123) 456-7890.</p>
          <p>Thank you for choosing our Pet Clinic!</p>
          
          <div style="background-color: #f8f8f8; padding: 10px; margin-top: 30px; font-size: 12px; color: #666;">
            <p>You can check your appointment status anytime by visiting our website and using your confirmation ID: ${appointment.confirmationId}</p>
          </div>
        ''';

        // Create a document in the 'email_queue' collection
        await _firestore.collection('email_queue').add({
          'to': appointment.contactEmail,
          'from': settings.emailUsername,
          'fromName': settings.emailDisplayName,
          'subject': 'Pet Clinic Appointment Confirmation',
          'html': emailContent,
          'username': settings.emailUsername,
          'password': settings.emailPassword,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'appointmentId': appointment.id,
          'appointmentConfirmationId': appointment.confirmationId,
        });

        print(
            'Email request added to queue in Firestore. Email will be sent by the server.');

        // Also directly try sending with Gmail if not in web platform
        try {
          await _sendDirectEmail(
            settings.emailUsername,
            settings.emailPassword,
            settings.emailDisplayName,
            appointment.contactEmail,
            'Pet Clinic Appointment Confirmation',
            emailContent,
          );
        } catch (directError) {
          print('Direct email sending failed (expected in web): $directError');
          // This is expected to fail in web, so we just log it
        }
      } catch (e) {
        print('Error creating email request in Firestore: $e');
        throw 'Failed to create email request: ${e.toString()}';
      }

      // Send SMS if enabled
      if (settings.smsEnabled && settings.smsApiKey.isNotEmpty) {
        print('SMS is enabled, attempting to send SMS...');
        await _sendSMS(
            appointment.contactPhone,
            'Your Pet Clinic appointment for ${appointment.petName} on ${appointment.date.day}/${appointment.date.month}/${appointment.date.year} at ${appointment.time} has been confirmed. Confirmation ID: ${appointment.confirmationId}',
            settings);
      } else {
        print('SMS is disabled or not configured.');
        print('SMS Enabled: ${settings.smsEnabled}');
        print(
            'SMS API Key: ${settings.smsApiKey.isNotEmpty ? 'Provided' : 'Missing'}');
      }
    } catch (e) {
      print('Error sending confirmation email: $e');
      // Log detailed error information
      if (e is MailerException) {
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }
      // Rethrow the error so the calling code can handle it
      throw 'Failed to send email: ${e.toString()}';
    }
  }

  // Send appointment request confirmation to user
  Future<void> sendAppointmentRequestReceipt(Appointment appointment) async {
    try {
      // Get admin settings
      AdminSettings settings = await _getSettings();

      // Check if email is enabled
      if (!settings.emailEnabled ||
          settings.emailUsername.isEmpty ||
          settings.emailPassword.isEmpty) {
        print('Email notifications are disabled or not configured');
        return;
      }

      print(
          'Preparing to send request receipt from: ${settings.emailUsername} to: ${appointment.contactEmail}');

      // Format email content
      final emailContent = '''
        <h1>Appointment Request Received</h1>
        <p>Dear ${appointment.ownerName},</p>
        <p>Thank you for requesting an appointment for ${appointment.petName}.</p>
        
        <h3>Appointment Details:</h3>
        <table style="border-collapse: collapse; width: 100%;">
          <tr>
            <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Service:</strong></td>
            <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.serviceType}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Requested Date:</strong></td>
            <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.date.day}/${appointment.date.month}/${appointment.date.year}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Requested Time:</strong></td>
            <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.time}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Pet Name:</strong></td>
            <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.petName}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #dddddd;"><strong>Pet Type:</strong></td>
            <td style="padding: 8px; border: 1px solid #dddddd;">${appointment.petType}</td>
          </tr>
        </table>
        
        <p>Our team will review your request and send a confirmation email shortly.</p>
        <p>If you have any questions, please contact us at (123) 456-7890.</p>
        <p>Thank you for choosing our Pet Clinic!</p>
      ''';

      // Create a document in the 'email_queue' collection
      await _firestore.collection('email_queue').add({
        'to': appointment.contactEmail,
        'from': settings.emailUsername,
        'fromName': settings.emailDisplayName,
        'subject': 'Pet Clinic Appointment Request Received',
        'html': emailContent,
        'username': settings.emailUsername,
        'password': settings.emailPassword,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'appointmentId': appointment.id,
      });

      print('Email request receipt added to queue in Firestore.');

      // Also directly try sending with Gmail if not in web platform
      try {
        await _sendDirectEmail(
          settings.emailUsername,
          settings.emailPassword,
          settings.emailDisplayName,
          appointment.contactEmail,
          'Pet Clinic Appointment Request Received',
          emailContent,
        );
      } catch (directError) {
        print('Direct email sending failed (expected in web): $directError');
        // This is expected to fail in web, so we just log it
      }

      // Send SMS if enabled
      if (settings.smsEnabled &&
          settings.smsApiKey.isNotEmpty &&
          appointment.contactPhone.isNotEmpty) {
        print('SMS is enabled, attempting to send SMS notification...');
        await _sendSMS(
            appointment.contactPhone,
            'Thank you for your Pet Clinic appointment request. We will confirm shortly.',
            settings);
      }
    } catch (e) {
      print('Error sending request receipt email: $e');
      // Log detailed error information
      if (e is MailerException) {
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }
      // Rethrow the error so the calling code can handle it
      throw 'Failed to send email: ${e.toString()}';
    }
  }

  // Try direct email sending (will work in non-web platforms)
  Future<void> _sendDirectEmail(
      String username,
      String password,
      String displayName,
      String recipient,
      String subject,
      String htmlContent) async {
    try {
      // For Gmail, use smtp.gmail.com with port 587
      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, displayName)
        ..recipients.add(recipient)
        ..subject = subject
        ..html = htmlContent;

      final sendReport = await send(message, smtpServer);
      print('Direct email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error in direct email sending: $e');
      throw e;
    }
  }

  // Send SMS using a third-party SMS API service
  Future<void> _sendSMS(
      String phoneNumber, String message, AdminSettings settings) async {
    try {
      if (phoneNumber.isEmpty) {
        print('Phone number is empty, SMS not sent');
        return;
      }

      print('Sending SMS to $phoneNumber');

      // This is a sample implementation using a generic API approach
      // You would replace this with the specific API endpoint and parameters for your SMS provider
      final response = await http.post(
        Uri.parse('https://your-sms-provider.com/api/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.smsApiKey}',
        },
        body: jsonEncode({
          'from': settings.smsFrom,
          'to': phoneNumber,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        print('SMS sent successfully');
      } else {
        print('Failed to send SMS: ${response.body}');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }

  // Test the email configuration
  Future<bool> testEmailConfiguration(String testEmail) async {
    try {
      // Get admin settings
      AdminSettings settings = await _getSettings();

      // Check if email is enabled
      if (!settings.emailEnabled ||
          settings.emailUsername.isEmpty ||
          settings.emailPassword.isEmpty) {
        print('Email notifications are disabled or not configured');
        throw 'Email settings not properly configured. Please check your username and password.';
      }

      print('Testing email configuration with:');
      print('From: ${settings.emailUsername}');
      print('To: $testEmail');

      // Create HTML content for test email
      final htmlContent = '''
        <h1>Email Configuration Test</h1>
        <p>This is a test email from the Pet Clinic system.</p>
        <p>If you received this email, the email configuration is working correctly.</p>
        <hr>
        <p style="color: #666; font-size: 12px;">Sent from Pet Clinic Email Service</p>
      ''';

      // Create a document in the 'email_queue' collection
      await _firestore.collection('email_queue').add({
        'to': testEmail,
        'from': settings.emailUsername,
        'fromName': settings.emailDisplayName,
        'subject': 'Pet Clinic Email Configuration Test',
        'html': htmlContent,
        'username': settings.emailUsername,
        'password': settings.emailPassword,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'isTest': true,
      });

      print('Test email request added to queue in Firestore.');

      // Also directly try sending with Gmail if not in web platform
      try {
        await _sendDirectEmail(
          settings.emailUsername,
          settings.emailPassword,
          settings.emailDisplayName,
          testEmail,
          'Pet Clinic Email Configuration Test',
          htmlContent,
        );
      } catch (directError) {
        print('Direct email sending failed (expected in web): $directError');
        // This is expected to fail in web, so we just log it
      }

      // Add a database flag to indicate the test was successful
      await _firestore.collection('admin_logs').add({
        'action': 'test_email_sent',
        'to': testEmail,
        'from': settings.emailUsername,
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error in test email configuration: $e');
      // Log detailed error information
      if (e is MailerException) {
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }

      // Add a database flag to indicate the test failed
      await _firestore.collection('admin_logs').add({
        'action': 'test_email_failed',
        'error': e.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      return false;
    }
  }

  // Show a troubleshooting dialog
  static void showEmailTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Troubleshooting Guide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'If you\'re having trouble sending emails, here are some common solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. For Gmail users:'),
              Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                    '• Enable 2-Step Verification on your Google account\n• Generate an App Password (not your regular password)\n• Use the App Password in the Email Settings'),
              ),
              SizedBox(height: 12),
              Text('2. Check your network connection'),
              SizedBox(height: 12),
              Text('3. Make sure you entered the correct email address'),
              SizedBox(height: 12),
              Text(
                  '4. For some email providers, you may need to enable "Less secure apps" in your account settings'),
              SizedBox(height: 16),
              Text(
                'How to get an App Password for Gmail:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(
                    '1. Go to your Google Account\n2. Select Security\n3. Under "Signing in to Google," select App Passwords\n4. At the bottom, choose Select app and choose the app you\'re using\n5. Choose Generate'),
              ),
              SizedBox(height: 16),
              Text(
                'Web Platform Note:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(
                    'In web browsers, direct email sending isn\'t possible due to security restrictions. Your emails are queued in the database and will be sent by the server.'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
