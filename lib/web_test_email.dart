import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/email_service.dart';
import 'services/firebase_service.dart';
import 'services/pdf_service.dart';
import 'models/appointment.dart';
import 'models/admin_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDI8l3La00qff4C8VcT3d4dzPjHfMLHkg0",
      appId: "1:688423885289:web:8ea81d5178c944f6935378",
      messagingSenderId: "688423885289",
      projectId: "pet-clinic-382e3",
    ),
  );
  runApp(const EmailTestApp());
}

class EmailTestApp extends StatelessWidget {
  const EmailTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Email Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const EmailTestPage(),
    );
  }
}

class EmailTestPage extends StatefulWidget {
  const EmailTestPage({Key? key}) : super(key: key);

  @override
  _EmailTestPageState createState() => _EmailTestPageState();
}

class _EmailTestPageState extends State<EmailTestPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final EmailService _emailService = EmailService();
  final PdfService _pdfService = PdfService();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String _logOutput = '';
  List<Appointment> _appointments = [];
  AdminSettings? _settings;

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailPasswordController =
      TextEditingController();
  final TextEditingController _emailDisplayNameController =
      TextEditingController();
  final TextEditingController _testEmailController =
      TextEditingController(text: 'test@example.com');
  final TextEditingController _petNameController =
      TextEditingController(text: 'Buddy');
  final TextEditingController _ownerNameController =
      TextEditingController(text: 'John Doe');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailPasswordController.dispose();
    _emailDisplayNameController.dispose();
    _testEmailController.dispose();
    _petNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _logOutput = 'Loading data...\n';
    });

    try {
      // Load admin settings
      final settings = await _firebaseService.getAdminSettings();

      // Load appointments
      final appointments = await _firebaseService.getAppointments().first;

      setState(() {
        _settings = settings;
        _appointments = appointments;
        _emailController.text = settings.emailUsername;
        _emailPasswordController.text = settings.emailPassword;
        _emailDisplayNameController.text = settings.emailDisplayName;
        _isLoading = false;
        _logOutput += 'Data loaded successfully!\n';
        _logOutput += 'Found ${appointments.length} appointments.\n';
        _logOutput +=
            'Email settings: ${settings.emailEnabled ? "Enabled" : "Disabled"}\n';
        _logOutput +=
            'Email username: ${settings.emailUsername.isEmpty ? "Not set" : settings.emailUsername}\n';

        // Check if email is configured
        if (settings.emailUsername.isEmpty || settings.emailPassword.isEmpty) {
          _logOutput += '\n⚠️ EMAIL CONFIGURATION REQUIRED\n';
          _logOutput +=
              'Please configure your email settings before trying to send emails.\n';
          _logOutput +=
              'For Gmail, use an App Password instead of your regular password.\n';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _logOutput += 'Error loading data: $e\n';
      });
    }
  }

  Future<void> _saveEmailSettings() async {
    if (_settings == null) return;

    setState(() {
      _isLoading = true;
      _logOutput += 'Saving email settings...\n';
    });

    try {
      final updatedSettings = AdminSettings(
        id: _settings!.id,
        emailUsername: _emailController.text,
        emailPassword: _emailPasswordController.text,
        emailDisplayName: _emailDisplayNameController.text,
        smsApiKey: _settings!.smsApiKey,
        smsFrom: _settings!.smsFrom,
        emailEnabled: true,
        smsEnabled: _settings!.smsEnabled,
      );

      await _firebaseService.updateAdminSettings(updatedSettings);

      setState(() {
        _settings = updatedSettings;
        _isLoading = false;
        _logOutput += 'Email settings saved successfully!\n';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _logOutput += 'Error saving email settings: $e\n';
      });
    }
  }

  Future<void> _sendTestEmail() async {
    if (_testEmailController.text.isEmpty) {
      setState(() {
        _logOutput += 'Please enter a test email address.\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _logOutput += 'Sending test email to ${_testEmailController.text}...\n';
    });

    try {
      final success =
          await _emailService.testEmailConfiguration(_testEmailController.text);

      setState(() {
        _isLoading = false;
        if (success) {
          _logOutput += 'Test email sent successfully!\n';
        } else {
          _logOutput +=
              'Failed to send test email. Check configuration and try again.\n';
          _logOutput += 'See troubleshooting guide for common issues.\n';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _logOutput += 'Error sending test email: $e\n';

        // Add helpful troubleshooting advice
        if (e.toString().contains('Authentication failed')) {
          _logOutput += '\n⚠️ AUTHENTICATION FAILED\n';
          _logOutput +=
              '• For Gmail, use an App Password, not your regular password\n';
          _logOutput +=
              '• Enable 2-Step Verification first at https://myaccount.google.com/security\n';
          _logOutput +=
              '• Then create an App Password at https://myaccount.google.com/apppasswords\n';
        } else if (e.toString().contains('socket')) {
          _logOutput += '\n⚠️ NETWORK ISSUE\n';
          _logOutput += '• Check your internet connection\n';
          _logOutput +=
              '• Make sure firewall is not blocking outgoing connections\n';
        }
      });
    }
  }

  Future<void> _createAndSendTestAppointment() async {
    if (_testEmailController.text.isEmpty) {
      setState(() {
        _logOutput +=
            'Please enter an email address for the test appointment.\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _logOutput += 'Creating test appointment...\n';
    });

    try {
      // Generate confirmation ID
      final confirmationId = _pdfService.generateConfirmationId();

      // Create test appointment
      final testAppointment = Appointment(
        id: 'test-${DateTime.now().millisecondsSinceEpoch}',
        petName: _petNameController.text,
        ownerName: _ownerNameController.text,
        petType: 'Dog',
        serviceType: 'Vaccination',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '10:30',
        status: 'confirmed',
        contactPhone: '+1234567890',
        contactEmail: _testEmailController.text,
        notes: 'This is a test appointment',
        confirmationId: confirmationId,
      );

      _logOutput += 'Test appointment created:\n';
      _logOutput += 'Pet: ${testAppointment.petName}\n';
      _logOutput += 'Owner: ${testAppointment.ownerName}\n';
      _logOutput += 'Email: ${testAppointment.contactEmail}\n';
      _logOutput += 'Confirmation ID: ${testAppointment.confirmationId}\n';

      // Send confirmation email
      _logOutput += 'Sending confirmation email...\n';
      await _emailService.sendAppointmentConfirmation(testAppointment);

      setState(() {
        _isLoading = false;
        _logOutput += 'Confirmation email sent successfully!\n';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _logOutput += 'Error: $e\n';

        // Add helpful troubleshooting advice
        if (e.toString().contains('Authentication failed')) {
          _logOutput += '\n⚠️ AUTHENTICATION FAILED\n';
          _logOutput +=
              '• For Gmail, use an App Password, not your regular password\n';
          _logOutput += '• Check the troubleshooting guide for more help\n';
        }
      });
    }
  }

  Future<void> _sendConfirmationForExistingAppointment(
      Appointment appointment) async {
    setState(() {
      _isLoading = true;
      _logOutput +=
          'Sending confirmation for appointment: ${appointment.petName}...\n';
    });

    try {
      // Check if appointment needs confirmation
      Appointment appointmentToSend = appointment;
      if (appointment.confirmationId == null ||
          appointment.status != 'confirmed') {
        // Generate confirmation ID and update status
        final confirmationId = _pdfService.generateConfirmationId();
        appointmentToSend = appointment.copyWith(
          status: 'confirmed',
          confirmationId: confirmationId,
          updatedAt: DateTime.now(),
        );

        // Update in Firestore
        await _firebaseService.updateAppointment(appointmentToSend);
        _logOutput +=
            'Appointment confirmed with ID: ${appointmentToSend.confirmationId}\n';

        // Refresh appointments list
        final appointments = await _firebaseService.getAppointments().first;
        setState(() {
          _appointments = appointments;
        });
      }

      // Send email confirmation
      _logOutput +=
          'Sending confirmation email to ${appointmentToSend.contactEmail}...\n';
      await _emailService.sendAppointmentConfirmation(appointmentToSend);

      setState(() {
        _isLoading = false;
        _logOutput += 'Confirmation email sent successfully!\n';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _logOutput += 'Error: $e\n';
      });
    }
  }

  void _showTroubleshootingGuide() {
    EmailService.showEmailTroubleshootingDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Clinic Email Test'),
        actions: [
          // Add a help button in the app bar
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Email Troubleshooting Guide',
            onPressed: _showTroubleshootingGuide,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Troubleshooting Banner
                  if (_settings?.emailUsername.isEmpty == true ||
                      _settings?.emailPassword.isEmpty == true)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.deepOrange),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Email Configuration Required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _showTroubleshootingGuide,
                                child: const Text('Help'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your email is not properly configured. Please enter your Gmail address and an App Password below.',
                          ),
                        ],
                      ),
                    ),

                  // Web Platform Information Banner
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Web Platform Email Handling',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'In web browsers, emails cannot be sent directly due to security restrictions. When you send an email through this interface, it will be queued in the database for processing by the server.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your email configuration is still required for the server to send emails on your behalf.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Email Settings Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Gmail Address',
                                hintText: 'your.email@gmail.com',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Gmail App Password',
                                hintText: 'Your app-specific password',
                                helperText:
                                    'For Gmail, use an App Password, not your regular password',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailDisplayNameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                hintText: 'Pet Clinic Services',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saveEmailSettings,
                                    child: const Text('Save Email Settings'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _showTroubleshootingGuide,
                                  icon:
                                      const Icon(Icons.help_outline, size: 18),
                                  label: const Text('Help'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigoAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Test Email Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send Test Email',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _testEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Recipient Email',
                              hintText: 'test@example.com',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _sendTestEmail,
                              child: const Text('Send Test Email'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Create Test Appointment Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create & Send Test Appointment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _petNameController,
                            decoration: const InputDecoration(
                              labelText: 'Pet Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ownerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Owner Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _createAndSendTestAppointment,
                              child:
                                  const Text('Create & Send Test Appointment'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Existing Appointments Card
                  if (_appointments.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Existing Appointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _appointments.length,
                              itemBuilder: (context, index) {
                                final appointment = _appointments[index];
                                return ListTile(
                                  title: Text(
                                      '${appointment.petName} (${appointment.ownerName})'),
                                  subtitle: Text(
                                    '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} at ${appointment.time} - Status: ${appointment.status}',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () =>
                                        _sendConfirmationForExistingAppointment(
                                            appointment),
                                    child: const Text('Send Confirmation'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Log Output Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Log Output',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadData,
                                tooltip: 'Refresh Data',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 300,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _logOutput,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
