import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/backend_user_service.dart';
import 'package:flutter/material.dart';

/// Dialog for editing an existing user
///
/// Features:
/// - Edit display name, phone, role, locations
/// - Cannot change email (immutable)
/// - Can toggle isActive status
/// - Form validation
/// - Auto-logs changes to audit service
class EditUserDialog extends StatefulWidget {
  final BackendUserModel user;

  const EditUserDialog({
    super.key,
    required this.user,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late BackendUserService _userService;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  late String _selectedRoleId;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userService = BackendUserService.instance;
    _nameController = TextEditingController(text: widget.user.displayName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedRoleId = widget.user.roleId;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated user
      final updatedUser = widget.user.copyWith(
        displayName: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        roleId: _selectedRoleId,
        isActive: _isActive,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        updatedBy: 'system',
      );

      await _userService.updateUser(updatedUser);

      if (mounted) {
        print('✅ User ${updatedUser.displayName} updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('❌ Error updating user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
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
      title: const Text('Edit User'),
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
                // Email (read-only)
                TextFormField(
                  initialValue: widget.user.email,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email (Cannot Change)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                // Display Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Display Name *',
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
                const SizedBox(height: 16),
                // Active Status Toggle
                Row(
                  children: [
                    Expanded(
                      child: const Text('Active Status'),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                    ),
                  ],
                ),
                if (!_isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⚠️ Inactive users cannot log in',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
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
          onPressed: _isLoading ? null : _updateUser,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update User'),
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
