import 'package:flutter/material.dart';
import 'models/appointment.dart';
import 'services/firebase_service.dart';
import 'services/pdf_service.dart';
import 'admin_settings_page.dart';
import 'login_page.dart';
import 'dart:async';
import 'package:printing/printing.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontFamily: 'Pacifico',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Notification Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AdminSettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Logout admin
                        _firebaseService.logoutAdmin();

                        // Navigate to login page and remove all previous routes
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Confirmed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue,
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  'Pet Clinic Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Requested Appointments Tab
                AppointmentListView(
                  status: 'requested',
                  title: 'Appointment Requests',
                  emptyMessage: 'No pending appointment requests',
                  firebaseService: _firebaseService,
                ),

                // Confirmed Appointments Tab
                AppointmentListView(
                  status: 'confirmed',
                  title: 'Confirmed Appointments',
                  emptyMessage: 'No confirmed appointments',
                  firebaseService: _firebaseService,
                ),

                // All Appointments Tab
                AppointmentListView(
                  status: null,
                  title: 'All Appointments',
                  emptyMessage: 'No appointments found',
                  firebaseService: _firebaseService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentListView extends StatelessWidget {
  final String? status;
  final String title;
  final String emptyMessage;
  final FirebaseService firebaseService;

  const AppointmentListView({
    Key? key,
    required this.status,
    required this.title,
    required this.emptyMessage,
    required this.firebaseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Appointment>>(
            stream: status != null
                ? firebaseService.getAppointmentsByStatus(status!)
                : firebaseService.getAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final appointments = snapshot.data ?? [];

              if (appointments.isEmpty) {
                return Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return AppointmentCard(
                    appointment: appointment,
                    firebaseService: firebaseService,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final FirebaseService firebaseService;
  final Function()? onStatusChanged;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.firebaseService,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {

  Future<void> _updateAppointmentStatus(String status) async {
    try {
      await widget.firebaseService.updateAppointmentStatus(
        widget.appointment.id,
        status,
        DateTime.now(),
      );

      if (widget.onStatusChanged != null) {
        widget.onStatusChanged!();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment ${status.toLowerCase()} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                        widget.appointment.petName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                      const SizedBox(height: 4),
                          Text(
                        widget.appointment.serviceType,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                ),
              ],
            ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.appointment.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.appointment.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(widget.appointment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Owner: ${widget.appointment.ownerName}'),
            Text(
                'Date: ${widget.appointment.date.day}/${widget.appointment.date.month}/${widget.appointment.date.year}'),
            Text('Time: ${widget.appointment.time}'),
            if (widget.appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${widget.appointment.notes}'),
            ],
            const SizedBox(height: 16),
            if (widget.appointment.status == 'requested') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus('confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus('cancelled'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class ConfirmationPreviewPage extends StatelessWidget {
  final Appointment appointment;
  final PdfService pdfService = PdfService();

  ConfirmationPreviewPage({
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
                await pdfService.printAppointmentConfirmation(appointment);
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
            pdfService.generateAppointmentConfirmation(appointment),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'PetClinic_Confirmation_${appointment.confirmationId}.pdf',
      ),
    );
  }
}
