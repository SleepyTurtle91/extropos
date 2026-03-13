import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class EWalletSettingsScreen extends StatefulWidget {
  const EWalletSettingsScreen({super.key});

  @override
  State<EWalletSettingsScreen> createState() => _EWalletSettingsScreenState();
}

class _EWalletSettingsScreenState extends State<EWalletSettingsScreen> {
  bool _isLoading = true;
  bool _boostEnabled = true;
  bool _grabPayEnabled = true;
  bool _tngEnabled = true;

  final _boostMerchantIdController = TextEditingController(text: 'BOOST-MID-12345');
  final _grabMerchantIdController = TextEditingController(text: 'GRAB-MID-67890');
  final _tngMerchantIdController = TextEditingController(text: 'TNG-MID-11223');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _boostMerchantIdController.dispose();
    _grabMerchantIdController.dispose();
    _tngMerchantIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // Simulate loading from persistent storage
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    // Simulate saving
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      ToastHelper.showToast(context, 'E-Wallet settings saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Wallet Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProviderTile(
                  title: 'Boost',
                  subtitle: 'Malaysian popular e-wallet',
                  enabled: _boostEnabled,
                  onChanged: (val) => setState(() => _boostEnabled = val),
                  controller: _boostMerchantIdController,
                  icon: Icons.account_balance_wallet,
                  color: Colors.red,
                ),
                const Divider(height: 32),
                _buildProviderTile(
                  title: 'GrabPay',
                  subtitle: 'Grab ecosystem integrated payment',
                  enabled: _grabPayEnabled,
                  onChanged: (val) => setState(() => _grabPayEnabled = val),
                  controller: _grabMerchantIdController,
                  icon: Icons.payment,
                  color: Colors.green,
                ),
                const Divider(height: 32),
                _buildProviderTile(
                  title: 'Touch ${"'"}${"n"} Go',
                  subtitle: 'TNG eWallet integration',
                  enabled: _tngEnabled,
                  onChanged: (val) => setState(() => _tngEnabled = val),
                  controller: _tngMerchantIdController,
                  icon: Icons.qr_code,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                const Card(
                  color: Color(0xFFFEF3C7),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Note: Enabling these providers will show them as options during the checkout process.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProviderTile({
    required String title,
    required String subtitle,
    required bool enabled,
    required Function(bool) onChanged,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          value: enabled,
          onChanged: onChanged,
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, top: 8),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Merchant ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'API Key / Secret',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
