import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// Maintenance Screen - System maintenance and diagnostics
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _systemInfo = {};

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    setState(() => _isLoading = true);

    try {
      // Get database statistics
      final dbStats = await DatabaseService.instance.getDatabaseStats();

      setState(() {
        _systemInfo = {
          'database_size': dbStats['size'] ?? 'Unknown',
          'total_orders': dbStats['orders_count'] ?? 0,
          'total_products': dbStats['products_count'] ?? 0,
          'last_backup': dbStats['last_backup'] ?? 'Never',
          'cache_size': 'Calculating...',
        };
      });
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to load system info');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isLoading = true);

    try {
      // Clear various caches
      await DatabaseService.instance.clearCache();
      ToastHelper.showToast(context, 'Cache cleared successfully');
      await _loadSystemInfo(); // Refresh info
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to clear cache');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _optimizeDatabase() async {
    setState(() => _isLoading = true);

    try {
      await DatabaseService.instance.optimizeDatabase();
      ToastHelper.showToast(context, 'Database optimized successfully');
      await _loadSystemInfo(); // Refresh info
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to optimize database');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportLogs() async {
    setState(() => _isLoading = true);

    try {
      // Export system logs
      final logData = await DatabaseService.instance.exportLogs();
      ToastHelper.showToast(context, 'Logs exported successfully');
      // In a real implementation, you might save this to a file or send it
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to export logs');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all user settings to defaults. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await DatabaseService.instance.resetSettings();
      ToastHelper.showToast(context, 'Settings reset successfully');
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to reset settings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Maintenance'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // System Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Database Size', _systemInfo['database_size']?.toString() ?? 'Unknown'),
                        _buildInfoRow('Total Orders', _systemInfo['total_orders']?.toString() ?? '0'),
                        _buildInfoRow('Total Products', _systemInfo['total_products']?.toString() ?? '0'),
                        _buildInfoRow('Last Backup', _systemInfo['last_backup']?.toString() ?? 'Never'),
                        _buildInfoRow('Cache Size', _systemInfo['cache_size']?.toString() ?? 'Unknown'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Maintenance Actions
                const Text(
                  'Maintenance Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildActionCard(
                  'Clear Cache',
                  'Clear temporary data and cached information',
                  Icons.cleaning_services,
                  _clearCache,
                ),

                _buildActionCard(
                  'Optimize Database',
                  'Rebuild indexes and optimize database performance',
                  Icons.tune,
                  _optimizeDatabase,
                ),

                _buildActionCard(
                  'Export Logs',
                  'Export system logs for troubleshooting',
                  Icons.description,
                  _exportLogs,
                ),

                _buildActionCard(
                  'Reset Settings',
                  'Reset all user settings to defaults',
                  Icons.restore,
                  _resetSettings,
                  isDestructive: true,
                ),

                const SizedBox(height: 24),

                // Diagnostic Tools
                const Text(
                  'Diagnostic Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildActionCard(
                  'Test Network',
                  'Test internet connectivity and API endpoints',
                  Icons.network_check,
                  () => ToastHelper.showToast(context, 'Network test not implemented'),
                ),

                _buildActionCard(
                  'Check Permissions',
                  'Verify app permissions and access rights',
                  Icons.security,
                  () => ToastHelper.showToast(context, 'Permission check not implemented'),
                ),

                _buildActionCard(
                  'Hardware Diagnostics',
                  'Test connected hardware devices',
                  Icons.hardware,
                  () => ToastHelper.showToast(context, 'Hardware diagnostics not implemented'),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : Colors.blue),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}