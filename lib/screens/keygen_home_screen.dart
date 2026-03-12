import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class KeyGenHomeScreen extends StatefulWidget {
  const KeyGenHomeScreen({super.key});

  @override
  State<KeyGenHomeScreen> createState() => _KeyGenHomeScreenState();
}

class _KeyGenHomeScreenState extends State<KeyGenHomeScreen> {
  final _uuid = const Uuid();
  String _generatedKey = '';

  void _generateKey() {
    setState(() {
      _generatedKey = _uuid.v4().toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License Key Generator')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Generate a new key',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  _generatedKey.isEmpty ? 'No key generated yet' : _generatedKey,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _generateKey,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Generate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
