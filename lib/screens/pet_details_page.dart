import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../services/pet_service.dart';

class PetDetailsPage extends StatefulWidget {
  final String petId;

  const PetDetailsPage({Key? key, required this.petId}) : super(key: key);

  @override
  _PetDetailsPageState createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  final _petService = PetService();
  bool _isLoading = true;
  Pet? _pet;
  List<MedicalRecord> _medicalHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    try {
      final pet = await _petService.getPet(widget.petId);
      final medicalHistory = await _petService.getMedicalHistory(widget.petId);

      if (mounted) {
        setState(() {
          _pet = pet;
          _medicalHistory = medicalHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pet data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet?.name ?? 'Pet Details'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit pet page
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pet == null
              ? const Center(child: Text('Pet not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet Profile Card
                      Card(
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
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.blue.shade100,
                                    backgroundImage: _pet!.photoUrl != null
                                        ? NetworkImage(_pet!.photoUrl!)
                                        : null,
                                    child: _pet!.photoUrl == null
                                        ? Icon(
                                            Icons.pets,
                                            size: 40,
                                            color: Colors.blue.shade800,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pet!.name,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_pet!.type} • ${_pet!.breed}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_pet!.gender} • ${_pet!.weight} kg',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildInfoColumn(
                                    'Age',
                                    _calculateAge(_pet!.dateOfBirth),
                                    Icons.calendar_today,
                                  ),
                                  _buildInfoColumn(
                                    'Medical Records',
                                    _medicalHistory.length.toString(),
                                    Icons.medical_services,
                                  ),
                                  _buildInfoColumn(
                                    'Last Visit',
                                    _getLastVisitDate(),
                                    Icons.event_note,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Medical History Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Medical History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Navigate to add medical record page
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Record'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Medical History List
                      if (_medicalHistory.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.medical_services,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No medical records yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _medicalHistory.length,
                          itemBuilder: (context, index) {
                            final record = _medicalHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(
                                    Icons.medical_services,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                title: Text(
                                  record.diagnosis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${record.date.toLocal().toString().split(' ')[0]} • Dr. ${record.doctorName}',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildRecordItem(
                                          'Treatment',
                                          record.treatment,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildRecordItem(
                                          'Medications',
                                          record.medications.join(', '),
                                        ),
                                        if (record.notes != null) ...[
                                          const SizedBox(height: 8),
                                          _buildRecordItem(
                                            'Notes',
                                            record.notes!,
                                          ),
                                        ],
                                        if (record.attachments != null &&
                                            record.attachments!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          _buildRecordItem(
                                            'Attachments',
                                            record.attachments!.join(', '),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  String _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    final difference = now.difference(dateOfBirth);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();

    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}';
    } else {
      return '$months month${months > 1 ? 's' : ''}';
    }
  }

  String _getLastVisitDate() {
    if (_medicalHistory.isEmpty) {
      return 'No visits yet';
    }

    final lastVisit =
        _medicalHistory.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
    return lastVisit.toLocal().toString().split(' ')[0];
  }
}
