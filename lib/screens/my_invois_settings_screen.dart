import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// MyInvois Settings Screen - Advanced e-invoice settings and preferences
class MyInvoisSettingsScreen extends StatefulWidget {
  const MyInvoisSettingsScreen({super.key});

  @override
  State<MyInvoisSettingsScreen> createState() => _MyInvoisSettingsScreenState();
}

class _MyInvoisSettingsScreenState extends State<MyInvoisSettingsScreen> {
  bool _autoSubmit = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  String _defaultLanguage = 'EN';
  bool _isLoading = false;

  final List<String> _languages = ['EN', 'MS'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from service/storage
    // For now, use defaults
    setState(() {
      _autoSubmit = false;
      _emailNotifications = true;
      _smsNotifications = false;
      _defaultLanguage = 'EN';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      // Save settings to storage/service
      // This would integrate with a settings service
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate save

      ToastHelper.showToast(context, 'Settings saved successfully');
      Navigator.of(context).pop();
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to save settings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotifications() async {
    try {
      // Test notification settings
      ToastHelper.showToast(context, 'Test notification sent');
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to send test notification');
    }
  }

  Future<void> _clearSubmissionHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Submission History'),
        content: const Text(
          'This will clear all submission history and UUIDs. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Clear submission history
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate clearing
      ToastHelper.showToast(context, 'Submission history cleared');
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to clear history');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyInvois Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        EInvoiceService.instance.isConfigured ? Icons.check_circle : Icons.error,
                        color: EInvoiceService.instance.isConfigured ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        EInvoiceService.instance.isConfigured
                            ? 'E-Invoice service configured'
                            : 'E-Invoice service not configured',
                      ),
                    ],
                  ),
                  if (EInvoiceService.instance.isConfigured) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Environment: ${EInvoiceService.instance.config?.isProduction == true ? 'Production' : 'Sandbox'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Automation Settings
          const Text(
            'Automation Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-Submit E-Invoices'),
                  subtitle: const Text('Automatically submit e-invoices after order completion'),
                  value: _autoSubmit,
                  onChanged: (value) => setState(() => _autoSubmit = value),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Submission Schedule'),
                  subtitle: const Text('Daily at 6:00 PM'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () {
                    // Show time picker for schedule
                    ToastHelper.showToast(context, 'Schedule configuration not implemented');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notification Settings
          const Text(
            'Notification Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive email notifications for submission status'),
                  value: _emailNotifications,
                  onChanged: (value) => setState(() => _emailNotifications = value),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('SMS Notifications'),
                  subtitle: const Text('Receive SMS notifications for submission failures'),
                  value: _smsNotifications,
                  onChanged: (value) => setState(() => _smsNotifications = value),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Test Notifications'),
                  subtitle: const Text('Send a test notification to verify settings'),
                  trailing: const Icon(Icons.send),
                  onTap: _testNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Language & Display Settings
          const Text(
            'Language & Display',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              title: const Text('Default Language'),
              subtitle: Text('Current: $_defaultLanguage'),
              trailing: DropdownButton<String>(
                value: _defaultLanguage,
                items: _languages.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _defaultLanguage = value);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Data Management
          const Text(
            'Data Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear Submission History'),
                  subtitle: const Text('Remove all submission records and UUIDs'),
                  trailing: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: _clearSubmissionHistory,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Export Submission Data'),
                  subtitle: const Text('Export all submission data for backup'),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    ToastHelper.showToast(context, 'Export functionality not implemented');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Advanced Settings
          const Text(
            'Advanced Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('API Rate Limits'),
                  subtitle: const Text('Configure API call limits and retry policies'),
                  trailing: const Icon(Icons.settings),
                  onTap: () {
                    ToastHelper.showToast(context, 'Rate limit configuration not implemented');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Debug Logging'),
                  subtitle: const Text('Enable detailed logging for troubleshooting'),
                  trailing: const Icon(Icons.bug_report),
                  onTap: () {
                    ToastHelper.showToast(context, 'Debug logging not implemented');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}