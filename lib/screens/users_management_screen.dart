import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'users_management_screen_ui.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<User> users = [];
  bool _isLoading = true;

  UserRole? _filterRole;
  UserStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return _buildUsersManagementScreen(context);
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final currentContext = context; // Capture context before async
    try {
      final loadedUsers = await DatabaseService.instance.getUsers();
      setState(() {
        users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastHelper.showToast(currentContext, 'Failed to load users: $e');
      }
    }
  }

  List<User> get filteredUsers {
    return users.where((user) {
      if (_filterRole != null && user.role != _filterRole) return false;
      if (_filterStatus != null && user.status != _filterStatus) return false;
      return true;
    }).toList();
  }

  void _addUser() {
    final currentContext = context; // Capture context before async operation
    showDialog(
      context: currentContext,
      builder: (context) => _UserFormDialog(
        onSave: (user) async {
          try {
            await DatabaseService.instance.insertUser(user);
            _loadUsers(); // Reload users from database
            if (mounted) {
              Navigator.of(currentContext).pop(); // Close dialog
              ToastHelper.showToast(currentContext, 'User added successfully');
            }
          } catch (e) {
            if (mounted) {
              ToastHelper.showToast(currentContext, 'Failed to add user: $e');
            }
          }
        },
      ),
    );
  }

  void _editUser(User user) {
    final currentContext = context; // Capture context before async operation
    showDialog(
      context: currentContext,
      builder: (context) => _UserFormDialog(
        user: user,
        onSave: (updatedUser) async {
          try {
            await DatabaseService.instance.updateUser(updatedUser);
            _loadUsers(); // Reload users from database
            if (mounted) {
              Navigator.of(currentContext).pop(); // Close dialog
              ToastHelper.showToast(
                currentContext,
                'User updated successfully',
              );
            }
          } catch (e) {
            if (mounted) {
              ToastHelper.showToast(
                currentContext,
                'Failed to update user: $e',
              );
            }
          }
        },
      ),
    );
  }

  void _deleteUser(User user) {
    final currentContext = context; // Capture context before async operation
    if (user.role == UserRole.admin) {
      ToastHelper.showToast(currentContext, 'Cannot delete admin user');
      return;
    }

    // Prevent deletion of the first admin user
    if (user.id == 'first-admin-system') {
      ToastHelper.showToast(
        currentContext,
        'Cannot delete the system administrator',
      );
      return;
    }

    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteUser(user.id);
                _loadUsers(); // Reload users from database
                if (mounted) {
                  Navigator.pop(currentContext); // Close confirmation dialog
                  ToastHelper.showToast(
                    currentContext,
                    'User deleted successfully',
                  );
                }
              } catch (e) {
                if (mounted) {
                  ToastHelper.showToast(
                    currentContext,
                    'Failed to delete user: $e',
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(User user) async {
    final currentContext = context; // capture context for async
    try {
      final updatedUser = user.copyWith(
        status: user.status == UserStatus.active
            ? UserStatus.inactive
            : UserStatus.active,
      );
      await DatabaseService.instance.updateUser(updatedUser);
      _loadUsers(); // Reload users from database
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(
          currentContext,
          'Failed to update user status: $e',
        );
      }
    }
  }
}

class _UserFormDialog extends StatefulWidget {
  final User? user;
  final Function(User) onSave;

  const _UserFormDialog({this.user, required this.onSave});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _pinController;
  late UserRole _selectedRole;
  late UserStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );
    _fullNameController = TextEditingController(
      text: widget.user?.fullName ?? '',
    );
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(
      text: widget.user?.phoneNumber ?? '',
    );
    _pinController = TextEditingController(text: widget.user?.pin ?? '');
    _selectedRole = widget.user?.role ?? UserRole.cashier;
    _selectedStatus = widget.user?.status ?? UserStatus.active;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _save() {
    if (_usernameController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _pinController.text.isEmpty) {
      ToastHelper.showToast(context, 'Please fill all required fields');
      return;
    }

    if (_pinController.text.length != 4) {
      ToastHelper.showToast(context, 'PIN must be 4 digits');
      return;
    }

    final user = User(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      username: _usernameController.text,
      fullName: _fullNameController.text,
      email: _emailController.text,
      role: _selectedRole,
      pin: _pinController.text,
      status: _selectedStatus,
      phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
      lastLoginAt: widget.user?.lastLoginAt,
      createdAt: widget.user?.createdAt,
    );

    widget.onSave(user);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  hintText: '+60123456789',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN (4 digits) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                ),
                items: UserStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
