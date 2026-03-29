import 'package:flutter/material.dart';
import 'models/appointment.dart';
import 'services/firebase_service.dart';
import 'services/pdf_service.dart';
import 'package:printing/printing.dart';

class AppointmentStatusPage extends StatefulWidget {
  const AppointmentStatusPage({Key? key}) : super(key: key);

  @override
  _AppointmentStatusPageState createState() => _AppointmentStatusPageState();
}

class _AppointmentStatusPageState extends State<AppointmentStatusPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final PdfService _pdfService = PdfService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _confirmationIdController = TextEditingController();

  bool _isLoading = false;
  Appointment? _foundAppointment;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _confirmationIdController.dispose();
    super.dispose();
  }

  Future<void> _searchAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _foundAppointment = null;
        _errorMessage = '';
      });

      try {
        // Implementation depends on your Firebase service
        // This is a placeholder for the actual query functionality
        // You'll need to add this method to your FirebaseService class
        final results = await _firebaseService.searchAppointmentByEmailAndId(
          _emailController.text.trim(),
          _confirmationIdController.text.trim(),
        );

        setState(() {
          _isLoading = false;
          if (results.isNotEmpty) {
            _foundAppointment = results.first;
          } else {
            _errorMessage = 'No appointment found with the given details';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error searching for appointment: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check Appointment Status',
          style: TextStyle(
            fontFamily: 'Pacifico',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction card
            Container(
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Check Your Appointment Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email and confirmation ID to check the status of your appointment or download your confirmation.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Your Email',
                      hintText:
                          'Enter the email you used to book the appointment',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmationIdController,
                    decoration: InputDecoration(
                      labelText: 'Confirmation ID',
                      hintText: 'Enter your appointment confirmation ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.confirmation_number),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the confirmation ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _searchAppointment,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Check Status',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_foundAppointment != null) ...[
              const SizedBox(height: 24),
              _buildAppointmentCard(_foundAppointment!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    IconData statusIcon;

    switch (appointment.status) {
      case 'requested':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.petName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        appointment.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            _buildInfoRow(Icons.pets, 'Pet Type', appointment.petType),
            _buildInfoRow(Icons.person, 'Owner', appointment.ownerName),
            _buildInfoRow(
                Icons.medical_services, 'Service', appointment.serviceType),
            _buildInfoRow(Icons.event, 'Date & Time',
                "${appointment.date.day}/${appointment.date.month}/${appointment.date.year} at ${appointment.time}"),
            if (appointment.confirmationId != null &&
                appointment.status == 'confirmed') ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.confirmation_number, 'Confirmation ID',
                  appointment.confirmationId!),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AppointmentConfirmationPage(
                            appointment: appointment,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description),
                    label: const Text('View Confirmation'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _pdfService
                            .printAppointmentConfirmation(appointment);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error printing confirmation: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                ],
              ),
            ],
            if (appointment.status == 'requested') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your appointment is pending confirmation. Our staff will review and confirm shortly.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentConfirmationPage extends StatelessWidget {
  final Appointment appointment;
  final PdfService _pdfService = PdfService();

  AppointmentConfirmationPage({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment Confirmation',
          style: TextStyle(
            fontFamily: 'Pacifico',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Confirmation',
            onPressed: () async {
              try {
                await _pdfService.printAppointmentConfirmation(appointment);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error printing confirmation: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) =>
            _pdfService.generateAppointmentConfirmation(appointment),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'PetClinic_Confirmation_${appointment.confirmationId}.pdf',
      ),
    );
  }
}
