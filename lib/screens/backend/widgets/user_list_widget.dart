import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:flutter/material.dart';

/// Reusable widget for displaying a list of users in table format
///
/// Features:
/// - Displays user email, name, role, status
/// - Shows last login time
/// - Action buttons (Edit, Delete, Lock/Unlock)
/// - Responsive design
typedef UserCallback = Function(BackendUserModel user);

class UserListWidget extends StatelessWidget {
  final List<BackendUserModel> users;
  final UserCallback onEdit;
  final UserCallback onDelete;
  final UserCallback onToggleLock;

  const UserListWidget({
    super.key,
    required this.users,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleLock,
  });

  String _getStatusLabel(BackendUserModel user) {
    if (user.isLocked) return 'Locked';
    return user.isActive ? 'Active' : 'Inactive';
  }

  Color _getStatusColor(BackendUserModel user) {
    if (user.isLocked) return Colors.red;
    return user.isActive ? Colors.green : Colors.grey;
  }

  String _formatLastLogin(int? timestamp) {
    if (timestamp == null) return 'Never';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Last Login')),
          DataColumn(label: Text('Actions')),
        ],
        rows: users.map((user) {
          final statusLabel = _getStatusLabel(user);
          final statusColor = _getStatusColor(user);
          final lastLogin = _formatLastLogin(user.lastLoginAt);
          final roleLabel = _getRoleLabel(user.roleId);

          return DataRow(
            cells: [
              DataCell(Text(user.email)),
              DataCell(Text(user.displayName)),
              DataCell(Text(user.phone ?? '-')),
              DataCell(Text(roleLabel)),
              DataCell(
                Chip(
                  label: Text(statusLabel),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ),
              DataCell(Text(lastLogin)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => onEdit(user),
                    ),
                    IconButton(
                      icon: Icon(
                        user.isLocked ? Icons.lock_open : Icons.lock,
                        size: 18,
                      ),
                      tooltip: user.isLocked ? 'Unlock' : 'Lock',
                      onPressed: () => onToggleLock(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => onDelete(user),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getRoleLabel(String roleId) {
    // Check predefined roles
    for (final role in PredefinedRoles.allRoles) {
      if (role.id == roleId) return role.name;
    }
    return roleId; // Fallback to ID if role not found
  }
}
