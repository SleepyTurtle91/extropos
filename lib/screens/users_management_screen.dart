import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Users Management'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _filterRole = null;
                  _filterStatus = null;
                } else if (value.startsWith('role_')) {
                  final role = value.split('_')[1];
                  _filterRole = UserRole.values.firstWhere(
                    (r) => r.name == role,
                  );
                } else if (value.startsWith('status_')) {
                  final status = value.split('_')[1];
                  _filterStatus = UserStatus.values.firstWhere(
                    (s) => s.name == status,
                  );
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Users')),
              const PopupMenuDivider(),
              ...UserRole.values.map(
                (role) => PopupMenuItem(
                  value: 'role_${role.name}',
                  child: Text(role.name.toUpperCase()),
                ),
              ),
              const PopupMenuDivider(),
              ...UserStatus.values.map(
                (status) => PopupMenuItem(
                  value: 'status_${status.name}',
                  child: Text(status.name.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filterRole != null || _filterStatus != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Text('Filters: '),
                  if (_filterRole != null) ...[
                    Chip(
                      label: Text(_filterRole!.name.toUpperCase()),
                      onDeleted: () => setState(() => _filterRole = null),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_filterStatus != null) ...[
                    Chip(
                      label: Text(_filterStatus!.name.toUpperCase()),
                      onDeleted: () => setState(() => _filterStatus = null),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(
                        user.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.role.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('@${user.username}'),
                        Text(user.email),
                        if (user.phoneNumber != null) Text(user.phoneNumber!),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.status == UserStatus.active
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(user.statusDisplayName),
                            if (user.lastLoginAt != null) ...[
                              const Text(' • Last login: '),
                              Text(_formatLastLogin(user.lastLoginAt!)),
                            ],
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editUser(user);
                            break;
                          case 'toggle_status':
                            _toggleStatus(user);
                            break;
                          case 'delete':
                            _deleteUser(user);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(
                                user.status == UserStatus.active
                                    ? Icons.block
                                    : Icons.check_circle,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.status == UserStatus.active
                                    ? 'Deactivate'
                                    : 'Activate',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.purple;
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.orange;
      case UserRole.supervisor:
        return Colors.amber;
      case UserRole.cashier:
        return Colors.blue;
      case UserRole.waiter:
        return Colors.green;
    }
  }

  String _formatLastLogin(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
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
