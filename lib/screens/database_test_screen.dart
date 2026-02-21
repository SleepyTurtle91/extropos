import 'package:extropos/services/backup_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  String _status = 'Not initialized';
  final List<String> _logs = [];
  final BackupService _backupService = BackupService.instance;

  @override
  void initState() {
    super.initState();
    _initBackupService();
    _initDatabase();
  }

  Future<void> _initBackupService() async {
    try {
      await _backupService.initialize();
      _addLog('Backup service initialized');
    } catch (e) {
      _addLog('Backup service initialization failed: $e');
    }
  }

  Future<void> _initDatabase() async {
    try {
      setState(() {
        _status = 'Initializing...';
        _logs.clear();
      });

      _addLog('Starting database initialization...');

      final db = await DatabaseHelper.instance.database;
      _addLog('✓ Database opened successfully');

      // Test reading default data
      final businessInfo = await db.query('business_info');
      _addLog('✓ Business info loaded: ${businessInfo.length} record(s)');

      final users = await db.query('users');
      _addLog('✓ Users loaded: ${users.length} record(s)');

      final paymentMethods = await db.query('payment_methods');
      _addLog('✓ Payment methods loaded: ${paymentMethods.length} record(s)');

      final receiptSettings = await db.query('receipt_settings');
      _addLog('✓ Receipt settings loaded: ${receiptSettings.length} record(s)');

      // Test table counts
      final tables = [
        'business_info',
        'categories',
        'items',
        'users',
        'tables',
        'payment_methods',
        'printers',
        'orders',
        'order_items',
        'transactions',
        'receipt_settings',
        'inventory_adjustments',
        'cash_sessions',
        'discounts',
        'item_modifiers',
        'audit_log',
      ];

      _addLog('\nTable verification:');
      for (final table in tables) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $table',
          );
          final count = result.first['count'] as int;
          _addLog('  - $table: $count record(s)');
        } catch (e) {
          _addLog('  - $table: ERROR - $e');
        }
      }

      setState(() {
        _status = 'Database ready ✓';
      });
      _addLog('\n✓ Database initialization completed successfully!');
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      _addLog('✗ Error: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text(
          'Are you sure you want to reset the database?\n\n'
          'This will DELETE ALL DATA and recreate the database with default values.\n\n'
          'A backup will be created automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() {
          _status = 'Resetting...';
          _logs.clear();
        });

        _addLog('Creating backup before reset...');
        final backupResult = await DatabaseHelper.instance.safeResetDatabase();
        _addLog('✓ Database reset successfully');
        _addLog('Backup created: $backupResult');

        await _initDatabase();
      } catch (e) {
        setState(() {
          _status = 'Reset error: $e';
        });
        _addLog('✗ Reset error: $e');
      }
    }
  }

  Future<void> _backupDatabase() async {
    try {
      setState(() {
        _status = 'Creating backup...';
        _logs.clear();
      });

      _addLog('Creating database backup...');
      final backupPath = await DatabaseHelper.instance.backupDatabase();
      _addLog('✓ Backup created: $backupPath');

      // Show backup info
      final stats = await DatabaseHelper.instance.getDatabaseStats();
      _addLog('Total backups: ${stats['backup_count']}');

      setState(() {
        _status = 'Backup complete';
      });
    } catch (e) {
      setState(() {
        _status = 'Backup error: $e';
      });
      _addLog('✗ Backup error: $e');
    }
  }

  Future<void> _showRestoreDialog() async {
    final backups = await DatabaseHelper.instance.getBackupFiles();

    if (!mounted) return;

    if (backups.isEmpty) {
      ToastHelper.showToast(context, 'No backup files found');
      return;
    }

    final selectedBackup = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final backup = backups[index];
              final fileName = backup.split('\\').last;
              return ListTile(
                title: Text(fileName),
                subtitle: Text(backup),
                onTap: () => Navigator.pop(context, backup),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedBackup != null && mounted) {
      await _restoreFromBackup(selectedBackup);
    }
  }

  Future<void> _restoreFromBackup(String backupPath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Text(
          'Are you sure you want to restore from:\n\n${backupPath.split('\\').last}\n\n'
          'This will replace the current database and restart the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() {
          _status = 'Restoring from backup...';
          _logs.clear();
        });

        _addLog('Restoring from backup: ${backupPath.split('\\').last}');
        await DatabaseHelper.instance.restoreFromBackup(backupPath);
        _addLog('✓ Database restored successfully');

        // Restart the app by triggering a reset
        if (mounted) {
          ToastHelper.showToast(
            context,
            'Database restored. Please restart the app.',
          );
        }
      } catch (e) {
        setState(() {
          _status = 'Restore error: $e';
        });
        _addLog('✗ Restore error: $e');
      }
    }
  }

  Future<void> _showDatabaseStats() async {
    try {
      setState(() {
        _status = 'Loading stats...';
        _logs.clear();
      });

      final stats = await _backupService.getBackupStats();
      _addLog('=== Database & Backup Statistics ===');
      _addLog('Database Path: ${stats['database_path']}');
      _addLog('Database Exists: ${stats['exists']}');
      _addLog('Database Size: ${stats['size_mb'].toStringAsFixed(2)} MB');
      _addLog('Last Modified: ${stats['last_modified']}');
      _addLog('Local Backups: ${stats['backup_count']}');

      if (stats['cloud_available'] == true) {
        _addLog('Cloud Backup Available: Yes (Android)');
        _addLog('Cloud Signed In: ${stats['cloud_signed_in']}');
        if (stats['cloud_signed_in'] == true) {
          _addLog(
            'Cloud User: ${stats['cloud_user_name']} (${stats['cloud_user_email']})',
          );
          _addLog('Cloud Backups: ${stats['cloud_backup_count']}');
        }
      } else {
        _addLog('Cloud Backup Available: No (Windows/Local only)');
      }

      setState(() {
        _status = 'Stats loaded';
      });
    } catch (e) {
      setState(() {
        _status = 'Stats error: $e';
      });
      _addLog('✗ Stats error: $e');
    }
  }

  Future<void> _insertTestData() async {
    try {
      setState(() {
        _status = 'Inserting test data...';
      });

      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      // Insert test category
      await db.insert('categories', {
        'id': 'test-cat-1',
        'name': 'Test Category',
        'description': 'Test category description',
        'icon_code_point': Icons.category.codePoint,
        'icon_font_family': Icons.category.fontFamily,
        'color_value': const Color(0xFF2196F3).toARGB32(),
        'sort_order': 1,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
      _addLog('✓ Inserted test category');

      // Insert test item
      await db.insert('items', {
        'id': 'test-item-1',
        'name': 'Test Item',
        'description': 'Test item description',
        'price': 9.99,
        'category_id': 'test-cat-1',
        'icon_code_point': Icons.shopping_bag.codePoint,
        'icon_font_family': Icons.shopping_bag.fontFamily,
        'color_value': const Color(0xFF4CAF50).toARGB32(),
        'is_available': 1,
        'is_featured': 0,
        'stock': 100,
        'track_stock': 1,
        'sort_order': 1,
        'created_at': now,
        'updated_at': now,
      });
      _addLog('✓ Inserted test item');

      setState(() {
        _status = 'Test data inserted ✓';
      });

      await _initDatabase();
    } catch (e) {
      setState(() {
        _status = 'Insert error: $e';
      });
      _addLog('✗ Insert error: $e');
    }
  }

  Future<void> _insertSampleOrders() async {
    try {
      setState(() {
        _status = 'Inserting sample orders...';
      });

      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();

      // Create sample orders for the last 30 days
      for (int i = 0; i < 30; i++) {
        final orderDate = now.subtract(Duration(days: i));
        final orderId = 'sample-order-${i + 1}';

        // Insert order
        await db.insert('orders', {
          'id': orderId,
          'user_id': 'admin', // Assuming admin user exists
          'total_amount': (10.0 + (i % 5) * 5.0), // Varying amounts
          'tax_amount': (10.0 + (i % 5) * 5.0) * 0.1,
          'discount': i % 3 == 0 ? 2.0 : 0.0, // Some orders have discounts
          'status': 'completed',
          'payment_method_id': i % 2 == 0 ? 'cash' : 'card',
          'customer_name': i % 4 == 0 ? 'John Doe' : null,
          'customer_phone': i % 4 == 0 ? '+1234567890' : null,
          'created_at': orderDate.toIso8601String(),
          'updated_at': orderDate.toIso8601String(),
        });

        // Insert order items
        final itemCount = 1 + (i % 3); // 1-3 items per order
        for (int j = 0; j < itemCount; j++) {
          await db.insert('order_items', {
            'id': 'sample-order-item-${i + 1}-${j + 1}',
            'order_id': orderId,
            'item_id': 'test-item-1', // Use the test item we created
            'quantity': 1 + (j % 2), // 1 or 2 quantity
            'price': 9.99,
            'subtotal': (1 + (j % 2)) * 9.99,
            'created_at': orderDate.toIso8601String(),
          });
        }
      }

      _addLog('✓ Inserted 30 sample orders with items');

      setState(() {
        _status = 'Sample orders inserted ✓';
      });

      await _initDatabase();
    } catch (e) {
      setState(() {
        _status = 'Insert error: $e';
      });
      _addLog('✗ Insert error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _status.contains('Error') || _status.contains('error')
                ? Colors.red.shade50
                : _status.contains('✓')
                ? Colors.green.shade50
                : Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        _status.contains('Error') || _status.contains('error')
                        ? Colors.red.shade700
                        : _status.contains('✓')
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _initDatabase,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _backupDatabase,
                        icon: const Icon(Icons.backup),
                        label: const Text('Backup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showRestoreDialog,
                        icon: const Icon(Icons.restore_page),
                        label: const Text('Restore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _insertTestData,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Test Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _insertSampleOrders,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Add Sample Orders'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showDatabaseStats,
                        icon: const Icon(Icons.info),
                        label: const Text('Stats'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _resetDatabase,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset DB'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.startsWith('✗');
                final isSuccess = log.startsWith('✓');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: isError
                          ? Colors.red.shade700
                          : isSuccess
                          ? Colors.green.shade700
                          : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
