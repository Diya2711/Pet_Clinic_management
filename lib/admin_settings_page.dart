import 'package:flutter/material.dart';
import 'models/admin_settings.dart';
import 'services/firebase_service.dart';
import 'services/email_service.dart';
import 'login_page.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({Key? key}) : super(key: key);

  @override
  _AdminSettingsPageState createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final EmailService _emailService = EmailService();
  bool _isLoading = true;
  bool _isSendingTest = false;
  bool _obscurePassword = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _smsApiKeyController = TextEditingController();
  final TextEditingController _smsFromController = TextEditingController();
  final TextEditingController _testEmailController = TextEditingController();

  String _settingsId = 'admin_email_settings';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _smsApiKeyController.dispose();
    _smsFromController.dispose();
    _testEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _firebaseService.getAdminSettings();

      _settingsId = settings.id;
      _emailController.text = settings.emailUsername;
      _passwordController.text = settings.emailPassword;
      _displayNameController.text = settings.emailDisplayName;
      _smsApiKeyController.text = settings.smsApiKey;
      _smsFromController.text = settings.smsFrom;

      setState(() {
        _emailEnabled = settings.emailEnabled;
        _smsEnabled = settings.smsEnabled;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final settings = AdminSettings(
          id: _settingsId,
          emailUsername: _emailController.text,
          emailPassword: _passwordController.text,
          emailDisplayName: _displayNameController.text,
          smsApiKey: _smsApiKeyController.text,
          smsFrom: _smsFromController.text,
          emailEnabled: _emailEnabled,
          smsEnabled: _smsEnabled,
        );

        await _firebaseService.updateAdminSettings(settings);

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving settings: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Send a test email to verify configuration
  Future<void> _sendTestEmail() async {
    if (_testEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a test email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingTest = true;
    });

    try {
      final success =
          await _emailService.testEmailConfiguration(_testEmailController.text);

      setState(() {
        _isSendingTest = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test email sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to send test email. Check your configuration.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSendingTest = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Settings',
          style: TextStyle(
            fontFamily: 'Pacifico',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
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
                              Icon(Icons.notifications_active,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Notification Settings',
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
                            'Configure your email and SMS settings for client notifications.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Settings
                    const Text(
                      'Email Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Enable Email Notifications'),
                      subtitle:
                          const Text('Send emails to clients for appointments'),
                      value: _emailEnabled,
                      onChanged: (value) {
                        setState(() {
                          _emailEnabled = value;
                        });
                      },
                      activeColor: Colors.blue,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: _emailEnabled,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'your-email@gmail.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailEnabled
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email address';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            }
                          : null,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: _emailEnabled,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Email Password / App Password',
                        hintText: 'For Gmail, use an app password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      validator: _emailEnabled
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              return null;
                            }
                          : null,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      enabled: _emailEnabled,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Pet Clinic',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: _emailEnabled
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a display name';
                              }
                              return null;
                            }
                          : null,
                    ),

                    const SizedBox(height: 24),

                    // SMS Settings
                    const Text(
                      'SMS Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Enable SMS Notifications'),
                      subtitle: const Text(
                          'Send text messages to clients for appointments'),
                      value: _smsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _smsEnabled = value;
                        });
                      },
                      activeColor: Colors.blue,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _smsApiKeyController,
                      enabled: _smsEnabled,
                      decoration: InputDecoration(
                        labelText: 'SMS API Key',
                        hintText: 'From your SMS provider',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.key),
                      ),
                      validator: _smsEnabled
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an API key';
                              }
                              return null;
                            }
                          : null,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _smsFromController,
                      enabled: _smsEnabled,
                      decoration: InputDecoration(
                        labelText: 'SMS From Name/Number',
                        hintText: 'PetClinic or your phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.message),
                      ),
                      validator: _smsEnabled
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a sender name or number';
                              }
                              return null;
                            }
                          : null,
                    ),

                    const SizedBox(height: 24),

                    // Test Email Section
                    const Text(
                      'Test Email Configuration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _testEmailController,
                            enabled: _emailEnabled,
                            decoration: InputDecoration(
                              labelText: 'Test Email Address',
                              hintText: 'test@example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.alternate_email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _emailEnabled && !_isSendingTest
                              ? _sendTestEmail
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSendingTest
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Send Test Email'),
                        ),
                      ],
                    ),

                    if (_emailEnabled)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Save your settings before sending a test email',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Save Settings',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
