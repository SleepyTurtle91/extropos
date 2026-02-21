import 'package:extropos/models/user_model.dart';
import 'package:flutter/material.dart';

class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Roles & Permissions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure what each role can and cannot do in the POS system.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Role selector
            const Text(
              'Select Role to View Permissions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: UserRole.values.map((role) {
                final isSelected = _selectedRole == role;
                return FilterChip(
                  label: Text(_getRoleDisplayName(role)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? role : null;
                    });
                  },
                  backgroundColor: isSelected
                      ? const Color.fromRGBO(37, 99, 235, 0.1)
                      : null,
                  selectedColor: const Color.fromRGBO(37, 99, 235, 0.2),
                  checkmarkColor: const Color(0xFF2563EB),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (_selectedRole != null) ...[
              // Role permissions display
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getRoleIcon(_selectedRole!),
                            color: _getRoleColor(_selectedRole!),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getRoleDisplayName(_selectedRole!),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getRoleDescription(_selectedRole!),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Permissions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildPermissionsList(_selectedRole!),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Show all roles overview
              const Text(
                'Role Overview:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...UserRole.values.map(
                (role) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      _getRoleIcon(role),
                      color: _getRoleColor(role),
                    ),
                    title: Text(_getRoleDisplayName(role)),
                    subtitle: Text(_getRoleDescription(role)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        _selectedRole = role;
                      });
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPermissionsList(UserRole role) {
    final permissions = RolePermissions.getPermissionsForRole(role);
    final permissionDefinitions = RolePermissions.getPermissionDefinitions();

    return permissionDefinitions.map((perm) {
      final key = perm['key'] as String;
      final title = perm['title'] as String;
      final description = perm['description'] as String;

      bool hasPermission = false;
      switch (key) {
        case 'canAccessPOS':
          hasPermission = permissions.canAccessPOS;
          break;
        case 'canManageUsers':
          hasPermission = permissions.canManageUsers;
          break;
        case 'canManageItems':
          hasPermission = permissions.canManageItems;
          break;
        case 'canManageTables':
          hasPermission = permissions.canManageTables;
          break;
        case 'canViewReports':
          hasPermission = permissions.canViewReports;
          break;
        case 'canManageBusinessSettings':
          hasPermission = permissions.canManageBusinessSettings;
          break;
        case 'canOpenCloseBusiness':
          hasPermission = permissions.canOpenCloseBusiness;
          break;
        case 'canProcessRefunds':
          hasPermission = permissions.canProcessRefunds;
          break;
        case 'canVoidItemsAfterPrinting':
          hasPermission = permissions.canVoidItemsAfterPrinting;
          break;
        case 'canManagePrinters':
          hasPermission = permissions.canManagePrinters;
          break;
        case 'canManagePaymentMethods':
          hasPermission = permissions.canManagePaymentMethods;
          break;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              hasPermission ? Icons.check_circle : Icons.cancel,
              color: hasPermission ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.waiter:
        return 'Waiter';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Full system access including super admin privileges';
      case UserRole.admin:
        return 'Full system access with all permissions';
      case UserRole.manager:
        return 'Can manage operations, close business, and view all reports';
      case UserRole.supervisor:
        return 'Can authorize transactions and manage operational issues';
      case UserRole.cashier:
        return 'Basic POS operations for processing sales';
      case UserRole.waiter:
        return 'Table service and order management';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.security;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.supervisor_account;
      case UserRole.supervisor:
        return Icons.badge;
      case UserRole.cashier:
        return Icons.point_of_sale;
      case UserRole.waiter:
        return Icons.room_service;
    }
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
}
