part of 'users_management_screen.dart';

extension _UsersManagementUI on _UsersManagementScreenState {
  Widget _buildUsersManagementScreen(BuildContext context) {
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
