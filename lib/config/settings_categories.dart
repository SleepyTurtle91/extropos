import 'package:extropos/screens/business_info_screen.dart';
import 'package:extropos/screens/categories_management_screen.dart';
import 'package:extropos/screens/customers_management_screen.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/modifier_groups_management_screen.dart';
import 'package:extropos/screens/payment_methods_management_screen.dart';
import 'package:extropos/screens/printers_management_screen.dart';
import 'package:extropos/screens/refund_screen.dart';
import 'package:extropos/screens/roles_management_screen.dart';
import 'package:extropos/screens/sales_history_screen.dart';
import 'package:extropos/screens/tables_management_screen.dart';
import 'package:extropos/screens/users_management_screen.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

class SettingsCategoriesBuilder {
  static List<SettingsCategory> buildCategories(
    BuildContext context,
    Map<String, String> appInfo,
    TrainingModeService trainingService, {
    required VoidCallback onShowTutorial,
    required VoidCallback onShowTrainingModeDialog,
    required VoidCallback onShowUserGuideDialog,
    required VoidCallback onShowRequireDbProductsDialog,
    required VoidCallback onShowPerformanceReportDialog,
    required VoidCallback onDownloadLatestApk,
    required VoidCallback onCheckForUpdates,
    required VoidCallback onResetPos,
    required VoidCallback onClearTrainingData,
    required VoidCallback onResetSetup,
  }) {
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrintersManagementScreen(),
              ),
            ),
          ),
          // TODO: Implement printer integration screen
          // SettingsItem(
          //   title: 'Printer Integration',
          //   icon: Icons.receipt_long,
          //   description: 'Thermal printer + PDF print tools',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const ThermalPrinterIntegrationScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement dual display settings screen
          // SettingsItem(
          //   title: 'Dual Display Settings',
          //   icon: Icons.monitor,
          //   description: 'Configure customer display for IMIN hardware',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const DualDisplaySettingsScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement customer displays management screen
          // SettingsItem(
          //   title: 'Customer Displays',
          //   icon: Icons.desktop_windows,
          //   description: 'Manage customer facing displays',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const CustomerDisplaysManagementScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement P2P management screen
          // SettingsItem(
          //   title: 'P2P Network Setup',
          //   icon: Icons.device_hub,
          //   description: 'Configure server/client P2P connections',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const P2PManagementScreen(),
          //     ),
          //   ),
          // ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UsersManagementScreen(),
              ),
            ),
          ),
          SettingsItem(
            title: 'Customers Management',
            icon: Icons.group,
            description: 'Manage customer database and loyalty',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomersManagementScreen(),
              ),
            ),
          ),
          SettingsItem(
            title: 'Roles Management',
            icon: Icons.security,
            description: 'Configure role permissions and access levels',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RolesManagementScreen(),
              ),
            ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoriesManagementScreen(),
              ),
            ),
          ),
          SettingsItem(
            title: 'Items Management',
            icon: Icons.inventory,
            description: 'Add and manage products',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ItemsManagementScreen(),
              ),
            ),
          ),
          SettingsItem(
            title: 'Modifier Groups',
            icon: Icons.tune,
            description: 'Manage product modifiers and options',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModifierGroupsManagementScreen(),
              ),
            ),
          ),
          // TODO: Implement refund processing screen
          // SettingsItem(
          //   title: 'Refunds & Returns',
          //   icon: Icons.undo,
          //   description: 'Process customer refunds and returns',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (context) => const RefundScreen()),
          //   ),
          // ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TablesManagementScreen(),
              ),
            ),
          ),
          // TODO: Implement kitchen display system
          // SettingsItem(
          //   title: 'Kitchen Display System',
          //   icon: Icons.restaurant,
          //   description: 'Monitor and manage kitchen orders',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const KitchenDisplayScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement order queue display
          // SettingsItem(
          //   title: 'Cafe Order Queue Display',
          //   icon: Icons.monitor,
          //   description: 'Customer-facing order status display',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (context) => const OrderQueueScreen()),
          //   ),
          // ),
        ],
      ),
      // TODO: Implement appearance settings
      // SettingsCategory(
      //   id: 'appearance',
      //   title: 'Appearance',
      //   icon: Icons.palette,
      //   color: const Color(0xFF8B5CF6),
      //   items: [
      //     SettingsItem(
      //       title: 'Theme & Color Scheme',
      //       icon: Icons.palette,
      //       description: 'Customize app colors and appearance',
      //       onTap: () => Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) => const ThemeSettingsScreen(),
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
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
              if (context.mounted)
                ToastHelper.showToast(
                  context,
                  nextValue
                      ? 'Training mode enabled'
                      : 'Training mode disabled',
                );
            },
          ),
          SettingsItem(
            title: 'Business Information',
            icon: Icons.business,
            description: 'Store name, address, tax settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BusinessInfoScreen(),
              ),
            ),
          ),
          SettingsItem(
            title: 'Software Activation',
            icon: Icons.vpn_key,
            description: 'Enter license key to unlock full features',
            onTap: () => Navigator.pushNamed(context, '/activation'),
          ),
          SettingsItem(
            title: 'Payment Methods',
            icon: Icons.attach_money,
            description: 'Configure payment options',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentMethodsManagementScreen(),
              ),
            ),
          ),
          // TODO: Implement e-wallet settings
          // SettingsItem(
          //   title: 'E-Wallet Settings',
          //   icon: Icons.qr_code_2,
          //   description: 'Enable and configure QR payments',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const EWalletSettingsScreen(),
          //     ),
          //   ),
          // ),
          SettingsItem(
            title: 'Sales History',
            icon: Icons.history,
            description: 'View recent orders and transactions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesHistoryScreen(),
              ),
            ),
          ),
          SettingsItem(
            title: 'Refunds & Returns',
            icon: Icons.undo,
            description: 'Process customer refunds and returns',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RefundScreen(),
              ),
            ),
          ),
          // TODO: Implement receipt settings screen
          // SettingsItem(
          //   title: 'Receipt Settings',
          //   icon: Icons.receipt_long,
          //   description: 'Customize receipt layout and footer',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const ReceiptSettingsScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement MyInvois integration
          // SettingsItem(
          //   title: 'e-Invoice (Malaysia)',
          //   icon: Icons.description,
          //   description: 'MyInvois integration for Malaysian tax compliance',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const MyInvoisSettingsScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement MyInvois queue management
          // SettingsItem(
          //   title: 'MyInvois Queue',
          //   icon: Icons.sync_problem,
          //   description: 'Manage failed e-invoice submissions and retry',
          //   onTap: () => Navigator.pushNamed(context, '/myinvois-queue'),
          // ),
          SettingsItem(
            title: 'Reset POS',
            icon: Icons.refresh,
            description: 'Clear all POS data (optional backup before reset)',
            onTap: onResetPos,
          ),
          SettingsItem(
            title: 'Check for Updates',
            icon: Icons.system_update,
            description: 'Download latest APK from GitHub releases',
            onTap: onDownloadLatestApk,
          ),
          SettingsItem(
            title: 'Clear Training Data',
            icon: Icons.school,
            description:
                'Clear temporary training transactions and sample data',
            onTap: onClearTrainingData,
          ),
          SettingsItem(
            title: 'Reset Setup',
            icon: Icons.restart_alt,
            description: 'Return to first-run setup (clears store name)',
            onTap: onResetSetup,
          ),
          // TODO: Implement advanced reports
          // SettingsItem(
          //   title: 'Advanced Reports',
          //   icon: Icons.analytics,
          //   description:
          //       'Sales analytics, product performance, and business insights',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const AdvancedReportsScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement analytics dashboard
          // SettingsItem(
          //   title: 'Analytics Dashboard',
          //   icon: Icons.dashboard,
          //   description: 'Interactive charts and real-time sales analytics',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const AnalyticsDashboardScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement employee performance tracking
          // SettingsItem(
          //   title: 'Employee Performance',
          //   icon: Icons.people_outline,
          //   description: 'Track sales, commissions, shifts, and leaderboards',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const EmployeePerformanceScreen(),
          //     ),
          //   ),
          // ),
          // TODO: Implement debug tools for development
          // if (kDebugMode)
          //   SettingsItem(
          //     title: 'Debug Tools',
          //     icon: Icons.bug_report,
          //     description: 'Developer tools for debugging hardware & plugins',
          //     onTap: () => Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const DebugToolsScreen(),
          //       ),
          //     ),
          //   ),
          // TODO: Implement test data generation
          // if (kDebugMode)
          //   SettingsItem(
          //     title: 'Generate Test Data',
          //     icon: Icons.data_usage,
          //     description: 'Create realistic sales data for testing reports',
          //     onTap: () => Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const GenerateTestDataScreen(),
          //       ),
          //     ),
          //   ),
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
            onTap: onShowTutorial,
          ),
          SettingsItem(
            title: 'Training Mode',
            icon: Icons.school,
            description: AppSettings.instance.isTrainingMode
                ? 'Currently enabled'
                : 'Currently disabled',
            onTap: onShowTrainingModeDialog,
          ),
          SettingsItem(
            title: 'User Guide',
            icon: Icons.book,
            description: 'Learn how to use ExtroPOS',
            onTap: onShowUserGuideDialog,
          ),
          SettingsItem(
            title: 'Require DB Products',
            icon: Icons.block,
            description: 'Prevent adding products not present in the database',
            onTap: onShowRequireDbProductsDialog,
          ),
        ],
      ),
      SettingsCategory(
        id: 'developer',
        title: 'Developer',
        icon: Icons.code,
        color: const Color(0xFFDB2777),
        items: [
          // TODO: Implement database testing tools
          // SettingsItem(
          //   title: 'Database Test',
          //   icon: Icons.storage,
          //   description: 'Test and verify database functionality',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const DatabaseTestScreen(),
          //     ),
          //   ),
          // ),
          SettingsItem(
            title: 'Performance Report',
            icon: Icons.speed,
            description: 'View app performance metrics and optimization data',
            onTap: onShowPerformanceReportDialog,
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
            onTap: () => showAboutDialog(
              context: context,
              applicationName: appInfo['appName'],
              applicationVersion:
                  'v${appInfo['version']} (Build ${appInfo['buildNumber']})',
              applicationIcon: const Icon(
                Icons.store,
                size: 48,
                color: Color(0xFF2563EB),
              ),
              children: const [
                Text(
                  'A modern point-of-sale system for retail, cafe, and restaurant businesses.',
                ),
                SizedBox(height: 16),
                Text(
                  'Features:\n• Multi-mode support (Retail, Cafe, Restaurant)\n• iMin device compatibility\n• Encrypted PIN storage\n• Dual display support\n• Advanced reporting\n• Thermal receipt printing',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          SettingsItem(
            title: 'Changelog',
            icon: Icons.history,
            description: 'View version history and recent changes',
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Changelog'),
                content: const Text('Changelog functionality will be implemented in a future update.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
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
                if (context.mounted)
                  ToastHelper.showToast(
                    context,
                    'Could not launch privacy policy',
                  );
              }
            },
          ),
          SettingsItem(
            title: 'Check for Updates',
            icon: Icons.system_update,
            description: 'Download latest version from GitHub',
            onTap: onCheckForUpdates,
          ),
        ],
      ),
    ];
  }
}
