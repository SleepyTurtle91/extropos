import 'package:extropos/services/test_database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class TestDatabaseScreen extends StatefulWidget {
  const TestDatabaseScreen({super.key});

  @override
  State<TestDatabaseScreen> createState() => _TestDatabaseScreenState();
}

class _TestDatabaseScreenState extends State<TestDatabaseScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    final testService = TestDatabaseService.instance;
    if (testService.isTestMode) {
      _statusMessage = 'Currently using TEST database';
    } else {
      _statusMessage = 'Currently using PRODUCTION database';
    }
    setState(() {});
  }

  Future<void> _executeAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isLoading = true);
    try {
      await action();
      ToastHelper.showToast(context, successMessage);
      _updateStatus();
    } catch (e) {
      ToastHelper.showToast(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final testService = TestDatabaseService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Database Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: testService.isTestMode
                  ? Colors.orange[50]
                  : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      testService.isTestMode
                          ? Icons.warning
                          : Icons.check_circle,
                      color: testService.isTestMode
                          ? Colors.orange
                          : Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: testService.isTestMode
                              ? Colors.orange[800]
                              : Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Database Mode Section
            _buildSection(
              title: 'Database Mode',
              children: [
                _buildActionButton(
                  title: 'Switch to Test Database',
                  subtitle: 'Use isolated test database with sample data',
                  icon: Icons.switch_left,
                  color: Colors.blue,
                  onPressed: () => _executeAction(
                    testService.switchToTestDatabase,
                    'Switched to test database',
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  title: 'Switch to Production Database',
                  subtitle: 'Use main production database',
                  icon: Icons.switch_right,
                  color: Colors.green,
                  onPressed: () => _executeAction(
                    testService.switchToProductionDatabase,
                    'Switched to production database',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Test Data Management Section
            _buildSection(
              title: 'Test Data Management',
              children: [
                _buildActionButton(
                  title: 'Populate Test Data',
                  subtitle: 'Add comprehensive sample data to test database',
                  icon: Icons.add_circle,
                  color: Colors.purple,
                  onPressed: () => _executeAction(
                    testService.populateTestData,
                    'Test data populated successfully',
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  title: 'Clear Test Data',
                  subtitle: 'Remove all data from test database',
                  icon: Icons.clear_all,
                  color: Colors.red,
                  onPressed: () => _executeAction(
                    testService.clearTestData,
                    'Test data cleared',
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  title: 'Reset Test Database',
                  subtitle: 'Clear and repopulate test database',
                  icon: Icons.refresh,
                  color: Colors.orange,
                  onPressed: () => _executeAction(
                    testService.resetTestDatabase,
                    'Test database reset successfully',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Database File Management Section
            _buildSection(
              title: 'Database File Management',
              children: [
                _buildActionButton(
                  title: 'Delete Test Database',
                  subtitle: 'Permanently delete test database file',
                  icon: Icons.delete_forever,
                  color: Colors.red[700]!,
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Database Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Purpose', 'Isolated testing environment'),
                    _buildInfoRow(
                      'Data',
                      'Sample categories, items, users, tables',
                    ),
                    _buildInfoRow('Safety', 'No impact on production data'),
                    _buildInfoRow(
                      'Location',
                      'flutterpos_test.db in app documents',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '💡 Tip: Use test database for development, training, and feature testing without affecting real business data.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: _isLoading ? null : onPressed,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test Database'),
        content: const Text(
          'This will permanently delete the test database file and all its data. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _executeAction(
                TestDatabaseService.instance.deleteTestDatabase,
                'Test database deleted',
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
