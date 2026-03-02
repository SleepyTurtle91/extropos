import 'package:extropos/services/license_key_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'keygen_home_screen_ui.dart';

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
  Widget build(BuildContext context) => throw UnimplementedError(
        'See keygen_home_screen_ui.dart',
      );

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
