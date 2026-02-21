import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:extropos/screens/backend/dialogs/add_user_dialog.dart';
import 'package:extropos/screens/backend/dialogs/edit_user_dialog.dart';
import 'package:extropos/screens/backend/widgets/user_list_widget.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:extropos/services/backend_user_service.dart';
import 'package:flutter/material.dart';

/// User Management Screen for Backend Flavor
///
/// Provides complete user lifecycle management (CRUD operations, lockout/unlock, etc.)
/// with permission checks and audit trail integration.
///
/// Permission Requirements:
/// - VIEW_USERS (to see list)
/// - CREATE_USERS (to add)
/// - EDIT_USERS (to edit)
/// - DELETE_USERS (to delete)
/// - LOCK_USERS (to lock/unlock)
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late BackendUserService _userService;
  late AccessControlService _accessControl;

  List<BackendUserModel> _allUsers = [];
  List<BackendUserModel> _filteredUsers = [];

  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all' or roleId
  String _selectedStatusFilter = 'active'; // 'active', 'locked', 'all'

  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  static const int _pageSize = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _userService = BackendUserService.instance;
    _accessControl = AccessControlService.instance;

    // Listen for user changes
    _userService.addListener(_onUsersChanged);

    // Load initial data
    _loadUsers();
  }

  @override
  void dispose() {
    _userService.removeListener(_onUsersChanged);
    super.dispose();
  }

  void _onUsersChanged() {
    if (mounted) {
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
        _currentPage = 0;
      });
    } catch (e) {
      print('❌ Error loading users: $e');
      setState(() {
        _errorMessage = 'Failed to load users: $e';
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
    List<BackendUserModel> filtered = _allUsers;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((user) =>
              user.email.toLowerCase().contains(query) ||
              user.displayName.toLowerCase().contains(query) ||
              (user.phone?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Role filter
    if (_selectedRoleFilter != 'all') {
      filtered =
          filtered.where((user) => user.roleId == _selectedRoleFilter).toList();
    }

    // Status filter
    if (_selectedStatusFilter == 'active') {
      filtered = filtered.where((user) => user.isActive && !user.isLocked).toList();
    } else if (_selectedStatusFilter == 'locked') {
      filtered = filtered.where((user) => user.isLocked).toList();
    }

    setState(() {
      _filteredUsers = filtered;
      _currentPage = 0;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  void _onRoleFilterChanged(String? value) {
    setState(() {
      _selectedRoleFilter = value ?? 'all';
    });
    _applyFilters();
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _selectedStatusFilter = value ?? 'active';
    });
    _applyFilters();
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddUserDialog(),
    );

    if (result == true) {
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ User created successfully')),
        );
      }
    }
  }

  Future<void> _showEditUserDialog(BackendUserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (result == true) {
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ User updated successfully')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BackendUserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.displayName}?'),
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
      await _deleteUser(user);
    }
  }

  Future<void> _deleteUser(BackendUserModel user) async {
    try {
      await _userService.deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ User deleted successfully')),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error deleting user: $e')),
        );
      }
    }
  }

  Future<void> _toggleLockUser(BackendUserModel user) async {
    try {
      if (user.isLocked) {
        await _userService.unlockUser(user.id);
      } else {
        await _userService.lockUser(user.id);
      }

      if (mounted) {
        final action = user.isLocked ? 'unlocked' : 'locked';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ User $action successfully')),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  // Get paginated users
  List<BackendUserModel> get _paginatedUsers {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    if (start >= _filteredUsers.length) return [];
    return _filteredUsers.sublist(start, min(end, _filteredUsers.length));
  }

  int get _totalPages =>
      (_filteredUsers.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Statistics Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  title: 'Total Users',
                  value: _allUsers.length.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Active',
                  value: _allUsers
                      .where((u) => u.isActive && !u.isLocked)
                      .length
                      .toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Locked',
                  value: _allUsers.where((u) => u.isLocked).length.toString(),
                  icon: Icons.lock,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by email, name, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        isExpanded: true,
                        onChanged: _onStatusFilterChanged,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'locked', child: Text('Locked')),
                          DropdownMenuItem(value: 'all', child: Text('All')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedRoleFilter,
                        isExpanded: true,
                        onChanged: _onRoleFilterChanged,
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All Roles'),
                          ),
                          ...PredefinedRoles.allRoles.map((role) {
                            return DropdownMenuItem(
                              value: role.id,
                              child: Text(role.name),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // User List
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
                              onPressed: _loadUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? const Center(
                            child: Text('No users found'),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                UserListWidget(
                                  users: _paginatedUsers,
                                  onEdit: (user) async {
                                    final canEdit =
                                        await _accessControl.hasPermission(
                                      Permission.EDIT_USERS,
                                    );
                                    if (canEdit) {
                                      await _showEditUserDialog(user);
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '❌ You do not have permission to edit users'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  onDelete: (user) async {
                                    final canDelete =
                                        await _accessControl.hasPermission(
                                      Permission.DELETE_USERS,
                                    );
                                    if (canDelete) {
                                      await _showDeleteConfirmation(user);
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '❌ You do not have permission to delete users'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  onToggleLock: (user) async {
                                    final canLock =
                                        await _accessControl.hasPermission(
                                      Permission.LOCK_USERS,
                                    );
                                    if (canLock) {
                                      await _toggleLockUser(user);
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '❌ You do not have permission to lock/unlock users'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                // Pagination
                                if (_totalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: _currentPage > 0
                                              ? () {
                                                  setState(
                                                    () => _currentPage--,
                                                  );
                                                }
                                              : null,
                                          icon: const Icon(Icons.chevron_left),
                                        ),
                                        Text(
                                          'Page ${_currentPage + 1} of $_totalPages',
                                        ),
                                        IconButton(
                                          onPressed: _currentPage < _totalPages - 1
                                              ? () {
                                                  setState(
                                                    () => _currentPage++,
                                                  );
                                                }
                                              : null,
                                          icon:
                                              const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _accessControl.hasPermission(Permission.CREATE_USERS),
        builder: (context, snapshot) {
          final canCreate = snapshot.data ?? false;
          if (!canCreate) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: _showAddUserDialog,
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
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function for min
int min(int a, int b) => a < b ? a : b;
