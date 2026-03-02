import 'package:flutter/material.dart';
import 'package:extropos/models/einvoice/lhdn_config.dart';

/// LHDN Configuration Dialog
/// Configure MyInvois API credentials and business details
/// Module: feature:einvoice
class LhdnConfigDialog extends StatefulWidget {
  final LhdnConfig initialConfig;
  final VoidCallback onDismiss;
  final ValueChanged<LhdnConfig> onSave;

  const LhdnConfigDialog({
    super.key,
    required this.initialConfig,
    required this.onDismiss,
    required this.onSave,
  });

  @override
  State<LhdnConfigDialog> createState() => _LhdnConfigDialogState();
}

class _LhdnConfigDialogState extends State<LhdnConfigDialog> {
  late TextEditingController _businessNameController;
  late TextEditingController _tinController;
  late TextEditingController _regNoController;
  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.initialConfig.businessName);
    _tinController = TextEditingController(text: widget.initialConfig.tin);
    _regNoController = TextEditingController(text: widget.initialConfig.regNo);
    _clientIdController =
        TextEditingController(text: widget.initialConfig.clientId);
    _clientSecretController =
        TextEditingController(text: widget.initialConfig.clientSecret);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _tinController.dispose();
    _regNoController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent, // Prevents Material 3 tinting over white
      child: SingleChildScrollView(
        // Added to prevent overflow when keyboard appears
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensures dialog only takes needed height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LHDN Integration Setup',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure your MyInvois API connection',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Business Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5), // indigo-600
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1),
              ),

              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Registered Business Name',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tinController,
                      decoration: const InputDecoration(
                        labelText: 'TIN',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _regNoController,
                      decoration: const InputDecoration(
                        labelText: 'BRN',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'MyInvois API Credentials',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981), // emerald-500
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1),
              ),

              TextField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: 'Client ID',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _clientSecretController,
                decoration: const InputDecoration(
                  labelText: 'Client Secret',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                obscureText: true,
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final newConfig = LhdnConfig(
                        businessName: _businessNameController.text.trim(),
                        tin: _tinController.text.trim(),
                        regNo: _regNoController.text.trim(),
                        clientId: _clientIdController.text.trim(),
                        clientSecret: _clientSecretController.text.trim(),
                      );
                      widget.onSave(newConfig);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
