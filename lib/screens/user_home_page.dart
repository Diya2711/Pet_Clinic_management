import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../services/user_auth_service.dart';
import '../services/pet_service.dart';
import 'user_login_page.dart';
import 'pet_details_page.dart';
import 'add_pet_page.dart';

class UserHomePage extends StatefulWidget {
  final User user;

  const UserHomePage({Key? key, required this.user}) : super(key: key);

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _userAuthService = UserAuthService();
  final _petService = PetService();
  bool _isLoading = false;
  List<Pet> _pets = [];

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

      // Navigate to login page
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
      // Reload pets if a new pet was added
      _loadPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.user.fullName}'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _signOut,
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
                  // User Profile Card
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
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  Icons.person,
                                  size: 30,
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
                                        fontSize: 20,
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pets Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Pets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _navigateToAddPet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Pet'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pets List
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: pet.photoUrl != null
                                  ? NetworkImage(pet.photoUrl!)
                                  : null,
                              child: pet.photoUrl == null
                                  ? Icon(
                                      Icons.pets,
                                      color: Colors.blue.shade800,
                                    )
                                  : null,
                            ),
                            title: Text(pet.name),
                            subtitle: Text('${pet.type} • ${pet.breed}'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PetDetailsPage(
                                    petId: pet.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Appointments Section
                  const Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TODO: Add appointments list
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming appointments',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to book appointment page
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Book an Appointment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
