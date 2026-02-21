import 'package:extropos/models/activation_mode.dart';
import 'package:extropos/screens/iap_debug_screen.dart';
import 'package:extropos/services/iap_service.dart';
import 'package:extropos/services/license_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _license = LicenseService.instance;
  ActivationMode _selectedMode = ActivationMode.offline;
  String _status = '';
  bool _loading = false;

  // Offline mode
  final _licenseKeyController = TextEditingController();

  // Tenant mode
  final _tenantIdController = TextEditingController();
  final _endpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _counterIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initIAP();
    
    // Pre-fill with current values if already activated
    if (_license.isActivated) {
      _selectedMode = _license.activationMode;
      if (_selectedMode == ActivationMode.offline) {
        _licenseKeyController.text = _license.licenseKey;
      } else {
        _tenantIdController.text = _license.tenantId;
        _endpointController.text = _license.tenantEndpoint;
        _apiKeyController.text = _license.tenantApiKey;
        _counterIdController.text = _license.counterId;
      }
    }
  }
  
  Future<void> _initIAP() async {
    try {
      await IAPService.instance.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) print('IAP Init Error: $e');
    }
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    _tenantIdController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _counterIdController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() => _loading = true);
    try {
      if (_selectedMode == ActivationMode.offline) {
        await _license.activate(_licenseKeyController.text.trim());
        setState(() => _status = '✅ Offline activation successful!');
      } else {
        await _license.activateWithTenant(
          tenantId: _tenantIdController.text.trim(),
          endpoint: _endpointController.text.trim(),
          apiKey: _apiKeyController.text.trim(),
          counterId: _counterIdController.text.isNotEmpty
              ? _counterIdController.text.trim()
              : null,
        );
        setState(() => _status = '✅ Tenant activation successful!');
      }
    } catch (e) {
      setState(() => _status = '❌ Activation failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  Future<void> _unbind() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unbind Device?'),
        content: const Text(
          'This will deactivate the license on this device. You will need to re-purchase or re-bind to use it again on another device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unbind')),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _loading = true);
    try {
      await _license.unbindDevice();
      setState(() {
        _status = '✅ Device unbound successfully.';
        _licenseKeyController.clear();
      });
    } catch (e) {
      setState(() => _status = '❌ Unbind failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Software Activation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            
            if (!_license.isActivated) ...[
              _buildPurchaseSection(),
              const Divider(height: 40),
            ],

            const Text(
              'Manual Activation:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildManualActivation(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    return Card(
      color: _license.isActivated ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _license.isActivated ? Icons.check_circle : Icons.warning_amber,
                  color: _license.isActivated ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  _license.isActivated ? 'Activated' : 'Trial Version',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_license.isActivated) ...[
                Text('License Key: ${_license.licenseKey}'),
                if (_license.boundEmail.isNotEmpty)
                  Text('Bound to: ${_license.boundEmail}'),
                  
                const SizedBox(height: 12),
                if (_license.licenseKey.startsWith('IAP-'))
                   OutlinedButton.icon(
                     onPressed: _loading ? null : _unbind,
                     icon: const Icon(Icons.link_off),
                     label: const Text('Unbind Device'),
                     style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                   ),
            ] else ...[
               Text('${_license.daysLeft} days remaining in trial.'),
               const Text('Features will be limited after trial expires.'),
            ]
          ],
        ),
      ),
    );
  }
  
  Widget _buildPurchaseSection() {
    if (!IAPService.instance.isAvailable) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Google Play Billing is not available on this device.'),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IAPDebugScreen()),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug IAP'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Purchase License:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Buy securely via Google Play. Lifetime license is bound to this device.'),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildIAPCard(
                title: 'Lifetime',
                subtitle: 'One-time purchase',
                icon: Icons.verified,
                color: Colors.blue.shade100,
                onTap: () async {
                  try {
                    await IAPService.instance.buyLifetime();
                  } catch (e) {
                    if (mounted) {
                      setState(() => _status = '❌ Purchase failed');
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Purchase Error'),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ),
             const SizedBox(width: 12),
             Expanded(
              child: _buildIAPCard(
                title: 'Cloud Sub',
                subtitle: 'Monthly/Yearly',
                icon: Icons.cloud,
                color: Colors.purple.shade100,
                onTap: () {
                  // Show subscription options dialog
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('Cloud Subscription'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('6 Months'),
                          subtitle: const Text('Access to cloud features'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              await IAPService.instance.buyCloud6Mo();
                            } catch (e) {
                              if (mounted) {
                                setState(() => _status = '❌ Purchase failed');
                                showDialog(
                                  context: context,
                                  builder: (ctx2) => AlertDialog(
                                    title: const Text('Purchase Error'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx2),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        ListTile(
                          title: const Text('1 Year'),
                          subtitle: const Text('Extended cloud access'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              await IAPService.instance.buyCloud1Yr();
                            } catch (e) {
                              if (mounted) {
                                setState(() => _status = '❌ Purchase failed');
                                showDialog(
                                  context: context,
                                  builder: (ctx2) => AlertDialog(
                                    title: const Text('Purchase Error'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx2),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
                  ));
                },
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => IAPService.instance.restorePurchases(),
          child: const Text('Restore Purchases'),
        ),
      ],
    );
  }
  
  Widget _buildIAPCard({
      required String title, 
      required String subtitle, 
      required IconData icon, 
      required Color color,
      required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualActivation() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<ActivationMode>(
                title: const Text('Offline Key'),
                value: ActivationMode.offline,
                groupValue: _selectedMode,
                onChanged: (value) => setState(() => _selectedMode = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<ActivationMode>(
                title: const Text('Tenant Login'),
                value: ActivationMode.tenant,
                groupValue: _selectedMode,
                onChanged: (value) => setState(() => _selectedMode = value!),
              ),
            ),
          ],
        ),
        if (_selectedMode == ActivationMode.offline) ...[
          TextField(
            controller: _licenseKeyController,
            decoration: const InputDecoration(labelText: 'Enter Manual License Key'),
          ),
        ] else ...[
          TextField(
            controller: _tenantIdController,
            decoration: const InputDecoration(labelText: 'Tenant ID'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(labelText: 'Reference URL'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(labelText: 'Access Key'),
            obscureText: true,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _activate,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                : const Text('Activate Manually'),
          ),
        ),
        if (_status.isNotEmpty) ...[
            const SizedBox(height: 16),
             Text(_status, style: TextStyle(color: _status.startsWith('✅') ? Colors.green : Colors.red)),
        ]
      ],
    );
  }
}
