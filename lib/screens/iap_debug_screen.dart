import 'package:extropos/services/iap_service.dart';
import 'package:flutter/material.dart';

/// Debug screen to diagnose IAP issues
class IAPDebugScreen extends StatefulWidget {
  const IAPDebugScreen({super.key});

  @override
  State<IAPDebugScreen> createState() => _IAPDebugScreenState();
}

class _IAPDebugScreenState extends State<IAPDebugScreen> {
  String _status = 'Initializing...';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _diagnose();
  }

  Future<void> _diagnose() async {
    _addLog('🔍 Starting IAP diagnostics...');

    try {
      // Check if IAP is available
      _addLog('Checking IAP availability...');
      final isAvailable = IAPService.instance.isAvailable;
      _addLog('IAP Available: $isAvailable');

      if (!isAvailable) {
        _addLog('❌ Google Play Billing is not available');
        _addLog('Possible reasons:');
        _addLog('  - Not running on a real device');
        _addLog('  - Google Play Services not installed');
        _addLog('  - App not signed correctly');
        setState(() => _status = 'IAP Not Available');
        return;
      }

      // Check loaded products
      _addLog('Checking loaded products...');
      final products = IAPService.instance.products;
      _addLog('Products loaded: ${products.length}');

      if (products.isEmpty) {
        _addLog('❌ No products loaded from Google Play');
        _addLog('Required product IDs:');
        _addLog('  - ${IAPService.productLifetime}');
        _addLog('  - ${IAPService.paramCloud6Mo}');
        _addLog('  - ${IAPService.paramCloud1Yr}');
        _addLog('');
        _addLog('⚠️ These products must be configured in Google Play Console!');
        setState(() => _status = 'No Products Found');
        return;
      }

      // List all products
      for (final product in products) {
        _addLog('✅ Product: ${product.id}');
        _addLog('   Title: ${product.title}');
        _addLog('   Price: ${product.price}');
        _addLog('   Description: ${product.description}');
      }

      setState(() => _status = 'IAP Ready');
      _addLog('✅ IAP system is ready!');
    } catch (e) {
      _addLog('❌ Error: $e');
      setState(() => _status = 'Error');
    }
  }

  void _addLog(String message) {
    setState(() => _logs.add(message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IAP Debug'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _status == 'IAP Ready'
                ? Colors.green.shade100
                : _status == 'Error' || _status == 'IAP Not Available'
                    ? Colors.red.shade100
                    : Colors.orange.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_status != 'IAP Ready')
                  const Text(
                    'See logs below for details',
                    style: TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: log.startsWith('❌')
                          ? Colors.red
                          : log.startsWith('✅')
                              ? Colors.green
                              : log.startsWith('⚠️')
                                  ? Colors.orange
                                  : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                        _status = 'Initializing...';
                      });
                      _diagnose();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Re-diagnose'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
