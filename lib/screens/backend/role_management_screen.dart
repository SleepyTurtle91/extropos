import 'package:extropos/models/role_model.dart';
import 'package:extropos/screens/backend/dialogs/add_role_dialog.dart';
import 'package:extropos/screens/backend/dialogs/edit_role_dialog.dart';
import 'package:extropos/screens/backend/widgets/role_permission_matrix.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:extropos/services/role_service.dart';
import 'package:flutter/material.dart';

/// Role Management Screen for Backend Flavor
///
/// Provides complete role lifecycle management with permission matrix editing.
/// System roles (Admin, Manager, Supervisor, Viewer) are protected from deletion.
///
/// Permission Requirements:
/// - VIEW_ROLES (to see list)
/// - CREATE_ROLES (to add)
/// - EDIT_ROLES (to edit)
/// - DELETE_ROLES (to delete - system roles protected)
class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() =>
      _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  late RoleService _roleService;
  late AccessControlService _accessControl;

  List<RoleModel> _allRoles = [];
  List<RoleModel> _filteredRoles = [];

  String _searchQuery = '';
  bool _showSystemRoles = true;
  bool _showCustomRoles = true;

  bool _isLoading = false;
  String? _errorMessage;

  RoleModel? _selectedRoleForPermissions;

  @override
  void initState() {
    super.initState();
    _roleService = RoleService.instance;
    _accessControl = AccessControlService.instance;

    // Listen for role changes
    _roleService.addListener(_onRolesChanged);

    // Load initial data
    _loadRoles();
  }

  @override
  void dispose() {
    _roleService.removeListener(_onRolesChanged);
    super.dispose();
  }

  void _onRolesChanged() {
    if (mounted) {
      _loadRoles();
    }
  }

  Future<void> _loadRoles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final roles = await _roleService.getAllRoles();
      setState(() {
        _allRoles = roles;
        _applyFilters();
      });
    } catch (e) {
      print('❌ Error loading roles: $e');
      setState(() {
        _errorMessage = 'Failed to load roles: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<RoleModel> filtered = _allRoles;

    // System role filter
    if (_showSystemRoles && !_showCustomRoles) {
      filtered = filtered.where((role) => role.isSystemRole).toList();
    } else if (!_showSystemRoles && _showCustomRoles) {
      filtered = filtered.where((role) => !role.isSystemRole).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((role) => role.name.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredRoles = filtered;
      _selectedRoleForPermissions = null;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  void _onSystemRolesToggle(bool value) {
    setState(() {
      _showSystemRoles = value;
    });
    _applyFilters();
  }

  void _onCustomRolesToggle(bool value) {
    setState(() {
      _showCustomRoles = value;
    });
    _applyFilters();
  }

  Future<void> _showAddRoleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddRoleDialog(),
    );

    if (result == true) {
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Role created successfully')),
        );
      }
    }
  }

  Future<void> _showEditRoleDialog(RoleModel role) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditRoleDialog(role: role),
    );

    if (result == true) {
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Role updated successfully')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete ${role.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRole(role);
    }
  }

  Future<void> _deleteRole(RoleModel role) async {
    try {
      await _roleService.deleteRole(role.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Role deleted successfully')),
        );
        await _loadRoles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error deleting role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left: Role List
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Statistics Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        title: 'Total',
                        value: _allRoles.length.toString(),
                        icon: Icons.vpn_key,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'System',
                        value: _allRoles
                            .where((r) => r.isSystemRole)
                            .length
                            .toString(),
                        icon: Icons.lock,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                // Search & Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search roles...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Role type filters
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              value: _showSystemRoles,
                              onChanged: (value) =>
                                  _onSystemRolesToggle(value ?? true),
                              title: const Text('System', style: TextStyle(fontSize: 12)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              value: _showCustomRoles,
                              onChanged: (value) =>
                                  _onCustomRolesToggle(value ?? true),
                              title: const Text('Custom', style: TextStyle(fontSize: 12)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Role List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_errorMessage!),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadRoles,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredRoles.isEmpty
                              ? const Center(child: Text('No roles found'))
                              : ListView.builder(
                                  itemCount: _filteredRoles.length,
                                  itemBuilder: (context, index) {
                                    final role = _filteredRoles[index];
                                    final isSelected =
                                        _selectedRoleForPermissions?.id == role.id;

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        selected: isSelected,
                                        title: Text(role.name),
                                        subtitle: Text(
                                          '${role.permissions.length} permissions',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        leading: Icon(
                                          role.isSystemRole
                                              ? Icons.lock
                                              : Icons.vpn_key,
                                          color: role.isSystemRole
                                              ? Colors.purple
                                              : Colors.blue,
                                        ),
                                        trailing: SizedBox(
                                          width: 100,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 18),
                                                tooltip: 'Edit',
                                                onPressed: () =>
                                                    _showEditRoleDialog(role),
                                              ),
                                              if (!role.isSystemRole)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip: 'Delete',
                                                  onPressed: () =>
                                                      _showDeleteConfirmation(
                                                        role,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedRoleForPermissions = role;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
          // Right: Permission Matrix (if role selected)
          if (_selectedRoleForPermissions != null)
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Permissions for "${_selectedRoleForPermissions!.name}"',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedRoleForPermissions = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RolePermissionMatrix(
                        role: _selectedRoleForPermissions!,
                        onPermissionsChanged: (permissions) async {
                          try {
                            await _roleService.updateRolePermissions(
                              _selectedRoleForPermissions!.id,
                              permissions,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✅ Permissions updated successfully'),
                                ),
                              );
                              await _loadRoles();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _accessControl.hasPermission(Permission.CREATE_ROLES),
        builder: (context, snapshot) {
          final canCreate = snapshot.data ?? false;
          if (!canCreate) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: _showAddRoleDialog,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
