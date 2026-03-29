import 'package:flutter/material.dart';
import 'models/appointment.dart';
import 'services/firebase_service.dart';
import 'services/email_service.dart';

class AppointmentPage extends StatefulWidget {
  final String? initialServiceType;

  const AppointmentPage({Key? key, this.initialServiceType}) : super(key: key);

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final EmailService _emailService = EmailService();
  bool _isLoading = false;

  String _petName = '';
  String _ownerName = '';
  String _petType = 'Dog';
  String _serviceType = 'Check-up';
  String _contactPhone = '';
  String _contactEmail = '';
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

  @override
  void initState() {
    super.initState();
    // Initialize service type if provided
    if (widget.initialServiceType != null) {
      // Map service names from main.dart to appointment page format if needed
      final Map<String, String> serviceMapping = {
        'Vaccination': 'Vaccination',
        'Surgery': 'Surgery',
        'Dental Care': 'Dental Care',
        'Grooming': 'Grooming',
      };

      if (serviceMapping.containsKey(widget.initialServiceType)) {
        _serviceType = serviceMapping[widget.initialServiceType]!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If we're loading, prevent back navigation
        if (_isLoading) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Book Appointment',
            style: TextStyle(
              fontFamily: 'Pacifico',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue,
          elevation: 0,
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
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Submit an appointment request',
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
                              'Your request will be reviewed by our staff who will confirm the appointment time. You will receive a confirmation message once approved.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pet Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Pet Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.pets),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your pet\'s name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _petName = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Owner Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _ownerName = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Pet Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        value: _petType,
                        items: _petTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _petType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _contactPhone = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
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
                        onSaved: (value) {
                          _contactEmail = value!;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Service Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Service Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.medical_services),
                        ),
                        value: _serviceType,
                        items: _serviceTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _serviceType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Additional Notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.note),
                          hintText:
                              'Any specific concerns or information we should know',
                        ),
                        maxLines: 3,
                        onSaved: (value) {
                          _notes = value ?? '';
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Preferred Appointment Time',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                        tileColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Time'),
                        subtitle: Text(
                            '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                        tileColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onTap: () => _selectTime(context),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Request Appointment',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Create a new appointment request
        final newAppointment = Appointment(
          id: '', // This will be set by Firestore
          petName: _petName,
          ownerName: _ownerName,
          petType: _petType,
          serviceType: _serviceType,
          date: _selectedDate,
          time:
              '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          status: 'requested',
          contactPhone: _contactPhone,
          contactEmail: _contactEmail,
          notes: _notes,
        );

        // Add to Firestore
        String appointmentId =
            await _firebaseService.addAppointment(newAppointment);

        // Update appointment with ID for email
        final appointmentWithId = newAppointment.copyWith(id: appointmentId);

        // Send email confirmation receipt
        if (_contactEmail.isNotEmpty) {
          try {
            await _emailService
                .sendAppointmentRequestReceipt(appointmentWithId);
          } catch (emailError) {
            print('Error sending receipt email: $emailError');
            // Continue even if email fails
          }
        }

        setState(() {
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          // Add an option to book another appointment rather than navigating away
          // This keeps the user on the page
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Success!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your appointment request for $_petName has been submitted successfully.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We will review your request and send a confirmation to $_contactEmail.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Just close dialog
                    _resetForm(); // Reset the form for a new appointment
                  },
                  child: const Text('Book Another Appointment'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Just close dialog
                    // No auto-navigation back - let user stay on page
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('Error submitting appointment: $e');

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting request: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _petName = '';
      _ownerName = '';
      _petType = 'Dog';
      _serviceType = 'Check-up';
      _contactPhone = '';
      _contactEmail = '';
      _notes = '';
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    });

    _formKey.currentState?.reset();
  }
}
