import 'package:extropos/helpers/responsive_helper.dart';
import 'package:extropos/screens/advanced_reports_screen.dart';
import 'package:extropos/screens/backend/activity_log_screen.dart';
import 'package:extropos/screens/backend/inventory_dashboard_screen.dart';
import 'package:extropos/screens/backend/role_management_screen.dart';
import 'package:extropos/screens/backend/user_management_screen.dart';
import 'package:extropos/screens/backend_categories_screen.dart';
import 'package:extropos/screens/backend_products_screen.dart';
import 'package:extropos/screens/business_info_screen.dart';
import 'package:extropos/screens/modifier_groups_management_screen.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/services/appwrite_sync_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Backend Manager Home Screen
/// For remote management of categories, products, modifiers, and viewing reports
/// This is an optional premium feature for remote POS management
class BackendHomeScreen extends StatefulWidget {
  const BackendHomeScreen({super.key});

  @override
  State<BackendHomeScreen> createState() => _BackendHomeScreenState();
}

class _BackendHomeScreenState extends State<BackendHomeScreen> {
  bool _isSyncing = false;
  late final AccessControlService _accessControl;

  // Permission flags loaded asynchronously
  bool _canViewUsers = false;
  bool _canViewRoles = false;
  bool _canManageInventory = false;
  bool _canViewActivityLogs = false;

  @override
  void initState() {
    super.initState();
    _accessControl = AccessControlService.instance;
    // Listen to sync service changes
    AppwriteSyncService.instance.addListener(_onSyncStatusChanged);
    // Load permissions asynchronously
    _loadPermissions();
  }

  @override
  void dispose() {
    AppwriteSyncService.instance.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _onSyncStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPermissions() async {
    try {
      final results = await Future.wait([
        _accessControl.hasPermission('VIEW_USERS'),
        _accessControl.hasPermission('VIEW_ROLES'),
        _accessControl.hasPermission('MANAGE_INVENTORY'),
        _accessControl.hasPermission('VIEW_ACTIVITY_LOGS'),
      ]);

      if (mounted) {
        setState(() {
          _canViewUsers = results[0];
          _canViewRoles = results[1];
          _canManageInventory = results[2];
          _canViewActivityLogs = results[3];
        });
      }
    } catch (e) {
      print('Error loading permissions: $e');
      // On error, keep defaults (false)
    }
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = AppwriteSyncService.instance;

      if (!syncService.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please configure Appwrite settings first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final result = await syncService.fullSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '✓ Sync complete! ${result.itemsSynced} items synced'
                  : '✗ Sync failed: ${result.error}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  // Removed display mode service - not needed for web-optimized backend

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Remote Manager',
      subtitle: 'Cloud management tools are coming soon for offline POS.',
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('ExtroPOS Remote Manager'),
            const SizedBox(width: 8),
            // Premium feature indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: const [],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout optimized for web browsers
          if (constraints.maxWidth < 768) {
            // Mobile layout
            return _buildMobileLayout();
          } else if (constraints.maxWidth < 1200) {
            // Tablet layout
            return _buildTabletLayout();
          } else {
            // Desktop layout
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(),
        if (AppwriteService.isEnabled) ...[
          const SizedBox(height: 24),
          _buildSyncStatusCard(),
          const SizedBox(height: 24),
        ],
        const Text(
          'Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildManagementTilesWidget(),
        const SizedBox(height: 24),
        const Text(
          'Reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._buildReportsTiles(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              _buildWelcomeCard(),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'MANAGEMENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    _buildManagementTilesWidget(),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'REPORTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ..._buildReportsTiles(),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Center(
            child: AppwriteService.isEnabled
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSyncStatusCard(),
                      const SizedBox(height: 32),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        // Top section with welcome and sync status
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWelcomeCard(),
              if (AppwriteService.isEnabled) ...[
                const SizedBox(height: 16),
                _buildSyncStatusCard(),
              ],
            ],
          ),
        ),
        const Divider(),
        // Bottom section with management tiles in a responsive grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  ResponsiveHelper.getAdaptiveCrossAxisCountFromConstraints(
                    constraints,
                    minColumns: 1,
                    maxColumns: 4,
                  );

              return GridView.count(
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  ..._buildReportsTiles(),
                  ..._buildManagementTilesGrid(crossAxisCount),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

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
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ExtroPOS Remote Manager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Premium Remote Management',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
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
                      Text(
                        'Appwrite Sync Status',
                        style: const TextStyle(
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
