import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/backend_user_service.dart';
import 'package:flutter/material.dart';

/// Dialog for adding a new user
///
/// Features:
/// - Email validation and uniqueness check
/// - Display name, phone, role selection
/// - Multi-location selection
/// - Form validation
/// - Auto-logs to audit service
class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  late BackendUserService _userService;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRoleId = '';
  final List<String> _selectedLocationIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userService = BackendUserService.instance;
    // Set default role to first available
    if (PredefinedRoles.allRoles.isNotEmpty) {
      _selectedRoleId = PredefinedRoles.allRoles.first.id;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Basic email validation
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email already exists
      final existingUser = await _userService.getUserByEmail(
        _emailController.text.toLowerCase(),
      );
      if (existingUser != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Email already exists')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user
      final user = BackendUserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: _emailController.text.toLowerCase(),
        displayName: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        roleId: _selectedRoleId,
        locationIds: _selectedLocationIds,
        isActive: true,
        isLocked: false,
        failedLoginAttempts: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdBy: 'system',
        updatedBy: 'system',
      );

      await _userService.createUser(user);

      if (mounted) {
        print('✅ User ${user.displayName} created successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('❌ Error creating user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'user@example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                // Display Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Display Name *',
                    hintText: 'John Doe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                // Phone
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Phone (Optional)',
                    hintText: '+60123456789',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Role Selection
                DropdownButtonFormField<String>(
                  value: _selectedRoleId,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRoleId = value;
                      });
                    }
                  },
                  items: PredefinedRoles.allRoles.map((role) {
                    return DropdownMenuItem(
                      value: role.id,
                      child: Text(role.name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Role Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 Selected Role Permissions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._getSelectedRolePermissions().take(3).map((perm) {
                        return Text('• $perm', style: const TextStyle(fontSize: 12));
                      }).toList(),
                      if (_getSelectedRolePermissions().length > 3)
                        Text(
                          '• +${_getSelectedRolePermissions().length - 3} more',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create User'),
        ),
      ],
    );
  }

  List<String> _getSelectedRolePermissions() {
    for (final role in PredefinedRoles.allRoles) {
      if (role.id == _selectedRoleId) {
        return role.permissions.keys.toList();
      }
    }
    return [];
  }
}
