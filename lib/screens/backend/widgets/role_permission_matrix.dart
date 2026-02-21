import 'package:extropos/models/role_model.dart';
import 'package:flutter/material.dart';

/// Widget for displaying and editing role permissions as a matrix
///
/// Features:
/// - Shows all 20+ permissions grouped by category
/// - Checkboxes for grant/revoke
/// - Color-coded by permission type
/// - Real-time updates
typedef PermissionsChangedCallback = Function(Map<String, bool> permissions);

class RolePermissionMatrix extends StatefulWidget {
  final RoleModel role;
  final PermissionsChangedCallback onPermissionsChanged;
  final bool readOnly;

  const RolePermissionMatrix({
    super.key,
    required this.role,
    required this.onPermissionsChanged,
    this.readOnly = false,
  });

  @override
  State<RolePermissionMatrix> createState() => _RolePermissionMatrixState();
}

class _RolePermissionMatrixState extends State<RolePermissionMatrix> {
  late Map<String, bool> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = Map.from(widget.role.permissions);
  }

  void _onPermissionChanged(String permission, bool value) {
    setState(() {
      _permissions[permission] = value;
    });
    widget.onPermissionsChanged(_permissions);
  }

  List<_PermissionCategory> _getPermissionsByCategory() {
    final categories = <String, List<String>>{};

    // Group permissions by category prefix
    for (final permission in _permissions.keys) {
      final parts = permission.split('_');
      final category = parts.isNotEmpty ? parts[0] : 'OTHER';
      categories.putIfAbsent(category, () => []).add(permission);
    }

    // Sort permissions within each category
    for (final list in categories.values) {
      list.sort();
    }

    return categories.entries.map((entry) {
      return _PermissionCategory(
        name: _getCategoryLabel(entry.key),
        color: _getCategoryColor(entry.key),
        permissions: entry.value,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'VIEW':
        return '👁️ View';
      case 'CREATE':
        return '➕ Create';
      case 'EDIT':
        return '✏️ Edit';
      case 'DELETE':
        return '🗑️ Delete';
      case 'MANAGE':
        return '⚙️ Manage';
      case 'LOCK':
        return '🔒 Lock/Unlock';
      case 'EXPORT':
        return '📤 Export';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'VIEW':
        return Colors.blue;
      case 'CREATE':
        return Colors.green;
      case 'EDIT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'MANAGE':
        return Colors.purple;
      case 'LOCK':
        return Colors.red;
      case 'EXPORT':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getPermissionLabel(String permission) {
    // Convert MANAGE_USERS to "Users"
    final parts = permission.split('_');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ').toUpperCase();
    }
    return permission;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getPermissionsByCategory();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Enabled: ${_permissions.values.where((v) => v).length} / ${_permissions.length}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Permission categories
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        color: category.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${category.permissions.where((p) => _permissions[p] ?? false).length}/${category.permissions.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Permissions grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 3,
                    ),
                    itemCount: category.permissions.length,
                    itemBuilder: (context, index) {
                      final permission = category.permissions[index];
                      final enabled = _permissions[permission] ?? false;

                      return Card(
                        elevation: 0,
                        color: enabled ? category.color.withOpacity(0.1) : Colors.transparent,
                        child: CheckboxListTile(
                          value: enabled,
                          onChanged: widget.readOnly
                              ? null
                              : (value) {
                                  _onPermissionChanged(
                                    permission,
                                    value ?? false,
                                  );
                                },
                          title: Text(
                            _getPermissionLabel(permission),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: enabled ? FontWeight.bold : FontWeight.normal,
                              color: enabled ? category.color : Colors.grey,
                            ),
                          ),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _PermissionCategory {
  final String name;
  final Color color;
  final List<String> permissions;

  _PermissionCategory({
    required this.name,
    required this.color,
    required this.permissions,
  });
}
