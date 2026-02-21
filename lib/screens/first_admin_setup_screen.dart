import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FirstAdminSetupScreen extends StatefulWidget {
  const FirstAdminSetupScreen({super.key});

  @override
  State<FirstAdminSetupScreen> createState() => _FirstAdminSetupScreenState();
}

class _FirstAdminSetupScreenState extends State<FirstAdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _createFirstAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create the first admin user with special ID
      final firstAdmin = User(
        id: 'first-admin-system', // Special ID to identify the first admin
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        role: UserRole.admin,
        pin: _pinController.text.trim(),
      );

      // Save to database
      await DatabaseService.instance.insertUser(firstAdmin);

      // Set admin PIN for system access
      await PinStore.instance.setAdminPin(_pinController.text.trim());

      if (!mounted) return;
      // Show success and navigate back to lock screen
      ToastHelper.showToast(context, 'First admin user created successfully!');
      Navigator.of(context).pop(); // Back to lock screen
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Failed to create admin user: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Admin Setup'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create First Administrator',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will be the system administrator with full access. This user cannot be deleted.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email (Optional)
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // PIN
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'PIN is required';
                      }
                      if (value.trim().length < 4) {
                        return 'PIN must be at least 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm PIN
                  TextFormField(
                    controller: _confirmPinController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != _pinController.text) {
                        return 'PINs do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Create Admin Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createFirstAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Administrator',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Note: This PIN will also be used as the system admin PIN for emergency access.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
