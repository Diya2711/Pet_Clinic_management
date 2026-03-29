import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'admin_page.dart';
import 'screens/user_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLogin = true; // Toggle between login and register views
  bool _obscurePassword = true;
  bool _adminExists = false;
  bool _isAdminMode = true; // Choose between admin/user login mode

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfAdminExists();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAdminExists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _firebaseService.adminExists();
      if (!mounted) return;
      setState(() {
        _adminExists = result;
        _isLogin =
            result; // If admin exists, show login, otherwise show registration
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking admin existence: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final admin = await _firebaseService.loginAdmin(
            _usernameController.text, _passwordController.text);

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        // Navigate to admin dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminPage()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${admin.username}!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final admin = await _firebaseService.registerAdmin(
            _usernameController.text,
            _passwordController.text,
            _emailController.text);

        setState(() {
          _isLoading = false;
          _adminExists = true;
          _isLogin = true; // Switch to login view after successful registration
        });

        if (!mounted) return;

        // Navigate to admin dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminPage()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Welcome, ${admin.username}! Your account has been created.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Title
                      Icon(
                        Icons.pets,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pet Clinic Login',
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 28,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category toggles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Admin'),
                            selected: _isAdminMode,
                            onSelected: (selected) {
                              setState(() {
                                _isAdminMode = true;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('User'),
                            selected: !_isAdminMode,
                            onSelected: (selected) {
                              setState(() {
                                _isAdminMode = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (!_isAdminMode) ...[
                        Text(
                          'User login selected. Tap below to sign in as a user.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UserLoginPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Go to User Login',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_isAdminMode) ...[
                        Text(
                          _isLogin
                              ? 'Login to access the admin dashboard'
                              : 'Create a new admin account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Username field
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  if (value.length < 4) {
                                    return 'Username must be at least 4 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email field (only for registration)
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (!_isLogin && value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLogin ? _login : _register,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _isLogin ? 'Login' : 'Register',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),

                              // Toggle login/register
                              if (_adminExists) ...[
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _formKey.currentState?.reset();
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? 'Need a new admin account? Register here'
                                        : 'Already have an account? Login here',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
