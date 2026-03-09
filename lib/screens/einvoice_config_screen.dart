import 'package:extropos/models/einvoice/einvoice_config.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// E-Invoice Configuration Screen - Configure MyInvois settings
class EInvoiceConfigScreen extends StatefulWidget {
  const EInvoiceConfigScreen({super.key});

  @override
  State<EInvoiceConfigScreen> createState() => _EInvoiceConfigScreenState();
}

class _EInvoiceConfigScreenState extends State<EInvoiceConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _tinController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();

  bool _isEnabled = false;
  bool _isProduction = false;
  bool _isLoading = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
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

  Future<void> _loadCurrentConfig() async {
    final config = EInvoiceService.instance.config;
    if (config != null) {
      setState(() {
        _clientIdController.text = config.clientId;
        _clientSecretController.text = config.clientSecret;
        _tinController.text = config.tin;
        _businessNameController.text = config.businessName;
        _businessAddressController.text = config.businessAddress;
        _businessPhoneController.text = config.businessPhone;
        _businessEmailController.text = config.businessEmail;
        _isEnabled = config.isEnabled;
        _isProduction = config.isProduction;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final config = EInvoiceConfig(
        clientId: _clientIdController.text.trim(),
        clientSecret: _clientSecretController.text.trim(),
        tin: _tinController.text.trim(),
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
        businessEmail: _businessEmailController.text.trim(),
        isProduction: _isProduction,
        isEnabled: _isEnabled,
      );

      await EInvoiceService.instance.saveConfig(config);
      ToastHelper.showToast(context, 'Configuration saved successfully');
      Navigator.of(context).pop();
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to save configuration: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    try {
      final success = await EInvoiceService.instance.testConnection();
      if (success) {
        ToastHelper.showToast(context, 'Connection test successful');
      } else {
        ToastHelper.showToast(context, 'Connection test failed');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Connection test error: ${e.toString()}');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Invoice Configuration'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveConfig,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Enable/Disable toggle
            SwitchListTile(
              title: const Text('Enable E-Invoicing'),
              subtitle: const Text('Enable MyInvois e-invoice submission'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),

            const SizedBox(height: 16),

            // Environment toggle
            SwitchListTile(
              title: const Text('Production Mode'),
              subtitle: const Text('Use production MyInvois API (uncheck for sandbox)'),
              value: _isProduction,
              onChanged: (value) => setState(() => _isProduction = value),
            ),

            const SizedBox(height: 24),

            // API Credentials
            const Text(
              'MyInvois API Credentials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                hintText: 'Enter your MyInvois Client ID',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_isEnabled && (value == null || value.isEmpty)) {
                  return 'Client ID is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _clientSecretController,
              decoration: const InputDecoration(
                labelText: 'Client Secret',
                hintText: 'Enter your MyInvois Client Secret',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (_isEnabled && (value == null || value.isEmpty)) {
                  return 'Client Secret is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Business Information
            const Text(
              'Business Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _tinController,
              decoration: const InputDecoration(
                labelText: 'Tax Identification Number (TIN)',
                hintText: 'Enter your business TIN',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_isEnabled && (value == null || value.isEmpty)) {
                  return 'TIN is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                hintText: 'Enter your registered business name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_isEnabled && (value == null || value.isEmpty)) {
                  return 'Business name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _businessAddressController,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                hintText: 'Enter your business address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (_isEnabled && (value == null || value.isEmpty)) {
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
                hintText: 'Enter your business phone number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (_isEnabled && (value == null || value.isEmpty)) {
                  return 'Business phone is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _businessEmailController,
              decoration: const InputDecoration(
                labelText: 'Business Email',
                hintText: 'Enter your business email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (_isEnabled && (value == null || value.isEmpty)) {
                  return 'Business email is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Test Connection Button
            ElevatedButton.icon(
              onPressed: (_isTesting || !_isEnabled) ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
              label: const Text('Test Connection'),
            ),

            const SizedBox(height: 16),

            // Info text
            const Text(
              'MyInvois e-invoicing is required for Malaysian businesses. Contact MyInvois for API credentials.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}