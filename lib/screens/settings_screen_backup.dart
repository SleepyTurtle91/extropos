import 'dart:io';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:extropos/screens/advanced_reports_screen.dart';
import 'package:extropos/screens/analytics_dashboard_screen.dart';
import 'package:extropos/screens/business_info_screen.dart';
import 'package:extropos/screens/categories_management_screen.dart';
import 'package:extropos/screens/customer_displays_management_screen.dart';
import 'package:extropos/screens/customers_management_screen.dart';
import 'package:extropos/screens/database_test_screen.dart';
import 'package:extropos/screens/debug_tools_screen.dart';
import 'package:extropos/screens/dual_display_settings_screen.dart';
import 'package:extropos/screens/employee_performance_screen.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/kitchen_display_screen.dart';
import 'package:extropos/screens/modifier_groups_management_screen.dart';
import 'package:extropos/screens/order_queue_screen.dart';
import 'package:extropos/screens/payment_methods_management_screen.dart';
import 'package:extropos/screens/printers_management_screen.dart';
import 'package:extropos/screens/receipt_settings_screen.dart';
import 'package:extropos/screens/refund_screen.dart';
import 'package:extropos/screens/roles_management_screen.dart';
import 'package:extropos/screens/sales_history_screen.dart';
import 'package:extropos/screens/setup_screen.dart';
import 'package:extropos/screens/tables_management_screen.dart';
import 'package:extropos/screens/theme_settings_screen.dart';
import 'package:extropos/screens/users_management_screen.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/reset_service.dart';
import 'package:extropos/services/training_data_generator.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:extropos/services/update_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UpdateServiceFactory = UpdateService Function();
typedef OpenFileFunction = Future<void> Function(String path);

class SettingsScreen extends StatelessWidget {
  final UpdateServiceFactory? updateServiceFactory;
  final OpenFileFunction? openFileFn;

  const SettingsScreen({super.key, this.updateServiceFactory, this.openFileFn});

