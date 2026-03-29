import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/appointment.dart';
import '../services/firebase_service.dart';
import '../services/email_service.dart';

class BookAppointmentPage extends StatefulWidget {
  final User user;

  const BookAppointmentPage({Key? key, required this.user}) : super(key: key);

  @override
  _BookAppointmentPageState createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final EmailService _emailService = EmailService();
  bool _isLoading = false;

  String _petName = '';
  String _petType = 'Dog';
  String _serviceType = 'Check-up';
  String _notes = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  final List<String> _petTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];
  final List<String> _serviceTypes = [
    'Check-up',
    'Vaccination',
    'Surgery',
    'Grooming',
    'Dental Care'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final appointmentDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final timeString = _selectedTime.format(context);

        final appointment = Appointment(
          id: '',
          petName: _petName,
          ownerName: widget.user.fullName,
          petType: _petType,
          serviceType: _serviceType,
          date: appointmentDateTime,
          time: timeString,
          status: 'requested',
          contactPhone: widget.user.phoneNumber,
          contactEmail: widget.user.email,
          notes: _notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          confirmationId: '',
        );

        // Add appointment to Firebase
        final appointmentId = await _firebaseService.addAppointment(appointment);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Send confirmation email
        try {
          // Create appointment with proper ID
          final appointmentWithId = appointment.copyWith(id: appointmentId);
          await _emailService.sendAppointmentConfirmation(appointmentWithId);
        } catch (e) {
          print('Failed to send email: $e');
          // Don't fail the appointment if email fails
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Appointment booked successfully! A confirmation email has been sent.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button safely
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Appointment'),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.event_available,
                            size: 32,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Schedule Your Pet\'s Appointment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Fill in the details below to book an appointment',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pet Information Section
                    Text(
                      'Pet Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pet Name
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Pet Name',
                        hintText: 'Enter your pet\'s name',
                        prefixIcon: const Icon(Icons.pets),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your pet\'s name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _petName = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pet Type
                    DropdownButtonFormField<String>(
                      value: _petType,
                      decoration: InputDecoration(
                        labelText: 'Pet Type',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: _petTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _petType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Service Information Section
                    Text(
                      'Service Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service Type
                    DropdownButtonFormField<String>(
                      value: _serviceType,
                      decoration: InputDecoration(
                        labelText: 'Service Type',
                        prefixIcon: const Icon(Icons.medical_services),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: _serviceTypes
                          .map((service) => DropdownMenuItem(
                                value: service,
                                child: Text(service),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _serviceType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Appointment Date & Time Section
                    Text(
                      'Appointment Date & Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Date: ${_selectedDate.toString().split(' ')[0]}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Picker
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Time: ${_selectedTime.format(context)}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Additional Notes
                    Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Any special requirements or medical history?',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onSaved: (value) {
                        _notes = value ?? '';
                      },
                    ),
                    const SizedBox(height: 24),

                    // Book Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _bookAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        ),
      );
  }
}
