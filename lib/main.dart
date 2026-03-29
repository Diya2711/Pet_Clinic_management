import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'screens/user_login_page.dart';
import 'screens/user_dashboard.dart';
import 'screens/user_home_page.dart';
import 'appointment_page.dart';
import 'doctors_page.dart';
import 'admin_page.dart';
import 'login_page.dart';
import 'admin_settings_page.dart';
import 'login_page.dart';
import 'appointment_status_page.dart';
import 'service_details_page.dart';
import 'services/firebase_service.dart';
import 'services/user_auth_service.dart';
import 'models/user_model.dart';
import 'web_test_email.dart'; // Import the email test tool

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
  runApp(const PetClinicApp());
}

class PetClinicApp extends StatelessWidget {
  const PetClinicApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Clinic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // User is logged in
          return FutureBuilder<User?>(
            future: UserAuthService().getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Check if user data is available (even with error, keep user logged in if we had data)
              if (userSnapshot.hasData && userSnapshot.data != null) {
                return UserDashboard(user: userSnapshot.data!);
              }

              // If there's an error but we also don't have data, show dashboard anyway with cached data
              // This prevents logout on navigation back
              if (userSnapshot.hasError) {
                print('Error fetching user data: ${userSnapshot.error}');
                // Try to show dashboard even with error - user might still be cached
                return UserDashboard(
                  user: User(
                    id: snapshot.data!.uid,
                    email: snapshot.data!.email ?? '',
                    fullName: snapshot.data!.displayName ?? 'User',
                    phoneNumber: '',
                    createdAt: DateTime.now(),
                  ),
                );
              }

              // If user data is truly not found after no error, sign out
              auth.FirebaseAuth.instance.signOut();
              return const LoginPage();
            },
          );
        }

        // User is not logged in
        return const LoginPage();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pet Clinic',
          style: TextStyle(
            fontFamily: 'Pacifico',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'User Login',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UserLoginPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Check Appointment Status',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AppointmentStatusPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: 'Our Doctors',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DoctorsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Dashboard',
            onPressed: () {
              // Check if admin is logged in
              if (firebaseService.isAdminLoggedIn()) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Admin Settings',
            onPressed: () {
              // Check if admin is logged in
              if (firebaseService.isAdminLoggedIn()) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AdminSettingsPage()),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'Email Confirmation Tool',
            onPressed: () {
              // Check if admin is logged in
              if (firebaseService.isAdminLoggedIn()) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const EmailTestPage()),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pet Clinic',
                    style: TextStyle(
                      fontFamily: 'Pacifico',
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quality care for your beloved pets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Book Appointment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AppointmentPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Check Appointment Status'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AppointmentStatusPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Our Doctors'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DoctorsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Area'),
              onTap: () {
                Navigator.pop(context);
                if (firebaseService.isAdminLoggedIn()) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminPage()),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
            if (firebaseService.isAdminLoggedIn())
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Confirmation Tool'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const EmailTestPage()),
                  );
                },
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16.0),
              Container(
                margin: const EdgeInsets.only(bottom: 24.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Pet Clinic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Quality care for your beloved pets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AppointmentPage()),
                              );
                            },
                            icon: const Icon(Icons.add, color: Colors.blue),
                            label: const Text('Book Now',
                                style: TextStyle(color: Colors.blue)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AppointmentStatusPage()),
                              );
                            },
                            icon: const Icon(Icons.search, color: Colors.blue),
                            label: const Text('Check Status',
                                style: TextStyle(color: Colors.blue)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const DoctorsPage()),
                      );
                    },
                    child: const Row(
                      children: [
                        Text(
                          'Our Doctors',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ServiceGridView(),
              const SizedBox(height: 24.0),
              const Text(
                'Pet Types We Care For',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              const PetTypesList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AppointmentPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Book Appointment',
      ),
    );
  }
}