  Future<Map<String, String>> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'appName': packageInfo.appName,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getAppInfo(),
        builder: (context, snapshot) {
          final appInfo =
              snapshot.data ??
              {'version': '1.0.5', 'buildNumber': '5', 'appName': 'ExtroPOS'};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: _buildSettingsContent(context, appInfo),
          );
        },
      ),
    );
  }

  List<Widget> _buildSettingsContent(
    BuildContext context,
    Map<String, String> appInfo,
  ) {
    return [
      _SettingsSection(
        title: 'Hardware',
        children: [
          _SettingsTile(
            icon: Icons.print,
            title: 'Printers Management',
            subtitle: 'Configure receipt and kitchen printers',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrintersManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.monitor,
            title: 'Dual Display Settings',
            subtitle: 'Configure customer display for IMIN hardware',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DualDisplaySettingsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.desktop_windows,
            title: 'Customer Displays',
            subtitle: 'Manage customer facing displays',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CustomerDisplaysManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'User Management',
        children: [
          _SettingsTile(
            icon: Icons.people,
            title: 'Users Management',
            subtitle: 'Manage staff accounts and permissions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UsersManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.group,
            title: 'Customers Management',
            subtitle: 'Manage customer database and loyalty',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomersManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.security,
            title: 'Roles Management',
            subtitle: 'Configure role permissions and access levels',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RolesManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'Products',
        children: [
          _SettingsTile(
            icon: Icons.category,
            title: 'Categories Management',
            subtitle: 'Organize products into categories',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoriesManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.inventory,
            title: 'Items Management',
            subtitle: 'Add and manage products',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemsManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.tune,
            title: 'Modifier Groups',
            subtitle: 'Manage product modifiers and options',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModifierGroupsManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.undo,
            title: 'Refunds & Returns',
            subtitle: 'Process customer refunds and returns',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RefundScreen()),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'Restaurant',
        children: [
          _SettingsTile(
            icon: Icons.table_restaurant,
            title: 'Tables Management',
            subtitle: 'Configure restaurant tables and layout',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TablesManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.restaurant,
            title: 'Kitchen Display System',
            subtitle: 'Monitor and manage kitchen orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KitchenDisplayScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.monitor,
            title: 'Cafe Order Queue Display',
            subtitle: 'Customer-facing order status display',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderQueueScreen(),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'Appearance',
        children: [
          _SettingsTile(
            icon: Icons.palette,
            title: 'Theme & Color Scheme',
            subtitle: 'Customize app colors and appearance',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'General',
        children: [
          Consumer<TrainingModeService>(
            builder: (context, trainingService, _) {
              return SwitchListTile(
                title: const Text('Training Mode'),
                subtitle: const Text(
                  'Enable demo mode - no persistent changes will be saved',
                ),
                value: trainingService.isTrainingMode,
                onChanged: (value) async {
                  await trainingService.toggleTrainingMode(value);
                  ToastHelper.showToast(
                    context,
                    value ? 'Training mode enabled' : 'Training mode disabled',
                  );
                },
                secondary: const Icon(Icons.school),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.business,
            title: 'Business Information',
            subtitle: 'Store name, address, tax settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessInfoScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.store,
            title: 'Business Mode',
            subtitle: 'Select your business type (Retail, Cafe, Restaurant)',
            onTap: () => _showBusinessModeDialog(context),
          ),
          _SettingsTile(
            icon: Icons.vpn_key,
            title: 'Software Activation',
            subtitle: 'Enter license key to unlock full features',
            onTap: () {
              Navigator.pushNamed(context, '/activation');
            },
          ),
          _SettingsTile(
            icon: Icons.attach_money,
            title: 'Payment Methods',
            subtitle: 'Configure payment options',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentMethodsManagementScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.history,
            title: 'Sales History',
            subtitle: 'View recent orders and transactions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesHistoryScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.receipt_long,
            title: 'Receipt Settings',
            subtitle: 'Customize receipt layout and footer',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceiptSettingsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.description,
            title: 'e-Invoice (Malaysia)',
            subtitle: 'MyInvois integration for Malaysian tax compliance',
            onTap: () {
              Navigator.pushNamed(context, '/einvoice-submission');
            },
          ),
          if (kDebugMode)
            _SettingsTile(
              icon: Icons.bug_report,
              title: 'Debug Tools',
              subtitle: 'Developer tools for debugging hardware & plugins',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugToolsScreen(),
                  ),
                );
              },
            ),
          _SettingsTile(
            icon: Icons.refresh,
            title: 'Reset POS',
            subtitle: 'Clear all POS data (optional backup before reset)',
            onTap: () async {
              final currentContext = context; // capture for async UI
              // Only allow first admin to reset POS
              final currentUser = LockManager.instance.currentUser;
              if (currentUser?.id != 'first-admin-system') {
                if (currentContext.mounted) {
                  ToastHelper.showToast(
                    currentContext,
                    'Only the system administrator can reset the POS',
                  );
                }
                return;
              }

              final result = await showDialog<Map<String, dynamic>>(
                context: currentContext,
                builder: (context) {
                  bool backup = false;
                  return StatefulBuilder(
                    builder: (context, setState) => AlertDialog(
                      title: const Text('Reset POS State'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'This will delete ALL persisted database data (categories, items, users, tables, orders, transactions) and clear in-memory POS state. This action is destructive and cannot be undone.',
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: backup,
                            onChanged: (v) =>
                                setState(() => backup = v ?? false),
                            title: const Text('Create backup before resetting'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, {
                            'confirmed': false,
                            'backup': false,
                          }),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, {
                            'confirmed': true,
                            'backup': backup,
                          }),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (result == null) return;

              final confirmed = result['confirmed'] == true;
              final doBackup = result['backup'] == true;

              if (!confirmed) return;

              if (doBackup) {
                try {
                  final backupPath = await DatabaseHelper.instance
                      .backupDatabase();
                  if (currentContext.mounted) {
                    ToastHelper.showToast(
                      currentContext,
                      'Database backed up to $backupPath',
                    );
                  }
                } catch (e) {
                  if (currentContext.mounted) {
                    ToastHelper.showToast(currentContext, 'Backup failed: $e');
                  }
                  // Abort reset if backup is requested but fails
                  return;
                }
              }

              try {
                // Safely reset on-disk database with automatic backup
                final backupResult = await DatabaseHelper.instance
                    .safeResetDatabase();
                if (currentContext.mounted) {
                  ToastHelper.showToast(
                    currentContext,
                    'Database reset complete. Backup: $backupResult',
                  );
                }
              } catch (e) {
                if (currentContext.mounted) {
                  ToastHelper.showToast(
                    currentContext,
                    'Error resetting database: $e',
                  );
                }
                return;
              }

              // Broadcast in-memory reset
              ResetService.instance.triggerReset();
              if (currentContext.mounted) {
                ToastHelper.showToast(
                  currentContext,
                  'POS database and in-memory state cleared.',
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.system_update,
            title: 'Check for updates',
            subtitle: 'Download latest APK from GitHub releases',
            onTap: () async {
              try {
                final currentContext = context;
                // Show a progress dialog while downloading
                showDialog(
                  context: currentContext,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    content: Row(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Expanded(child: Text('Downloading latest APK...')),
                      ],
                    ),
                  ),
                );

                // use injected factory if available for tests/mocking
                final svc =
                    updateServiceFactory?.call() ??
                    UpdateService(owner: 'Giras91', repo: 'flutterpos');

                // Show an option dialog to choose whether to open after download
                final choice = await showDialog<String>(
                  context: currentContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Download Update'),
                    content: const Text(
                      'Would you like to open the APK after download?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'download'),
                        child: const Text('Download'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, 'download_open'),
                        child: const Text('Download & Open'),
                      ),
                    ],
                  ),
                );
                if (choice == null || choice == 'cancel') {
                  if (currentContext.mounted)
                    Navigator.of(currentContext).pop();
                  return;
                }

                final filePath = await svc.downloadLatestApk();

                // Save to Downloads or Desktop if possible
                // Prefer Desktop, fallback to Downloads, then HOME
                Directory desktopPath;
                final home = Platform.environment['HOME'] ?? '';
                if (Platform.isWindows) {
                  desktopPath = Directory(
                    Platform.environment['USERPROFILE'] ?? '',
                  );
                } else {
                  desktopPath = Directory('$home/Desktop');
                }
                if (!await desktopPath.exists()) {
                  // Try Downloads
                  final downloads = Directory('$home/Downloads');
                  if (await downloads.exists()) {
                    desktopPath = downloads;
                  } else {
                    // Fallback to home directory
                    desktopPath = Directory(home);
                  }
                }
                final file = File(filePath);
                final target = File(
                  '${desktopPath.path}/${file.uri.pathSegments.last}',
                );
                try {
                  await file.copy(target.path);
                } catch (e) {
                  // Copy failed: show helpful dialog and fallback options
                  if (currentContext.mounted) {
                    Navigator.of(currentContext).pop(); // close progress
                    final action = await showDialog<String>(
                      context: currentContext,
                      builder: (context) => AlertDialog(
                        title: const Text('Unable to save file'),
                        content: Text(
                          'Failed to write APK to ${desktopPath.path}: $e\n\nYou can pick a different location or open the APK directly if supported.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop('cancel'),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop('choose'),
                            child: const Text('Choose location'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop('open'),
                            child: const Text('Open APK'),
                          ),
                        ],
                      ),
                    );
                    if (action == 'choose') {
                      final fileSave = await getSaveLocation(
                        suggestedName: file.uri.pathSegments.last,
                      );
                      if (fileSave != null) {
                        await File(
                          fileSave.path,
                        ).writeAsBytes(await file.readAsBytes());
                        ToastHelper.showToast(
                          currentContext,
                          'Saved to ${fileSave.path}',
                        );
                      }
                    } else if (action == 'open') {
                      // Try to open via injected openFileFn or default OpenFilex
                      final openFn =
                          openFileFn ?? (path) => OpenFilex.open(path);
                      await openFn(file.path);
                    }
                    return;
                  }
                }

                if (currentContext.mounted) {
                  Navigator.of(currentContext).pop(); // close progress
                  ToastHelper.showToast(
                    currentContext,
                    'Latest APK downloaded: ${target.path}',
                  );
                }

                if (choice == 'download_open') {
                  // Attempt to open: use injected function if provided (test override), otherwise use OpenFilex
                  final openFn = openFileFn ?? (path) => OpenFilex.open(path);
                  try {
                    await openFn(target.path);
                  } catch (e) {
                    if (currentContext.mounted)
                      ToastHelper.showToast(
                        currentContext,
                        'Unable to open APK: $e',
                      );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ToastHelper.showToast(context, 'Update failed: $e');
                }
              }
            },
          ),
          _SettingsTile(
            icon: Icons.school,
            title: 'Clear Training Data',
            subtitle: 'Clear temporary training transactions and sample data',
            onTap: () async {
              // Clear in-memory training transactions
              TrainingModeService.instance.clearTrainingData();
              // Also attempt to clear sample training DB entries (if any were created)
              try {
                await TrainingDataGenerator.instance.clearTrainingData();
                ToastHelper.showToast(context, 'Training data cleared');
              } catch (e) {
                ToastHelper.showToast(
                  context,
                  'Failed to clear training DB data: $e',
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.restart_alt,
            title: 'Reset Setup',
            subtitle: 'Return to first-run setup (clears store name)',
            onTap: () async {
              final currentContext = context; // capture for async UI
              // Only allow first admin to reset setup
              final currentUser = LockManager.instance.currentUser;
              if (currentUser?.id != 'first-admin-system') {
                if (currentContext.mounted) {
                  ToastHelper.showToast(
                    currentContext,
                    'Only the system administrator can reset the setup',
                  );
                }
                return;
              }

              final result = await showDialog<Map<String, dynamic>>(
                context: currentContext,
                builder: (context) {
                  bool resetDb = false;
                  bool backup = false;
                  return StatefulBuilder(
                    builder: (context, setState) => AlertDialog(
                      title: const Text('Reset Setup'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'This will clear the initial setup flag and store name so the app will show the setup screen on next start. Optionally you can reset the database to factory defaults (this will recreate seeded data).',
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: backup,
                            onChanged: (v) =>
                                setState(() => backup = v ?? false),
                            title: const Text('Create backup before resetting'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            value: resetDb,
                            onChanged: (v) =>
                                setState(() => resetDb = v ?? false),
                            title: const Text(
                              'Also reset database to factory defaults',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, {
                            'confirmed': false,
                            'resetDb': false,
                            'backup': false,
                          }),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, {
                            'confirmed': true,
                            'resetDb': resetDb,
                            'backup': backup,
                          }),
                          child: const Text('Reset Setup'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (result == null) return;
              final confirmed = result['confirmed'] == true;
              final doResetDb = result['resetDb'] == true;
              final doBackup = result['backup'] == true;
              if (!confirmed) return;

              // Clear setup flag and store name
              try {
                await ConfigService.instance.setSetupDone(false);
                await ConfigService.instance.setStoreName('');
              } catch (e) {
                if (currentContext.mounted) {
                  ToastHelper.showToast(
                    currentContext,
                    'Error clearing setup flag: $e',
                  );
                }
                return;
              }

              if (doBackup) {
                try {
                  final backupPath = await DatabaseHelper.instance
                      .backupDatabase();
                  if (currentContext.mounted) {
                    ToastHelper.showToast(
                      currentContext,
                      'Database backed up to $backupPath',
                    );
                  }
                } catch (e) {
                  if (currentContext.mounted) {
                    ToastHelper.showToast(currentContext, 'Backup failed: $e');
                  }
                  // Abort reset if backup is requested but fails
                  return;
                }
              }

              if (doResetDb) {
                try {
                  await DatabaseHelper.instance.resetDatabase();
                } catch (e) {
                  if (currentContext.mounted) {
                    ToastHelper.showToast(
                      currentContext,
                      'Error resetting database: $e',
                    );
                  }
                  return;
                }
              }

              // Broadcast in-memory reset and navigate to setup screen
              ResetService.instance.triggerReset();
              if (context.mounted) {
                ToastHelper.showToast(
                  context,
                  'Setup cleared — showing Setup screen now',
                );
                // Replace stack with SetupScreen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (c) => const SetupScreen()),
                  (route) => false,
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.analytics,
            title: 'Advanced Reports',
            subtitle:
                'Sales analytics, product performance, and business insights',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedReportsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.dashboard,
            title: 'Analytics Dashboard',
            subtitle: 'Interactive charts and real-time sales analytics',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboardScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.people_outline,
            title: 'Employee Performance',
            subtitle: 'Track sales, commissions, shifts, and leaderboards',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeePerformanceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'Help & Support',
        children: [
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Show Tutorial',
            subtitle: 'Replay the getting started guide',
            onTap: () async {
              await AppSettings.instance.resetTutorial();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
                ToastHelper.showToast(
                  context,
                  'Tutorial will show on next app start',
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.school,
            title: 'Training Mode',
            subtitle: AppSettings.instance.isTrainingMode
                ? 'Currently enabled'
                : 'Currently disabled',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Training Mode'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Training Mode allows you to practice using the system without affecting real data.',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'When enabled:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• All transactions are marked as training'),
                      const Text('• Data can be easily cleared'),
                      const Text('• Perfect for staff training'),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: AppSettings.instance,
                        builder: (context, child) {
                          return SwitchListTile(
                            title: const Text('Enable Training Mode'),
                            value: AppSettings.instance.isTrainingMode,
                            onChanged: (value) {
                              AppSettings.instance.setTrainingMode(value);
                            },
                          );
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Training Data',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Load Training Data'),
                              content: const Text(
                                'This will add sample categories and items to your database for training purposes. This will not delete existing data.\n\nContinue?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Load Data'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            try {
                              await TrainingDataGenerator.instance
                                  .generateSampleCategories();
                              await TrainingDataGenerator.instance
                                  .generateSampleItems();
                              if (context.mounted) {
                                ToastHelper.showToast(
                                  context,
                                  'Training data loaded successfully',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ToastHelper.showToast(
                                  context,
                                  'Error loading training data: $e',
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Load Sample Data'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Training Data'),
                              content: const Text(
                                'This will delete ALL categories and items from the database. This action cannot be undone!\n\nAre you sure?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Clear All Data'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            try {
                              await TrainingDataGenerator.instance
                                  .clearTrainingData();
                              if (context.mounted) {
                                ToastHelper.showToast(
                                  context,
                                  'Training data cleared successfully',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ToastHelper.showToast(
                                  context,
                                  'Error clearing training data: $e',
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear All Data'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.book,
            title: 'User Guide',
            subtitle: 'Learn how to use ExtroPOS',
            onTap: () {
              _showUserGuideDialog(context);
            },
          ),
          _SettingsTile(
            icon: Icons.block,
            title: 'Require DB Products',
            subtitle: 'Prevent adding products not present in the database',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Require DB Products'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'When enabled, you cannot add mock/fallback products to the cart. Please add the item in Items Management first.',
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: AppSettings.instance,
                        builder: (context, child) {
                          return SwitchListTile(
                            title: const Text('Enforce DB-only products'),
                            value: AppSettings.instance.requireDbProducts,
                            onChanged: (v) =>
                                AppSettings.instance.setRequireDbProducts(v),
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'Developer',
        children: [
          _SettingsTile(
            icon: Icons.storage,
            title: 'Database Test',
            subtitle: 'Test and verify database functionality',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseTestScreen(),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SettingsSection(
        title: 'About',
        children: [
          _SettingsTile(
            icon: Icons.info,
            title: 'App Information',
            subtitle:
                '${appInfo['appName']} v${appInfo['version']} (Build ${appInfo['buildNumber']})',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: appInfo['appName'],
                applicationVersion:
                    'v${appInfo['version']} (Build ${appInfo['buildNumber']})',
                applicationIcon: const Icon(
                  Icons.store,
                  size: 48,
                  color: Color(0xFF2563EB),
                ),
                children: [
                  const Text(
                    'A modern point-of-sale system for retail, cafe, and restaurant businesses.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Features:\n'
                    '• Multi-mode support (Retail, Cafe, Restaurant)\n'
                    '• iMin device compatibility\n'
                    '• Encrypted PIN storage\n'
                    '• Dual display support\n'
                    '• Cloud sync with Appwrite\n'
                    '• Advanced reporting\n'
                    '• Thermal receipt printing',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
          _SettingsTile(
            icon: Icons.system_update,
            title: 'Check for Updates',
            subtitle: 'Download latest version from GitHub',
            onTap: () => _checkForUpdates(context),
          ),
        ],
      ),
    ];
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updateService = UpdateService(owner: 'Giras91', repo: 'flutterpos');

      final updateInfo = await updateService.checkForUpdates();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (updateInfo == null) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Releases Available'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Could not find any releases on GitHub.'),
                  SizedBox(height: 12),
                  Text(
                    'This could mean:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• No releases have been published yet'),
                  Text('• Repository is private'),
                  Text('• Network connection issue'),
                  SizedBox(height: 12),
                  Text(
                    'To enable updates, publish a release on GitHub with an APK file attached.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!updateInfo.isNewer) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Up to Date'),
              content: Text(
                'You are running the latest version (${updateInfo.version}).',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show update available dialog
      if (context.mounted) {
        _showUpdateDialog(context, updateInfo);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to check for updates: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${updateInfo.version} is now available!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Release: ${updateInfo.tagName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Release Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  updateInfo.releaseNotes,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallUpdate(context, updateInfo);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download & Install'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstallUpdate(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    if (!Platform.isAndroid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Supported'),
          content: const Text(
            'Automatic updates are only supported on Android. Please download the update manually from GitHub.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri.parse(updateInfo.downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Open in Browser'),
            ),
          ],
        ),
      );
      return;
    }

    // Show download progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading update...'),
                SizedBox(height: 8),
                Text(
                  'This may take a few minutes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updateService = UpdateService(owner: 'Giras91', repo: 'flutterpos');

      final apkPath = await updateService.downloadLatestApk(
        assetNameContains: '.apk',
      );

      // Close download dialog
      if (context.mounted) Navigator.pop(context);

      // Open the APK for installation
      await OpenFilex.open(apkPath);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Complete'),
            content: const Text(
              'The update has been downloaded. Please follow the on-screen instructions to install the update.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close download dialog
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Failed'),
            content: Text('Failed to download update: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(updateInfo.downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Download Manually'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showUserGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.book, size: 32, color: Colors.blue),
                  const SizedBox(width: 16),
                  const Text(
                    'User Guide',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildGuideSection('Getting Started', Icons.rocket_launch, [
                      '1. Choose your business type (Retail, Cafe, or Restaurant)',
                      '2. Configure your business information',
                      '3. Set up categories and items',
                      '4. Add payment methods and printers',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Training Mode', Icons.school, [
                      'Enable Training Mode to practice without affecting real data',
                      'Perfect for training new staff members',
                      'All transactions will be marked as training',
                      'Easily clear training data when done',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Managing Sales', Icons.point_of_sale, [
                      'Add items to cart by tapping on them',
                      'Adjust quantities as needed',
                      'Apply discounts if applicable',
                      'Select payment method and complete transaction',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Reports', Icons.analytics, [
                      'View daily, weekly, and monthly sales reports',
                      'Track best-selling items',
                      'Monitor payment method usage',
                      'Export reports for accounting',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Settings', Icons.settings, [
                      'Business Info: Update your business details',
                      'Users: Manage staff accounts and permissions',
                      'Categories & Items: Organize your products',
                      'Printers: Configure receipt printing',
                      'Payment Methods: Set up payment options',
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, IconData icon, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(point, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBusinessModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Business Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBusinessModeOption(
                context,
                BusinessMode.retail,
                'Retail Mode',
                'Enable product code search for direct sales',
                Icons.shopping_cart,
              ),
              const SizedBox(height: 16),
              _buildBusinessModeOption(
                context,
                BusinessMode.cafe,
                'Cafe Mode',
                'Calling number system for takeaway orders',
                Icons.local_cafe,
              ),
              const SizedBox(height: 16),
              _buildBusinessModeOption(
                context,
                BusinessMode.restaurant,
                'Restaurant Mode',
                'Table management for dine-in service',
                Icons.restaurant,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBusinessModeOption(
    BuildContext context,
    BusinessMode mode,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = BusinessInfo.instance.selectedBusinessMode == mode;
    return InkWell(
      onTap: () {
        BusinessInfo.updateInstance(
          BusinessInfo.instance.copyWith(selectedBusinessMode: mode),
        );
        Navigator.of(context).pop();
        ToastHelper.showToast(context, '$title selected');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color.fromRGBO(37, 99, 235, 0.1)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(37, 99, 235, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
