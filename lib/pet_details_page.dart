import 'package:flutter/material.dart';

class PetDetailsPage extends StatelessWidget {
  final String petType;
  final int petCount;
  final IconData icon;

  const PetDetailsPage({
    Key? key,
    required this.petType,
    required this.petCount,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$petType Details',
          style: const TextStyle(
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
            Center(
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                radius: 60,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                petType,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                '$petCount pets treated',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Common Health Issues',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHealthIssuesList(),
            const SizedBox(height: 32),
            const Text(
              'Recommended Vaccines',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildVaccinesList(),
            const SizedBox(height: 32),
            const Text(
              'Care Tips',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCareTips(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment requested'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Schedule a Check-up',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIssuesList() {
    final List<Map<String, String>> issues = [
      {
        'issue': 'Skin allergies',
        'description': 'Common in all pet types, requires special medication'
      },
      {
        'issue': 'Dental problems',
        'description': 'Regular cleaning and check-ups recommended'
      },
      {
        'issue': 'Digestive issues',
        'description': 'Diet management and occasional medication'
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issues[index]['issue']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(issues[index]['description']!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVaccinesList() {
    final List<String> vaccines = [
      'Rabies',
      'Distemper',
      'Parvovirus',
      'Annual boosters',
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vaccines.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(vaccines[index]),
        );
      },
    );
  }

  Widget _buildCareTips() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Regular exercise is important for all pets',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '2. Provide clean water and appropriate food',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '3. Schedule regular check-ups',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '4. Watch for changes in behavior or appearance',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
