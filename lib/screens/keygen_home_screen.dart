import 'package:extropos/services/license_key_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyGenHomeScreen extends StatefulWidget {
  const KeyGenHomeScreen({super.key});

  @override
  State<KeyGenHomeScreen> createState() => _KeyGenHomeScreenState();
}

class _KeyGenHomeScreenState extends State<KeyGenHomeScreen> {
  LicenseType _selectedType = LicenseType.trial1Month;
  int _keyCount = 1;
  final List<String> _generatedKeys = [];
  String? _validationKey;
  bool? _validationResult;
  String? _validationMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('FlutterPOS License Generator'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Generator Section
              _buildGeneratorCard(),
              const SizedBox(height: 24),

              // Validator Section
              _buildValidatorCard(),
              const SizedBox(height: 24),

              // Generated Keys List
              if (_generatedKeys.isNotEmpty) _buildGeneratedKeysList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.vpn_key,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'License Key Generator',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Generate and validate license keys for FlutterPOS system',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip('1 Month Trial', '30 days', Icons.timer),
                _buildInfoChip('3 Month Trial', '90 days', Icons.event),
                _buildInfoChip('Lifetime', 'Unlimited', Icons.all_inclusive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      label: Text('$label: $value'),
      backgroundColor: Colors.blue[50],
    );
  }

  Widget _buildGeneratorCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate License Keys',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // License Type Selection
            const Text(
              'License Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<LicenseType>(
              segments: const [
                ButtonSegment(
                  value: LicenseType.trial1Month,
                  label: Text('1 Month'),
                  icon: Icon(Icons.timer),
                ),
                ButtonSegment(
                  value: LicenseType.trial3Month,
                  label: Text('3 Months'),
                  icon: Icon(Icons.event),
                ),
                ButtonSegment(
                  value: LicenseType.lifetime,
                  label: Text('Lifetime'),
                  icon: Icon(Icons.all_inclusive),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<LicenseType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Number of Keys
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 360) {
                  // Stack vertically for narrow layouts
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Number of Keys:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<int>(
                          value: _keyCount,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 5, 10, 25, 50, 100].map((count) {
                            return DropdownMenuItem(
                              value: count,
                              child: Text('$count'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _keyCount = value ?? 1;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const Text(
                      'Number of Keys:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<int>(
                        value: _keyCount,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: [1, 5, 10, 25, 50, 100].map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text('$count'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _keyCount = value ?? 1;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateKeys,
                icon: const Icon(Icons.add_circle),
                label: const Text('Generate Keys'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidatorCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Validate License Key',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter License Key',
                hintText: 'EXTRO-XXXX-XXXX-XXXX-XXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              onChanged: (value) {
                setState(() {
                  _validationKey = value;
                  _validationResult = null;
                  _validationMessage = null;
                });
              },
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _validationKey != null && _validationKey!.isNotEmpty
                    ? _validateKey
                    : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Validate Key'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            if (_validationResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _validationResult! ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _validationResult! ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _validationResult! ? Icons.check_circle : Icons.error,
                          color: _validationResult! ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _validationResult! ? 'Valid Key' : 'Invalid Key',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _validationResult!
                                ? Colors.green[900]
                                : Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                    if (_validationMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _validationMessage!,
                        style: TextStyle(
                          color: _validationResult!
                              ? Colors.green[900]
                              : Colors.red[900],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedKeysList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated Keys (${_generatedKeys.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _copyAllKeys,
                      icon: const Icon(Icons.copy_all),
                      label: const Text('Copy All'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearKeys,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedKeys.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final key = _generatedKeys[index];
                final type = LicenseKeyGenerator.getLicenseType(key);
                final expiryDate = LicenseKeyGenerator.getExpiryDate(key);
                final daysRemaining = LicenseKeyGenerator.getDaysRemaining(key);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    key,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${LicenseKeyGenerator.getLicenseTypeName(type!)}',
                      ),
                      if (expiryDate != null)
                        Text(
                          'Expires: ${expiryDate.toString().split(' ')[0]} ($daysRemaining days)',
                        )
                      else
                        const Text('Expires: Never (Lifetime)'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyKey(key),
                    tooltip: 'Copy Key',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _generateKeys() {
    final newKeys = LicenseKeyGenerator.generateKeys(_selectedType, _keyCount);
    setState(() {
      _generatedKeys.insertAll(0, newKeys);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generated $_keyCount ${LicenseKeyGenerator.getLicenseTypeName(_selectedType)} key(s)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _validateKey() {
    if (_validationKey == null || _validationKey!.isEmpty) return;

    final isValid = LicenseKeyGenerator.validateKey(_validationKey!);
    String message = '';

    if (isValid) {
      final type = LicenseKeyGenerator.getLicenseType(_validationKey!);
      final expiryDate = LicenseKeyGenerator.getExpiryDate(_validationKey!);
      final daysRemaining = LicenseKeyGenerator.getDaysRemaining(
        _validationKey!,
      );

      message = 'Type: ${LicenseKeyGenerator.getLicenseTypeName(type!)}\n';
      if (expiryDate != null) {
        message += 'Expires: ${expiryDate.toString().split(' ')[0]}\n';
        message += 'Days Remaining: $daysRemaining';
      } else {
        message += 'Expires: Never (Lifetime)';
      }
    } else {
      message = 'This key is invalid or has expired';
    }

    setState(() {
      _validationResult = isValid;
      _validationMessage = message;
    });
  }

  void _copyKey(String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('License key copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyAllKeys() {
    final allKeys = _generatedKeys.join('\n');
    Clipboard.setData(ClipboardData(text: allKeys));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_generatedKeys.length} keys copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearKeys() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Keys'),
        content: const Text(
          'Are you sure you want to clear all generated keys?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _generatedKeys.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
