part of 'dealer_home_screen.dart';

extension DealerHomeScreenDialogs on _DealerHomeScreenState {
  void _showSupportContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Color(0xFF2563EB)),
            SizedBox(width: 12),
            Text('Contact Support'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get support for your dealer account:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildSupportOption(
                  'Email Support',
                  'support@extropos.io',
                  Icons.mail,
                  () => _launchEmailClient('support@extropos.io'),
                ),
                const SizedBox(height: 8),
                _buildSupportOption(
                  'Live Chat',
                  'Available now',
                  Icons.chat,
                  () =>
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Live chat opening...')),
                      ),
                ),
              ],
            ),
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
  }

  Widget _buildSupportOption(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showActivationTestDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController licenseKeyController = TextEditingController();
    String? validationResult;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF2563EB)),
              SizedBox(width: 12),
              Text('Test App Activation'),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter a license key to test activation validation:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: licenseKeyController,
                      decoration: const InputDecoration(
                        labelText: 'License Key',
                        hintText: 'EXTRO-LIFE-XXXX-XXXX-XXXX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a license key';
                        }
                        if (!value.startsWith('EXTRO-')) {
                          return 'License key must start with EXTRO-';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await _validateTestLicense(
                          licenseKeyController.text.trim(),
                        );
                        setState(() {
                          validationResult = result;
                        });
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Test Activation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (validationResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: validationResult!.contains('✅')
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: validationResult!.contains('✅')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          validationResult!,
                          style: TextStyle(
                            fontSize: 13,
                            color: validationResult!.contains('✅')
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Test License Keys:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildKeyExample('1-Month Trial', 'Generate using KeyGen'),
                    _buildKeyExample('3-Month Trial', 'Generate using KeyGen'),
                    _buildKeyExample('Lifetime', 'Generate using KeyGen'),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyExample(String type, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.fiber_manual_record, size: 8, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$type: ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              example,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmailClient(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email client')),
        );
      }
    }
  }
}
