import 'dart:developer' as developer;

import 'package:extropos/services/database_helper.dart';
import 'package:flutter/material.dart';

class EWalletSettingsScreen extends StatefulWidget {
  const EWalletSettingsScreen({super.key});

  @override
  State<EWalletSettingsScreen> createState() => _EWalletSettingsScreenState();
}

class _EWalletSettingsScreenState extends State<EWalletSettingsScreen> {
  final TextEditingController _merchantIdController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _clientSecretController = TextEditingController();
  final TextEditingController _callbackUrlController = TextEditingController();
  final TextEditingController _webhookSecretController = TextEditingController();
  bool _isEnabled = false;
  bool _useSandbox = true;
  bool _loading = true;
  String _provider = 'duitnow';
  bool _showAdvanced = false;

  static const String _paymentMethodKey = 'ewallet';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'e_wallet_settings',
        where: 'payment_method = ?',
        whereArgs: [_paymentMethodKey],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        _merchantIdController.text = (row['merchant_id'] as String?) ?? '';
        _apiKeyController.text = (row['api_key'] as String?) ?? '';
        _clientIdController.text = (row['client_id'] as String?) ?? '';
        _clientSecretController.text = (row['client_secret'] as String?) ?? '';
        _callbackUrlController.text = (row['callback_url'] as String?) ?? '';
        _webhookSecretController.text = (row['webhook_secret'] as String?) ?? '';
        _isEnabled = ((row['is_enabled'] as int?) ?? 0) == 1;
        _useSandbox = ((row['use_sandbox'] as int?) ?? 1) == 1;
        _provider = (row['provider'] as String?) ?? 'duitnow';
      }
    } catch (e) {
      developer.log('EWallet settings load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateSettings() {
    if (_isEnabled) {
      if (_merchantIdController.text.trim().isEmpty) {
        return 'Merchant ID is required when E-Wallet is enabled';
      }
      
      final callbackUrl = _callbackUrlController.text.trim();
      if (callbackUrl.isNotEmpty) {
        final uri = Uri.tryParse(callbackUrl);
        if (uri == null || (!uri.scheme.startsWith('http'))) {
          return 'Callback URL must be a valid HTTP/HTTPS URL';
        }
      }
    }
    return null;
  }

  Future<void> _saveSettings() async {
    final validationError = _validateSettings();
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }
    
    try {
      final db = await DatabaseHelper.instance.database;
      final existing = await db.query(
        'e_wallet_settings',
        where: 'payment_method = ?',
        whereArgs: [_paymentMethodKey],
        limit: 1,
      );
      final data = {
        'payment_method': _paymentMethodKey,
        'provider': _provider,
        'merchant_id': _merchantIdController.text.trim(),
        'api_key': _apiKeyController.text.trim(),
        'client_id': _clientIdController.text.trim(),
        'client_secret': _clientSecretController.text.trim(),
        'callback_url': _callbackUrlController.text.trim(),
        'webhook_secret': _webhookSecretController.text.trim(),
        'use_sandbox': _useSandbox ? 1 : 0,
        'is_enabled': _isEnabled ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      if (existing.isEmpty) {
        data['created_at'] = DateTime.now().millisecondsSinceEpoch;
        await db.insert('e_wallet_settings', data);
      } else {
        await db.update(
          'e_wallet_settings',
          data,
          where: 'payment_method = ?',
          whereArgs: [_paymentMethodKey],
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-Wallet settings saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    }
  }

  @override
  void dispose() {
    _merchantIdController.dispose();
    _apiKeyController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _callbackUrlController.dispose();
    _webhookSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Wallet Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Enable E-Wallet Payments'),
                    subtitle: const Text('Show E-Wallet method during checkout'),
                    value: _isEnabled,
                    onChanged: (v) => setState(() => _isEnabled = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Use Sandbox/Test Mode'),
                    subtitle: const Text('Recommended for testing'),
                    value: _useSandbox,
                    onChanged: (v) => setState(() => _useSandbox = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _provider,
                    decoration: const InputDecoration(
                      labelText: 'Provider',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'duitnow', child: Text('DuitNow QR')),
                      DropdownMenuItem(value: 'grabpay', child: Text('GrabPay')),
                      DropdownMenuItem(value: 'tng', child: Text('Touch ’n Go')),
                      DropdownMenuItem(value: 'boost', child: Text('Boost')),
                      DropdownMenuItem(value: 'shopeepay', child: Text('ShopeePay')),
                    ],
                    onChanged: (v) => setState(() => _provider = v ?? 'duitnow'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _merchantIdController,
                    decoration: const InputDecoration(
                      labelText: 'Merchant ID *',
                      hintText: 'e.g., DN-123456 or provider-specific',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Advanced Credentials'),
                    subtitle: Text(_showAdvanced ? 'Hide credentials' : 'Show API keys, webhooks'),
                    initiallyExpanded: _showAdvanced,
                    onExpansionChanged: (expanded) {
                      setState(() => _showAdvanced = expanded);
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _apiKeyController,
                              decoration: const InputDecoration(
                                labelText: 'API Key',
                                hintText: 'Optional for gateway integration',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _clientIdController,
                              decoration: const InputDecoration(
                                labelText: 'Client ID',
                                hintText: 'OAuth client identifier',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _clientSecretController,
                              decoration: const InputDecoration(
                                labelText: 'Client Secret',
                                hintText: 'OAuth client secret',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _callbackUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Callback URL',
                                hintText: 'https://yoursite.com/callback',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _webhookSecretController,
                              decoration: const InputDecoration(
                                labelText: 'Webhook Secret',
                                hintText: 'For signature verification',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text(
                            'This screen stores local E-Wallet settings for QR-based payments. '
                            'Provider integration can be added later. Sandbox mode is recommended during testing.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
