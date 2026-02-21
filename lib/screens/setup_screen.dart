import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPinCtrl = TextEditingController();
  bool _saving = false;
  BusinessMode _selectedBusinessMode = BusinessMode.retail;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    // Capture navigator early to avoid using BuildContext across async gaps.
    final currentContext = context; // capture for toasts
    final navigator = Navigator.of(currentContext);

    setState(() => _saving = true);

    try {
      // Save store name to SharedPreferences
      await ConfigService.instance.setStoreName(_storeNameCtrl.text.trim());

      // Update business_info table in database
      final db = await DatabaseHelper.instance.database;

      // Always update the business info (there should be default data with id='1')
      await db.update(
        'business_info',
        {
          'name': _storeNameCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: ['1'],
      );

      // Save selected business mode
      await BusinessInfo.updateInstance(
        BusinessInfo.instance.copyWith(
          businessName: _storeNameCtrl.text.trim(),
          selectedBusinessMode: _selectedBusinessMode,
        ),
      );

      await ConfigService.instance.setSetupDone(true);

      // Replace the default admin user with the new one
      final String pin = _adminPinCtrl.text.trim();
      final String newAdminId = const Uuid().v4();

      // Delete the default admin user (id='1')
      await db.delete('users', where: 'id = ?', whereArgs: ['1']);

      // Create new admin user with the provided details
      final user = User(
        id: newAdminId,
        username: _adminNameCtrl.text.trim().replaceAll(' ', '_').toLowerCase(),
        fullName: _adminNameCtrl.text.trim(),
        email: _adminEmailCtrl.text.trim(),
        role: UserRole.admin,
        pin: pin,
      );

      await DatabaseService.instance.insertUser(user);

      // Save admin PIN securely
      try {
        await PinStore.instance.setAdminPin(pin);
      } catch (e) {
        debugPrint('Failed to save admin PIN: $e');
      }

      setState(() => _saving = false);

      // Show success message
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Setup completed successfully!');

      // Ensure widget is still mounted before navigating
      if (!mounted) return;

      // Navigate to home
      navigator.pushReplacementNamed('/');
    } catch (e, stackTrace) {
      setState(() => _saving = false);

      // Show error message
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Setup failed: $e');

      debugPrint('Setup error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Widget _buildBusinessModeOption(
    BusinessMode mode,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedBusinessMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBusinessMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color.fromRGBO(37, 99, 235, 0.1)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome — Setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Let\'s get your store ready',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _storeNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Store name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter store name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Business Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select your business mode:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    _buildBusinessModeOption(
                      BusinessMode.retail,
                      'Retail Mode',
                      'Product code search for direct sales',
                      Icons.shopping_bag,
                    ),
                    const SizedBox(height: 12),
                    _buildBusinessModeOption(
                      BusinessMode.cafe,
                      'Cafe Mode',
                      'Calling number system for takeaway orders',
                      Icons.local_cafe,
                    ),
                    const SizedBox(height: 12),
                    _buildBusinessModeOption(
                      BusinessMode.restaurant,
                      'Restaurant Mode',
                      'Table management for dine-in service',
                      Icons.restaurant,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Administrator account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _adminNameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter admin name'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _adminEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _adminPinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Admin PIN (4 digits)',
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a PIN';
                        }
                        if (v.trim().length < 3) {
                          return 'PIN must be at least 3 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saving ? null : _completeSetup,
                      child: _saving
                          ? const CircularProgressIndicator.adaptive()
                          : const Text('Complete setup'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              // Skip setup: mark as done and go to home
                              final navigator = Navigator.of(context);
                              await ConfigService.instance.setSetupDone(true);
                              if (!mounted) return;
                              navigator.pushReplacementNamed('/');
                            },
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
