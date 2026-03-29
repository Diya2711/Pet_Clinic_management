import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../services/user_auth_service.dart';
import '../services/pet_service.dart';
import 'user_login_page.dart';
import 'add_pet_page.dart';
import 'book_appointment_page.dart';
import 'tip_details_page.dart';

class UserDashboard extends StatefulWidget {
  final User user;

  const UserDashboard({Key? key, required this.user}) : super(key: key);

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _userAuthService = UserAuthService();
  final _petService = PetService();
  bool _isLoading = false;
  List<Pet> _pets = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pets = await _petService.getUserPets(widget.user.id);
      if (mounted) {
        setState(() {
          _pets = pets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pets: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userAuthService.signOut();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserLoginPage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToAddPet() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddPetPage()),
    );

    if (result == true) {
      _loadPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.user.fullName}'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedTabIndex,
              children: [
                // Home Tab
                _buildHomeTab(),
                // Doctors Tab
                _buildDoctorsTab(),
                // My Pets Tab
                _buildMyPetsTab(),
                // Tips Tab
                _buildTipsTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'My Pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Tips',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.add_circle,
                  label: 'Book\nAppointment',
                  color: Colors.green,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookAppointmentPage(user: widget.user),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.favorite,
                  label: 'Add\nPet',
                  color: Colors.orange,
                  onTap: _navigateToAddPet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.medical_services,
                  label: 'Our\nDoctors',
                  color: Colors.purple,
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // My Pets Summary
          Text(
            'My Pets (${_pets.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          if (_pets.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pets added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddPet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Pet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pets.take(3).length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.pets,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    title: Text(pet.name),
                    subtitle: Text('${pet.breed} • ${pet.type}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab() {
    final doctors = [
      {
        'name': 'Dr. Sarah Johnson',
        'specialization': 'General Practice',
        'experience': '10 years',
        'rating': 4.8,
        'phone': '+1-800-123-4567',
        'bio': 'Experienced veterinarian specializing in general pet care, vaccinations, and health check-ups.',
      },
      {
        'name': 'Dr. Michael Chen',
        'specialization': 'Surgery',
        'experience': '8 years',
        'rating': 4.9,
        'phone': '+1-800-234-5678',
        'bio': 'Expert in surgical procedures including spay/neuter, tumor removal, and orthopedic surgery.',
      },
      {
        'name': 'Dr. Emily Rodriguez',
        'specialization': 'Dental Care',
        'experience': '6 years',
        'rating': 4.7,
        'phone': '+1-800-345-6789',
        'bio': 'Specialist in dental cleaning, treatment, and prevention of dental diseases in pets.',
      },
      {
        'name': 'Dr. James Wilson',
        'specialization': 'Dermatology',
        'experience': '12 years',
        'rating': 4.9,
        'phone': '+1-800-456-7890',
        'bio': 'Specializes in skin conditions, allergies, and dermatological treatments for all pet types.',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Expert Doctors',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Meet our experienced veterinary team',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
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
                            child: Icon(
                              Icons.medical_services,
                              size: 40,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor['name'].toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor['specialization'].toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doctor['rating']} • ${doctor['experience']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        doctor['bio'].toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BookAppointmentPage(user: widget.user),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Book Appointment'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyPetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Pets',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToAddPet,
                icon: const Icon(Icons.add),
                label: const Text('Add Pet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_pets.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pets added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first pet to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
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
                              radius: 35,
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(
                                Icons.pets,
                                size: 35,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pet.breed,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Type: ${pet.type}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPetInfoRow('Gender', pet.gender),
                              const SizedBox(height: 8),
                              _buildPetInfoRow('Weight', '${pet.weight} kg'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    final tips = [
      {
        'title': 'Proper Nutrition',
        'description': 'Feed your pet age-appropriate food. Puppies and kittens need different nutrients than adults.',
        'icon': Icons.restaurant,
        'color': Colors.orange,
        'details': [
          'Choose age-appropriate food formulas',
          'Provide fresh water at all times',
          'Monitor portion sizes to prevent obesity',
          'Include variety in diet with vet approval',
          'Supplement with vitamins if recommended'
        ],
      },
      {
        'title': 'Regular Exercise',
        'description': 'Daily walks and playtime keep your pet healthy and prevent behavioral issues.',
        'icon': Icons.directions_run,
        'color': Colors.green,
        'details': [
          'Daily walks for at least 30 minutes',
          'Interactive play sessions with toys',
          'Mental stimulation through training',
          'Age-appropriate exercise routines',
          'Monitor for signs of fatigue or injury'
        ],
      },
      {
        'title': 'Dental Care',
        'description': 'Brush your pets teeth regularly and schedule professional cleanings annually.',
        'icon': Icons.healing,
        'color': Colors.blue,
        'details': [
          'Brush teeth 2-3 times per week',
          'Use pet-safe toothpaste',
          'Provide dental chews and toys',
          'Annual professional cleanings',
          'Watch for signs of dental disease'
        ],
      },
      {
        'title': 'Vaccinations',
        'description': 'Keep vaccinations up to date (₹1,800 - ₹5,500) to protect against common diseases.',
        'icon': Icons.medical_services,
        'color': Colors.purple,
        'details': [
          'Core vaccines: Rabies, Distemper, Parvovirus, Hepatitis',
          'Non-core vaccines: Bordetella, Lyme, Leptospirosis',
          'Puppy/kitten series starting at 6-8 weeks',
          'Adult booster shots annually',
          'Vaccination schedule based on lifestyle and risk'
        ],
      },
      {
        'title': 'Grooming',
        'description': 'Regular grooming keeps your pet clean, comfortable, and helps detect health issues.',
        'icon': Icons.cleaning_services,
        'color': Colors.pink,
        'details': [
          'Regular brushing to prevent mats',
          'Nail trimming every 3-4 weeks',
          'Ear cleaning and inspection',
          'Bathing as needed (not too frequent)',
          'Professional grooming for breed-specific needs'
        ],
      },
      {
        'title': 'Mental Stimulation',
        'description': 'Use toys, training, and games to keep your pets mind active and engaged.',
        'icon': Icons.games,
        'color': Colors.red,
        'details': [
          'Puzzle toys and treat dispensers',
          'Training sessions for new commands',
          'Interactive play with owners',
          'Rotating toys to prevent boredom',
          'Socialization with other pets and people'
        ],
      },
      {
        'title': 'Parasite Prevention',
        'description': 'Use regular flea, tick, and worm prevention treatments recommended by your vet.',
        'icon': Icons.shield,
        'color': Colors.teal,
        'details': [
          'Monthly flea and tick preventatives',
          'Heartworm prevention medication',
          'Regular fecal exams for intestinal parasites',
          'Environmental control (cleaning yard)',
          'Year-round protection in some areas'
        ],
      },
      {
        'title': 'Regular Checkups',
        'description': 'Annual vet visits help catch health problems early and keep records updated.',
        'icon': Icons.local_hospital,
        'color': Colors.indigo,
        'details': [
          'Annual wellness examinations',
          'Vaccination updates',
          'Dental assessments',
          'Weight and body condition checks',
          'Blood work and diagnostic testing'
        ],
      },
      {
        'title': 'Common Diseases',
        'description': 'Protect against rabies, distemper, parvovirus with timely vaccinations. Use heartworm preventatives monthly.',
        'icon': Icons.warning,
        'color': Colors.redAccent,
        'details': [
          'Rabies: Prevent with annual vaccination',
          'Distemper: Core vaccine for dogs',
          'Parvovirus: Highly contagious, vaccinate puppies',
          'Heartworm: Monthly preventatives essential',
          'Flea-borne diseases: Regular flea control',
          'Early detection through regular vet visits'
        ],
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pet Care Tips',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Learn how to keep your pets healthy and happy',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TipDetailsPage(
                        title: tip['title'].toString(),
                        icon: tip['icon'] as IconData,
                        color: tip['color'] as Color,
                        description: tip['description'].toString(),
                        details: tip['details'] as List<String>,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (tip['color'] as Color).withOpacity(0.7),
                          (tip['color'] as Color).withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tip['icon'] as IconData,
                            size: 36,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tip['title'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tip['description'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
