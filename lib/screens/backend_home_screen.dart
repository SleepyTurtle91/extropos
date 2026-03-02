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

part 'backend_home_layout_builders.dart';
part 'backend_home_component_builders.dart';

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

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Remote Manager',
      subtitle: 'Cloud management tools are coming soon for offline POS.',
    );
  }
}