class ServiceGridView extends StatelessWidget {
  ServiceGridView({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> services = [
    {
      'title': 'Vaccination',
      'icon': Icons.medical_services,
      'color': Colors.blue,
      'description':
          'We provide comprehensive vaccination services for all pets, ensuring they are protected against common diseases. Our vaccination packages include core vaccines recommended for all pets and optional vaccines based on lifestyle and risk factors.',
      'details': [
        'Core vaccines: Rabies (₹500), Distemper (₹800), Parvovirus (₹700)',
        'Optional vaccines: Bordetella (₹600), Lyme (₹900)',
        'Puppy and kitten vaccination series',
        'Adult booster shots',
        'Vaccination certificates for travel',
        'Common diseases protection: Rabies, Distemper, Parvo, Hepatitis'
      ],
      'price': '₹1,800 - ₹5,500'
    },
    {
      'title': 'Surgery',
      'icon': Icons.healing,
      'color': Colors.red,
      'description':
          'Our skilled veterinary surgeons perform a wide range of surgical procedures with the utmost care and precision. We utilize modern equipment and advanced techniques to ensure the safety and comfort of your pet.',
      'details': [
        'Spay and neuter procedures',
        'Tumor and mass removals',
        'Orthopedic surgery',
        'Emergency surgery',
        'Post-operative care and pain management'
      ],
      'price': '₹12,000 - ₹65,000'
    },
    {
      'title': 'Dental Care',
      'icon': Icons.cleaning_services,
      'color': Colors.green,
      'description':
          'Dental health is essential for your pet\'s overall wellbeing. Our dental services include cleanings, extractions, and treatments for various dental diseases, helping to prevent pain and systemic health issues.',
      'details': [
        'Comprehensive dental examinations',
        'Teeth cleaning and polishing',
        'Tooth extractions',
        'Treatment for periodontal disease',
        'Home dental care guidance'
      ],
      'price': '₹6,500 - ₹24,000'
    },
    {
      'title': 'Grooming',
      'icon': Icons.pets,
      'color': Colors.orange,
      'description':
          'Our professional grooming services keep your pet looking and feeling their best. From basic baths to full styling, our groomers cater to each pet\'s specific needs while ensuring a positive, stress-free experience.',
      'details': [
        'Bathing and coat conditioning',
        'Haircuts and styling',
        'Nail trimming and filing',
        'Ear cleaning',
        'De-shedding treatments'
      ],
      'price': '₹2,500 - ₹8,000'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return ServiceCard(
          title: services[index]['title'],
          icon: services[index]['icon'],
          color: services[index]['color'],
          description: services[index]['description'],
          details: services[index]['details'],
          price: services[index]['price'],
        );
      },
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> details;
  final String price;

  const ServiceCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.details,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ServiceDetailsPage(
                title: title,
                icon: icon,
                color: color,
                description: description,
                details: details,
                price: price,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetTypesList extends StatefulWidget {
  const PetTypesList({Key? key}) : super(key: key);

  @override
  State<PetTypesList> createState() => _PetTypesListState();
}

class _PetTypesListState extends State<PetTypesList> {
  Map<String, int> _petTypeCounts = {};

  @override
  void initState() {
    super.initState();
    _loadPetTypeCounts();
  }

  Future<void> _loadPetTypeCounts() async {
    try {
      final statsDoc = await FirebaseFirestore.instance
          .collection('statistics')
          .doc('pet_types')
          .get();

      if (statsDoc.exists) {
        final data = statsDoc.data() as Map<String, dynamic>;
        setState(() {
          _petTypeCounts = Map<String, int>.from(data);
        });
      }
    } catch (e) {
      print('Error loading pet type counts: $e');
    }
  }

  final List<Map<String, dynamic>> petTypes = [
    {
      'name': 'Dogs',
      'icon': Icons.pets,
    },
    {
      'name': 'Cats',
      'icon': Icons.pets,
    },
    {
      'name': 'Birds',
      'icon': Icons.flutter_dash,
    },
    {
      'name': 'Rabbits',
      'icon': Icons.cruelty_free,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: petTypes.map((pet) {
        final count = _petTypeCounts[pet['name'].toLowerCase()] ?? 0;
        return PetTypeCard(
          name: pet['name'],
          count: count,
          icon: pet['icon'],
        );
      }).toList(),
    );
  }
}

class PetTypeCard extends StatelessWidget {
  final String name;
  final int count;
  final IconData icon;

  const PetTypeCard({
    Key? key,
    required this.name,
    required this.count,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),
        title: Text(name),
        subtitle: Text('$count pets'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Create a PetTypeDetailsPage for showing pets of a specific type
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Showing pets of type: $name'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
