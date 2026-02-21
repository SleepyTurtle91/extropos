import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/role_service.dart';
import 'package:flutter/material.dart';

/// Dialog for adding a new custom role
///
/// Features:
/// - Role name input with validation
/// - Base permissions selection
/// - Cannot create system roles
class AddRoleDialog extends StatefulWidget {
  const AddRoleDialog({super.key});

  @override
  State<AddRoleDialog> createState() => _AddRoleDialogState();
}

class _AddRoleDialogState extends State<AddRoleDialog> {
  late RoleService _roleService;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roleService = RoleService.instance;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Role name is required';
    }
    if (value.length < 2) {
      return 'Role name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Role name must be at most 50 characters';
    }
    return null;
  }

  Future<void> _createRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create new role with empty permissions (to be configured later)
      final role = RoleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        permissions: {}, // Empty permissions - user will configure
        isSystemRole: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _roleService.createRole(role);

      if (mounted) {
        print('✅ Role ${role.name} created successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('❌ Error creating role: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating role: $e')),
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
      title: const Text('Add New Role'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Role Name *',
                    hintText: 'e.g., Senior Manager',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '📝 Next Steps:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Create the role with this name\n'
                        '2. Select the role from the list\n'
                        '3. Configure permissions on the right panel',
                        style: TextStyle(fontSize: 12),
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
          onPressed: _isLoading ? null : _createRole,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Role'),
        ),
      ],
    );
  }
}
