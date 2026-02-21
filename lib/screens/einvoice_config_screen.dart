import 'package:extropos/models/einvoice/einvoice_config.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/services/myinvois_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// e-Invoice Configuration Screen
/// Allows users to configure MyInvois credentials for Malaysian e-Invoice
class EInvoiceConfigScreen extends StatefulWidget {
  const EInvoiceConfigScreen({super.key});

  @override
  State<EInvoiceConfigScreen> createState() => _EInvoiceConfigScreenState();
}

class _EInvoiceConfigScreenState extends State<EInvoiceConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _einvoiceService = EInvoiceService.instance;
  final _myinvoisService = MyInvoisService.instance;

  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;
  late TextEditingController _tinController;
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _businessEmailController;

  bool _isEnabled = false;
  bool _isProduction = false;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscureSecret = true;
  bool? _testPassed;
  String? _testStatus;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    final config = _einvoiceService.config ?? EInvoiceConfig.sandbox();

    _clientIdController = TextEditingController(text: config.clientId);
    _clientSecretController = TextEditingController(text: config.clientSecret);
    _tinController = TextEditingController(text: config.tin);
    _businessNameController = TextEditingController(text: config.businessName);
    _businessAddressController = TextEditingController(
      text: config.businessAddress,
    );
    _businessPhoneController = TextEditingController(
      text: config.businessPhone,
    );
    _businessEmailController = TextEditingController(
      text: config.businessEmail,
    );

    _isEnabled = config.isEnabled;
    _isProduction = config.isProduction;
    _testPassed = null;
    _testStatus = null;
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _tinController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      // Save config temporarily for testing
      final testConfig = _buildConfig();
      await _einvoiceService.saveConfig(testConfig);

      // Test authentication
      final success = await _einvoiceService.testConnection();

      if (!mounted) return;

      if (success) {
        _testPassed = true;
        _testStatus = 'Connection successful. Token acquired.';
        ToastHelper.showToast(context, '✓ Connection successful');
      } else {
        _testPassed = false;
        _testStatus = 'Connection failed. Check credentials or environment.';
        ToastHelper.showToast(context, '✗ Connection failed');
      }
    } catch (e) {
      if (!mounted) return;
      _testPassed = false;
      _testStatus = 'Connection error: ${e.toString()}';
      ToastHelper.showToast(context, 'Connection error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final config = _buildConfig();
      await _einvoiceService.saveConfig(config);

      if (!mounted) return;
      ToastHelper.showToast(context, 'e-Invoice configuration saved');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Failed to save: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  EInvoiceConfig _buildConfig() {
    return EInvoiceConfig(
      clientId: _clientIdController.text.trim(),
      clientSecret: _clientSecretController.text.trim(),
      tin: _tinController.text.trim(),
      businessName: _businessNameController.text.trim(),
      businessAddress: _businessAddressController.text.trim(),
      businessPhone: _businessPhoneController.text.trim(),
      businessEmail: _businessEmailController.text.trim(),
      identityServiceUrl: _isProduction
          ? 'https://api.myinvois.hasil.gov.my'
          : 'https://preprod-api.myinvois.hasil.gov.my',
      apiServiceUrl: _isProduction
          ? 'https://api.myinvois.hasil.gov.my'
          : 'https://preprod-api.myinvois.hasil.gov.my',
      isProduction: _isProduction,
      isEnabled: _isEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('e-Invoice Configuration'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final columnWidth = isWide
                    ? (constraints.maxWidth - 32) / 2
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: columnWidth,
                          child: _buildOverviewCard(),
                        ),
                        SizedBox(
                          width: columnWidth,
                          child: _buildEnvironmentCard(),
                        ),
                        SizedBox(
                          width: columnWidth,
                          child: _buildCredentialsCard(),
                        ),
                        SizedBox(
                          width: columnWidth,
                          child: _buildBusinessCard(),
                        ),
                        SizedBox(
                          width: columnWidth,
                          child: _buildActionsCard(),
                        ),
                        SizedBox(
                          width: columnWidth,
                          child: _buildHelpCard(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isProduction ? 'Production' : 'Sandbox',
                    style: TextStyle(
                      color: _isProduction
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      color:
                          _isEnabled ? Colors.green.shade700 : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'MyInvois e-Invoice for Malaysia',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Provide MyInvois Client ID/Secret, TIN, and business profile. Use Sandbox for testing and switch to Production when ready.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable e-Invoice'),
              subtitle: const Text('Automatically submit invoices to MyInvois'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
              activeColor: const Color(0xFF2563EB),
            ),
            if (_testStatus != null) ...[
              const Divider(),
              Row(
                children: [
                  Icon(
                    _testPassed == true
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: _testPassed == true ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testStatus!,
                      style: TextStyle(
                        color: _testPassed == true ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    final identityUrl = _isProduction
        ? 'https://api.myinvois.hasil.gov.my'
        : 'https://preprod-api.myinvois.hasil.gov.my';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Sandbox (Testing)'),
                  icon: Icon(Icons.science),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Production'),
                  icon: Icon(Icons.verified),
                ),
              ],
              selected: {_isProduction},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => _isProduction = selection.first);
              },
            ),
            const SizedBox(height: 16),
            _readonlyField(
              label: 'Identity Service URL',
              value: identityUrl,
            ),
            const SizedBox(height: 12),
            _readonlyField(
              label: 'API Service URL',
              value: identityUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MyInvois Credentials',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'Client ID *',
                hintText: 'From MyInvois portal (Client ID)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Client ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientSecretController,
              obscureText: _obscureSecret,
              decoration: InputDecoration(
                labelText: 'Client Secret *',
                hintText: 'From MyInvois portal (Client Secret)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSecret ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureSecret = !_obscureSecret);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Client Secret is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: Use Sandbox credentials for testing (environment auto-applies headers).',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tinController,
              decoration: const InputDecoration(
                labelText: 'Tax Identification Number (TIN) *',
                hintText: 'e.g., C1234567890',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'TIN is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                hintText: 'Registered business name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessAddressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Business Address *',
                hintText: 'Full registered address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessPhoneController,
              decoration: const InputDecoration(
                labelText: 'Business Phone',
                hintText: '+60123456789',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessEmailController,
              decoration: const InputDecoration(
                labelText: 'Business Email',
                hintText: 'contact@business.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_protected_setup),
                    label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Configuration'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Testing will request a token from ${_isProduction ? 'Production' : 'Sandbox'} and report success or failure.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showSystemDiagnostics,
              icon: const Icon(Icons.bug_report),
              label: const Text('System Diagnostics'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show comprehensive system diagnostics dialog
  Future<void> _showSystemDiagnostics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Running diagnostics...'),
          ],
        ),
      ),
    );

    try {
      final health = await _myinvoisService.getSystemHealth();
      final info = _myinvoisService.getServiceInfo();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                health['overallStatus'] == 'HEALTHY'
                    ? Icons.check_circle
                    : Icons.warning,
                color: health['overallStatus'] == 'HEALTHY'
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text('System Diagnostics'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDiagnosticSection(
                  'Configuration',
                  [
                    _buildDiagnosticRow('Environment', info['environment']),
                    _buildDiagnosticRow('Enabled', info['enabled'].toString()),
                    _buildDiagnosticRow('TIN', info['tin']),
                    _buildDiagnosticRow('Business', info['businessName']),
                    _buildDiagnosticRow('Client ID', info['clientId']),
                  ],
                ),
                const Divider(),
                _buildDiagnosticSection(
                  'API Status',
                  [
                    _buildDiagnosticRow('e-Invoice API', health['einvoiceAPI'],
                        isStatus: true),
                    _buildDiagnosticRow('Platform API', health['platformAPI'],
                        isStatus: true),
                    _buildDiagnosticRow('Overall', health['overallStatus'],
                        isStatus: true),
                  ],
                ),
                const Divider(),
                _buildDiagnosticSection(
                  'Endpoints',
                  [
                    _buildDiagnosticRow('Identity', info['identityUrl']),
                    _buildDiagnosticRow('API', info['apiUrl']),
                  ],
                ),
                if (health['apiVersion'] != 'UNKNOWN') ...[
                  const Divider(),
                  _buildDiagnosticSection(
                    'Version',
                    [
                      _buildDiagnosticRow(
                        'API',
                        health['apiVersion'].toString(),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Timestamp: ${health['timestamp']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Diagnostics Failed'),
            ],
          ),
          content: Text('Error: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDiagnosticSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _buildDiagnosticRow(String label, String value,
      {bool isStatus = false}) {
    Color? statusColor;
    if (isStatus) {
      if (value.contains('OK') || value.contains('HEALTHY')) {
        statusColor = Colors.green;
      } else if (value.contains('ERROR') || value.contains('FAILED')) {
        statusColor = Colors.red;
      } else {
        statusColor = Colors.orange;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: statusColor ?? Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.help_outline, size: 16, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Reference: https://sdk.myinvois.hasil.gov.my/einvoicingapi/\n'
              'Portal: https://myinvois.hasil.gov.my\n\n'
              'Sandbox is recommended until credentials are verified.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readonlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade100,
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

