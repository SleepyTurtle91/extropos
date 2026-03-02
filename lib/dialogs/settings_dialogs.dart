import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/lazy_loading_service.dart';
import 'package:extropos/services/memory_manager.dart';
import 'package:extropos/services/performance_monitor.dart';
import 'package:extropos/services/training_data_generator.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class SettingsDialogs {
  static void showTrainingModeDialog(BuildContext context) {
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
              builder: (context, child) => SwitchListTile(
                title: const Text('Enable Training Mode'),
                value: AppSettings.instance.isTrainingMode,
                onChanged: (value) =>
                    AppSettings.instance.setTrainingMode(value),
              ),
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
                    if (context.mounted)
                      ToastHelper.showToast(
                        context,
                        'Training data loaded successfully',
                      );
                  } catch (e) {
                    if (context.mounted)
                      ToastHelper.showToast(
                        context,
                        'Error loading training data: $e',
                      );
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
                    if (context.mounted)
                      ToastHelper.showToast(
                        context,
                        'Training data cleared successfully',
                      );
                  } catch (e) {
                    if (context.mounted)
                      ToastHelper.showToast(
                        context,
                        'Error clearing training data: $e',
                      );
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

  static void showRequireDbProductsDialog(BuildContext context) {
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
              builder: (context, child) => SwitchListTile(
                title: const Text('Enforce DB-only products'),
                value: AppSettings.instance.requireDbProducts,
                onChanged: (v) => AppSettings.instance.setRequireDbProducts(v),
              ),
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

  static void showUserGuideDialog(BuildContext context) {
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

  static Widget _buildGuideSection(
    String title,
    IconData icon,
    List<String> points,
  ) {
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

  static void showPerformanceReportDialog(BuildContext context) {
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
                  if (snapshot.hasError)
                    return Text(
                      'Error loading performance data: ${snapshot.error}',
                    );
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

  static Future<Map<String, dynamic>> _getPerformanceStats() async {
    try {
      final allStats = PerformanceMonitor.instance.getAllStats();
      final monitorStats = {
        'loadData': allStats['loadData']?.avgMs.toStringAsFixed(2) ?? 'N/A',
        'filterProducts':
            allStats['filterProducts']?.avgMs.toStringAsFixed(2) ?? 'N/A',
        'addToCart': allStats['addToCart']?.avgMs.toStringAsFixed(2) ?? 'N/A',
      };
      final lazyStats = LazyLoadingService.instance.getCacheStats();
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

  static Widget _buildPerformanceMetric(
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

  static Widget _buildOptimizationStatus(
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

  static void _generateDetailedReport(BuildContext context) {
    PerformanceMonitor.instance.printReport();
    ToastHelper.showToast(
      context,
      'Performance report generated. Check console for details.',
    );
  }
}
