part of 'backend_home_screen.dart';

/// Extension providing component builders for cards and tiles
extension _BackendHomeComponentBuilders on _BackendHomeScreenState {
  Widget _buildWelcomeCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                  child: const Icon(Icons.dashboard_customize_outlined,
                      color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Remote Manager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cloud management dashboard for ExtroPOS',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    if (!AppwriteService.isEnabled) {
      return const SizedBox.shrink();
    }
    final syncService = AppwriteSyncService.instance;
    final isInitialized = syncService.isInitialized;
    final status = syncService.status;
    final lastSync = syncService.lastSyncTime;
    final errorMessage = syncService.errorMessage;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case SyncStatus.syncing:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = 'Syncing...';
        break;
      case SyncStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Synced';
        break;
      case SyncStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Error';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_off;
        statusText = isInitialized ? 'Ready' : 'Not configured';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appwrite Sync Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 12, color: statusColor),
                      ),
                    ],
                  ),
                ),
                if (isInitialized && status != SyncStatus.syncing)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isSyncing ? null : _performSync,
                    tooltip: 'Sync Now',
                    color: const Color(0xFF2563EB),
                  ),
              ],
            ),
            if (lastSync != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Last synced: ${DateFormat('MMM dd, yyyy HH:mm').format(lastSync)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTilesWidget() {
    final tiles = _buildManagementTiles();
    return Column(
      children: tiles,
    );
  }

  List<Widget> _buildManagementTilesGrid(int crossAxisCount) {
    return _buildManagementTiles();
  }

  List<Widget> _buildManagementTiles() {
    final tiles = <Widget>[
      _buildMenuTile(
        icon: Icons.category,
        title: 'Categories',
        subtitle: 'Manage product categories',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BackendCategoriesScreen(),
            ),
          );
        },
      ),
      _buildMenuTile(
        icon: Icons.inventory_2,
        title: 'Products',
        subtitle: 'Manage products and pricing',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BackendProductsScreen(),
            ),
          );
        },
      ),
      _buildMenuTile(
        icon: Icons.add_circle_outline,
        title: 'Modifiers',
        subtitle: 'Manage product modifiers',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModifierGroupsManagementScreen(),
            ),
          );
        },
      ),
      _buildMenuTile(
        icon: Icons.business,
        title: 'Business Info',
        subtitle: 'Update business details',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BusinessInfoScreen()),
          );
        },
      ),
    ];

    // Phase 1 Admin Features - Add if user has permission
    if (_canViewUsers) {
      tiles.add(
        _buildMenuTile(
          icon: Icons.people,
          title: 'Users',
          subtitle: 'Manage backend users and access',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserManagementScreen(),
              ),
            );
          },
        ),
      );
    }

    if (_canViewRoles) {
      tiles.add(
        _buildMenuTile(
          icon: Icons.security,
          title: 'Roles & Permissions',
          subtitle: 'Manage roles and permissions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RoleManagementScreen(),
              ),
            );
          },
        ),
      );
    }

    if (_canManageInventory) {
      tiles.add(
        _buildMenuTile(
          icon: Icons.warehouse,
          title: 'Inventory',
          subtitle: 'Track and manage inventory',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InventoryDashboardScreen(),
              ),
            );
          },
        ),
      );
    }

    if (_canViewActivityLogs) {
      tiles.add(
        _buildMenuTile(
          icon: Icons.history,
          title: 'Activity Logs',
          subtitle: 'View system activity and audit trail',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityLogScreen(),
              ),
            );
          },
        ),
      );
    }

    return tiles;
  }

  List<Widget> _buildReportsTiles() {
    return [
      _buildMenuTile(
        icon: Icons.analytics,
        title: 'Advanced Reports',
        subtitle: 'View sales analytics',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdvancedReportsScreen(),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
