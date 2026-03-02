import 'package:extropos/models/einvoice/einvoice_config.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/services/myinvois_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'einvoice_config_ui.dart';

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
}
