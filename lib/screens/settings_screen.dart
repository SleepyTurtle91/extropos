import 'dart:io';

// business_mode.dart no longer used after removing mode selection UI
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
import 'package:extropos/screens/ewallet_settings_screen.dart';
import 'package:extropos/screens/generate_test_data_screen.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/kitchen_display_screen.dart';
import 'package:extropos/screens/modifier_groups_management_screen.dart';
import 'package:extropos/screens/my_invois_settings_screen.dart';
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
import 'package:extropos/screens/thermal_printer_integration_screen.dart';
import 'package:extropos/screens/users_management_screen.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/lazy_loading_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/memory_manager.dart';
import 'package:extropos/services/performance_monitor.dart';
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

class SettingsScreen extends StatefulWidget {
  final UpdateServiceFactory? updateServiceFactory;
  final OpenFileFunction? openFileFn;

  const SettingsScreen({super.key, this.updateServiceFactory, this.openFileFn});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _activeCategoryId;

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
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _getAppInfo(),
          builder: (context, snapshot) {
            final appInfo =
                snapshot.data ??
                {'version': '1.0.5', 'buildNumber': '5', 'appName': 'ExtroPOS'};
            final trainingService = context.watch<TrainingModeService>();
            final categories = _buildCategories(
              context,
              appInfo,
              trainingService,
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 600) crossAxisCount = 2;
                if (constraints.maxWidth >= 900) crossAxisCount = 3;
                if (constraints.maxWidth >= 1200) crossAxisCount = 4;

                final activeCategory = _activeCategoryId == null
                    ? null
                    : categories.firstWhere(
                        (category) => category.id == _activeCategoryId,
                        orElse: () => categories.first,
                      );

                return Column(
                  children: [
                    _buildHeader(constraints.maxWidth, activeCategory),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: activeCategory == null
                            ? _buildMainGrid(crossAxisCount, categories)
                            : _buildSubGrid(crossAxisCount, activeCategory),
                      ),
                    ),
                    _buildFooter(appInfo),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<SettingsCategory> _buildCategories(
    BuildContext context,
    Map<String, String> appInfo,
    TrainingModeService trainingService,
  ) {
    return [
      SettingsCategory(
        id: 'hardware',
        title: 'Hardware',
        icon: Icons.print,
        color: const Color(0xFF4F46E5),
        items: [
          SettingsItem(
            title: 'Printers Management',
            icon: Icons.print,
            description: 'Configure receipt and kitchen printers',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrintersManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Printer Integration',
            icon: Icons.receipt_long,
            description: 'Thermal printer + PDF print tools',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThermalPrinterIntegrationScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Dual Display Settings',
            icon: Icons.monitor,
            description: 'Configure customer display for IMIN hardware',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DualDisplaySettingsScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Customer Displays',
            icon: Icons.desktop_windows,
            description: 'Manage customer facing displays',
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
      SettingsCategory(
        id: 'user_mgmt',
        title: 'User Management',
        icon: Icons.people,
        color: const Color(0xFF10B981),
        items: [
          SettingsItem(
            title: 'Users Management',
            icon: Icons.people,
            description: 'Manage staff accounts and permissions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UsersManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Customers Management',
            icon: Icons.group,
            description: 'Manage customer database and loyalty',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomersManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Roles Management',
            icon: Icons.security,
            description: 'Configure role permissions and access levels',
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
      SettingsCategory(
        id: 'products',
        title: 'Products',
        icon: Icons.shopping_bag,
        color: const Color(0xFFF59E0B),
        items: [
          SettingsItem(
            title: 'Categories Management',
            icon: Icons.category,
            description: 'Organize products into categories',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoriesManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Items Management',
            icon: Icons.inventory,
            description: 'Add and manage products',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemsManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Modifier Groups',
            icon: Icons.tune,
            description: 'Manage product modifiers and options',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModifierGroupsManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Refunds & Returns',
            icon: Icons.undo,
            description: 'Process customer refunds and returns',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RefundScreen()),
              );
            },
          ),
        ],
      ),
      SettingsCategory(
        id: 'restaurant',
        title: 'Restaurant',
        icon: Icons.restaurant,
        color: const Color(0xFFF43F5E),
        items: [
          SettingsItem(
            title: 'Tables Management',
            icon: Icons.table_restaurant,
            description: 'Configure restaurant tables and layout',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TablesManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Kitchen Display System',
            icon: Icons.restaurant,
            description: 'Monitor and manage kitchen orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KitchenDisplayScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Cafe Order Queue Display',
            icon: Icons.monitor,
            description: 'Customer-facing order status display',
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
      SettingsCategory(
        id: 'appearance',
        title: 'Appearance',
        icon: Icons.palette,
        color: const Color(0xFF8B5CF6),
        items: [
          SettingsItem(
            title: 'Theme & Color Scheme',
            icon: Icons.palette,
            description: 'Customize app colors and appearance',
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
      SettingsCategory(
        id: 'general',
        title: 'General',
        icon: Icons.settings,
        color: const Color(0xFF475569),
        items: [
          SettingsItem(
            title: 'Training Mode',
            icon: Icons.school,
            description: trainingService.isTrainingMode
                ? 'Currently enabled'
                : 'Currently disabled',
            onTap: () async {
              final nextValue = !trainingService.isTrainingMode;
              await trainingService.toggleTrainingMode(nextValue);
              if (context.mounted) {
                ToastHelper.showToast(
                  context,
                  nextValue
                      ? 'Training mode enabled'
                      : 'Training mode disabled',
                );
              }
            },
          ),
          SettingsItem(
            title: 'Business Information',
            icon: Icons.business,
            description: 'Store name, address, tax settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessInfoScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Software Activation',
            icon: Icons.vpn_key,
            description: 'Enter license key to unlock full features',
            onTap: () {
              Navigator.pushNamed(context, '/activation');
            },
          ),
          SettingsItem(
            title: 'Payment Methods',
            icon: Icons.attach_money,
            description: 'Configure payment options',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentMethodsManagementScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'E-Wallet Settings',
            icon: Icons.qr_code_2,
            description: 'Enable and configure QR payments',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EWalletSettingsScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Sales History',
            icon: Icons.history,
            description: 'View recent orders and transactions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesHistoryScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Receipt Settings',
            icon: Icons.receipt_long,
            description: 'Customize receipt layout and footer',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceiptSettingsScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'e-Invoice (Malaysia)',
            icon: Icons.description,
            description: 'MyInvois integration for Malaysian tax compliance',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyInvoisSettingsScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'MyInvois Queue',
            icon: Icons.sync_problem,
            description: 'Manage failed e-invoice submissions and retry',
            onTap: () {
              Navigator.pushNamed(context, '/myinvois-queue');
            },
          ),
          SettingsItem(
            title: 'Reset POS',
            icon: Icons.refresh,
            description: 'Clear all POS data (optional backup before reset)',
            onTap: () => _handleResetPos(context),
          ),
          SettingsItem(
            title: 'Check for Updates',
            icon: Icons.system_update,
            description: 'Download latest APK from GitHub releases',
            onTap: () => _downloadLatestApk(context),
          ),
          SettingsItem(
            title: 'Clear Training Data',
            icon: Icons.school,
            description:
                'Clear temporary training transactions and sample data',
            onTap: () => _handleClearTrainingData(context),
          ),
          SettingsItem(
            title: 'Reset Setup',
            icon: Icons.restart_alt,
            description: 'Return to first-run setup (clears store name)',
            onTap: () => _handleResetSetup(context),
          ),
          SettingsItem(
            title: 'Advanced Reports',
            icon: Icons.analytics,
            description:
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
          SettingsItem(
            title: 'Analytics Dashboard',
            icon: Icons.dashboard,
            description: 'Interactive charts and real-time sales analytics',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboardScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Employee Performance',
            icon: Icons.people_outline,
            description: 'Track sales, commissions, shifts, and leaderboards',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeePerformanceScreen(),
                ),
              );
            },
          ),
          if (kDebugMode)
            SettingsItem(
              title: 'Debug Tools',
              icon: Icons.bug_report,
              description: 'Developer tools for debugging hardware & plugins',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugToolsScreen(),
                  ),
                );
              },
            ),
          if (kDebugMode)
            SettingsItem(
              title: 'Generate Test Data',
              icon: Icons.data_usage,
              description: 'Create realistic sales data for testing reports',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GenerateTestDataScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      SettingsCategory(
        id: 'help',
        title: 'Help & Support',
        icon: Icons.help_outline,
        color: const Color(0xFF0EA5E9),
        items: [
          SettingsItem(
            title: 'Show Tutorial',
            icon: Icons.help_outline,
            description: 'Replay the getting started guide',
            onTap: () => _showTutorial(context),
          ),
          SettingsItem(
            title: 'Training Mode',
            icon: Icons.school,
            description: AppSettings.instance.isTrainingMode
                ? 'Currently enabled'
                : 'Currently disabled',
            onTap: () => _showTrainingModeDialog(context),
          ),
          SettingsItem(
            title: 'User Guide',
            icon: Icons.book,
            description: 'Learn how to use ExtroPOS',
            onTap: () => _showUserGuideDialog(context),
          ),
          SettingsItem(
            title: 'Require DB Products',
            icon: Icons.block,
            description: 'Prevent adding products not present in the database',
            onTap: () => _showRequireDbProductsDialog(context),
          ),
        ],
      ),
      SettingsCategory(
        id: 'developer',
        title: 'Developer',
        icon: Icons.code,
        color: const Color(0xFFDB2777),
        items: [
          SettingsItem(
            title: 'Database Test',
            icon: Icons.storage,
            description: 'Test and verify database functionality',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseTestScreen(),
                ),
              );
            },
          ),
          SettingsItem(
            title: 'Performance Report',
            icon: Icons.speed,
            description: 'View app performance metrics and optimization data',
            onTap: () => _showPerformanceReportDialog(context),
          ),
        ],
      ),
      SettingsCategory(
        id: 'about',
        title: 'About',
        icon: Icons.info_outline,
        color: const Color(0xFF94A3B8),
        items: [
          SettingsItem(
            title: 'App Information',
            icon: Icons.info_outline,
            description:
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
                    '• Advanced reporting\n'
                    '• Thermal receipt printing',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
          SettingsItem(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip,
            description: 'View our privacy policy',
            onTap: () async {
              const url = 'https://extropos.org/privacy-policy';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              } else {
                if (context.mounted) {
                  ToastHelper.showToast(
                    context,
                    'Could not launch privacy policy',
                  );
                }
              }
            },
          ),
          SettingsItem(
            title: 'Check for Updates',
            icon: Icons.system_update,
            description: 'Download latest version from GitHub',
            onTap: () => _checkForUpdates(context),
          ),
        ],
      ),
    ];
  }

  Widget _buildHeader(double width, SettingsCategory? activeCategory) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (activeCategory != null || canPop)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: InkWell(
                      onTap: () {
                        if (activeCategory != null) {
                          setState(() => _activeCategoryId = null);
                          return;
                        }
                        if (canPop) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeCategory?.title ?? 'System Settings',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeCategory != null
                            ? 'Manage ${activeCategory.title.toLowerCase()} preferences'
                            : 'Select a configuration tile to get started',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (width >= 600)
            ElevatedButton.icon(
              onPressed: () {
                ToastHelper.showToast(
                  context,
                  'Settings are saved automatically',
                );
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFE2E8F0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainGrid(int crossAxisCount, List<SettingsCategory> categories) {
    return GridView.builder(
      key: const ValueKey('MainGrid'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 180,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return SettingsTileWidget(
          title: category.title,
          description: '${category.items.length} management areas available.',
          icon: category.icon,
          color: category.color,
          onTap: () => setState(() => _activeCategoryId = category.id),
        );
      },
    );
  }

  Widget _buildSubGrid(int crossAxisCount, SettingsCategory category) {
    final items = category.items;
    return GridView.builder(
      key: ValueKey('SubGrid_${category.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 180,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SettingsTileWidget(
          title: item.title,
          description: item.description,
          subLabel: category.title,
          icon: item.icon,
          color: category.color,
          onTap: item.onTap,
        );
      },
    );
  }

  Widget _buildFooter(Map<String, String> appInfo) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${appInfo['appName']} v${appInfo['version']} (Build ${appInfo['buildNumber']})',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResetPos(BuildContext context) async {
    final currentContext = context;
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
                  onChanged: (v) => setState(() => backup = v ?? false),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        final backupPath = await DatabaseHelper.instance.backupDatabase();
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
        return;
      }
    }

    try {
      final backupResult = await DatabaseHelper.instance.safeResetDatabase();
      if (currentContext.mounted) {
        ToastHelper.showToast(
          currentContext,
          'Database reset complete. Backup: $backupResult',
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        ToastHelper.showToast(currentContext, 'Error resetting database: $e');
      }
      return;
    }

    ResetService.instance.triggerReset();
    if (currentContext.mounted) {
      ToastHelper.showToast(
        currentContext,
        'POS database and in-memory state cleared.',
      );
    }
  }

  Future<void> _downloadLatestApk(BuildContext context) async {
    try {
      final currentContext = context;
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

      final svc =
          widget.updateServiceFactory?.call() ??
          UpdateService(owner: 'Giras91', repo: 'flutterpos');

      final choice = await showDialog<String>(
        context: currentContext,
        builder: (context) => AlertDialog(
          title: const Text('Download Update'),
          content: const Text('Would you like to open the APK after download?'),
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
              onPressed: () => Navigator.pop(context, 'download_open'),
              child: const Text('Download & Open'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel') {
        if (currentContext.mounted) {
          Navigator.of(currentContext).pop();
        }
        return;
      }

      final filePath = await svc.downloadLatestApk();

      Directory desktopPath;
      final home = Platform.environment['HOME'] ?? '';
      if (Platform.isWindows) {
        desktopPath = Directory(Platform.environment['USERPROFILE'] ?? '');
      } else {
        desktopPath = Directory('$home/Desktop');
      }
      if (!await desktopPath.exists()) {
        final downloads = Directory('$home/Downloads');
        if (await downloads.exists()) {
          desktopPath = downloads;
        } else {
          desktopPath = Directory(home);
        }
      }
      final file = File(filePath);
      final target = File('${desktopPath.path}/${file.uri.pathSegments.last}');
      try {
        await file.copy(target.path);
      } catch (e) {
        if (currentContext.mounted) {
          Navigator.of(currentContext).pop();
          final action = await showDialog<String>(
            context: currentContext,
            builder: (context) => AlertDialog(
              title: const Text('Unable to save file'),
              content: Text(
                'Failed to write APK to ${desktopPath.path}: $e\n\nYou can pick a different location or open the APK directly if supported.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('choose'),
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
              await File(fileSave.path).writeAsBytes(await file.readAsBytes());
              ToastHelper.showToast(
                currentContext,
                'Saved to ${fileSave.path}',
              );
            }
          } else if (action == 'open') {
            final openFn = widget.openFileFn ?? (path) => OpenFilex.open(path);
            await openFn(file.path);
          }
          return;
        }
      }

      if (currentContext.mounted) {
        Navigator.of(currentContext).pop();
        ToastHelper.showToast(
          currentContext,
          'Latest APK downloaded: ${target.path}',
        );
      }

      if (choice == 'download_open') {
        final openFn = widget.openFileFn ?? (path) => OpenFilex.open(path);
        try {
          await openFn(target.path);
        } catch (e) {
          if (currentContext.mounted) {
            ToastHelper.showToast(currentContext, 'Unable to open APK: $e');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ToastHelper.showToast(context, 'Update failed: $e');
      }
    }
  }

  Future<void> _handleClearTrainingData(BuildContext context) async {
    TrainingModeService.instance.clearTrainingData();
    try {
      await TrainingDataGenerator.instance.clearTrainingData();
      ToastHelper.showToast(context, 'Training data cleared');
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to clear training DB data: $e');
    }
  }

  Future<void> _handleResetSetup(BuildContext context) async {
    final currentContext = context;
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
                  onChanged: (v) => setState(() => backup = v ?? false),
                  title: const Text('Create backup before resetting'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: resetDb,
                  onChanged: (v) => setState(() => resetDb = v ?? false),
                  title: const Text('Also reset database to factory defaults'),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

    try {
      await ConfigService.instance.setSetupDone(false);
      await ConfigService.instance.setStoreName('');
    } catch (e) {
      if (currentContext.mounted) {
        ToastHelper.showToast(currentContext, 'Error clearing setup flag: $e');
      }
      return;
    }

    if (doBackup) {
      try {
        final backupPath = await DatabaseHelper.instance.backupDatabase();
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
        return;
      }
    }

    if (doResetDb) {
      try {
        await DatabaseHelper.instance.resetDatabase();
      } catch (e) {
        if (currentContext.mounted) {
          ToastHelper.showToast(currentContext, 'Error resetting database: $e');
        }
        return;
      }
    }

    ResetService.instance.triggerReset();
    if (context.mounted) {
      ToastHelper.showToast(
        context,
        'Setup cleared — showing Setup screen now',
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const SetupScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showTutorial(BuildContext context) async {
    await AppSettings.instance.resetTutorial();
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ToastHelper.showToast(context, 'Tutorial will show on next app start');
    }
  }

  void _showTrainingModeDialog(BuildContext context) {
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
                        onPressed: () => Navigator.pop(context, false),
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
                    await TrainingDataGenerator.instance.generateSampleItems();
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
                        onPressed: () => Navigator.pop(context, false),
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
                    await TrainingDataGenerator.instance.clearTrainingData();
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
  }

  void _showRequireDbProductsDialog(BuildContext context) {
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

  void _showPerformanceReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.speed, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Performance Report'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Metrics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _getPerformanceStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Error loading performance data: ${snapshot.error}',
                    );
                  }

                  final stats = snapshot.data ?? {};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPerformanceMetric(
                        'Data Loading',
                        '${stats['dataLoading'] ?? 'N/A'}',
                        'Time to load products and categories',
                      ),
                      _buildPerformanceMetric(
                        'Product Filtering',
                        '${stats['productFiltering'] ?? 'N/A'}',
                        'Time to filter products by category',
                      ),
                      _buildPerformanceMetric(
                        'Cart Operations',
                        '${stats['cartOperations'] ?? 'N/A'}',
                        'Time for cart add/remove operations',
                      ),
                      _buildPerformanceMetric(
                        'Memory Usage',
                        '${stats['memoryUsage'] ?? 'N/A'}',
                        'Current memory consumption',
                      ),
                      _buildPerformanceMetric(
                        'Cache Hit Rate',
                        '${stats['cacheHitRate'] ?? 'N/A'}',
                        'Percentage of cache hits vs misses',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Optimization Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildOptimizationStatus(
                        'Lazy Loading',
                        stats['lazyLoadingEnabled'] == true,
                        'Products loaded on demand',
                      ),
                      _buildOptimizationStatus(
                        'Memory Management',
                        stats['memoryManagementEnabled'] == true,
                        'Automatic resource cleanup',
                      ),
                      _buildOptimizationStatus(
                        'Widget Optimization',
                        stats['widgetOptimizationEnabled'] == true,
                        'Efficient list rendering',
                      ),
                      _buildOptimizationStatus(
                        'Image Caching',
                        stats['imageCachingEnabled'] == true,
                        'Optimized image loading',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateDetailedReport(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getPerformanceStats() async {
    try {
      // Get performance monitor stats
      final allStats = PerformanceMonitor.instance.getAllStats();
      final monitorStats = {
        'loadData': allStats['loadData']?.avgMs.toStringAsFixed(2) ?? 'N/A',
        'filterProducts':
            allStats['filterProducts']?.avgMs.toStringAsFixed(2) ?? 'N/A',
        'addToCart': allStats['addToCart']?.avgMs.toStringAsFixed(2) ?? 'N/A',
      };

      // Get lazy loading stats
      final lazyStats = LazyLoadingService.instance.getCacheStats();

      // Get memory manager stats
      final memoryStats = MemoryManager.instance.getMemoryStats();

      return {
        'dataLoading': '${monitorStats['loadData']}ms',
        'productFiltering': '${monitorStats['filterProducts']}ms',
        'cartOperations': '${monitorStats['addToCart']}ms',
        'memoryUsage': '${memoryStats['registered_resources']} resources',
        'cacheHitRate': '${lazyStats['product_cache_entries']} cached',
        'lazyLoadingEnabled': true,
        'memoryManagementEnabled': true,
        'widgetOptimizationEnabled': true,
        'imageCachingEnabled': true,
      };
    } catch (e) {
      return {'error': 'Failed to load performance data: $e'};
    }
  }

  Widget _buildPerformanceMetric(
    String label,
    String value,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationStatus(
    String feature,
    bool enabled,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _generateDetailedReport(BuildContext context) {
    // Trigger performance report generation
    PerformanceMonitor.instance.printReport();

    // Show confirmation
    ToastHelper.showToast(
      context,
      'Performance report generated. Check console for details.',
    );
  }
}

class SettingsItem {
  final String title;
  final IconData icon;
  final String? description;
  final VoidCallback onTap;

  const SettingsItem({
    required this.title,
    required this.icon,
    this.description,
    required this.onTap,
  });
}

class SettingsCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<SettingsItem> items;

  const SettingsCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class SettingsTileWidget extends StatelessWidget {
  final String title;
  final String? description;
  final String? subLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SettingsTileWidget({
    super.key,
    required this.title,
    this.description,
    this.subLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          hoverColor: const Color(0xFFEEF2FF),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (subLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subLabel!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
