import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/role_service.dart';
import 'package:flutter/material.dart';

/// Dialog for editing an existing role
///
/// Features:
/// - Edit role name
/// - Cannot edit system roles
/// - Cannot change system role flag
class EditRoleDialog extends StatefulWidget {
  final RoleModel role;

  const EditRoleDialog({
    super.key,
    required this.role,
  });

  @override
  State<EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends State<EditRoleDialog> {
  late RoleService _roleService;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roleService = RoleService.instance;
    _nameController = TextEditingController(text: widget.role.name);
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

  Future<void> _updateRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated role
      final updatedRole = widget.role.copyWith(
        name: _nameController.text,
      );

      await _roleService.updateRole(updatedRole);

      if (mounted) {
        print('✅ Role ${updatedRole.name} updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('❌ Error updating role: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
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
      title: const Text('Edit Role'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System role indicator
                if (widget.role.isSystemRole)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.lock, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'System role - Limited editing',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.role.isSystemRole) const SizedBox(height: 16),
                // Role Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading && !widget.role.isSystemRole,
                  decoration: InputDecoration(
                    labelText: 'Role Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: widget.role.isSystemRole
                        ? 'System roles cannot be renamed'
                        : null,
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                // Role Type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.role.isSystemRole ? Icons.lock : Icons.vpn_key,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Role Type',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.role.isSystemRole ? 'System Role' : 'Custom Role',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
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
        if (!widget.role.isSystemRole)
          ElevatedButton(
            onPressed: _isLoading ? null : _updateRole,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update Role'),
          ),
      ],
    );
  }
}
