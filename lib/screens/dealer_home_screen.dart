import 'package:extropos/screens/dealer_analytics_screen.dart';
import 'package:extropos/screens/dealer_customer_management_screen.dart';
import 'package:extropos/screens/keygen_home_screen.dart';
import 'package:extropos/screens/tenant_onboarding_screen.dart';
import 'package:extropos/services/license_key_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dealer Portal Home Screen
/// For dealer registration and tenant management
class DealerHomeScreen extends StatefulWidget {
  const DealerHomeScreen({super.key});

  @override
  State<DealerHomeScreen> createState() => _DealerHomeScreenState();
}

class _DealerHomeScreenState extends State<DealerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExtroPOS Dealer Portal'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Brand Section
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.business_center,
                          size: 64,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ExtroPOS Dealer Portal',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your restaurant clients, generate licenses, and create tenant databases',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Actions
                  _buildActionCard(
                    icon: Icons.vpn_key,
                    title: 'License Generator',
                    description:
                        'Generate offline licenses and tenant registration keys',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KeyGenHomeScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildActionCard(
                    icon: Icons.group_add,
                    title: 'Tenant Onboarding',
                    description:
                        'Create new tenant databases for restaurant clients',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TenantOnboardingScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildActionCard(
                    icon: Icons.people,
                    title: 'Customer Registration',
                    description: 'Register and manage restaurant customers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DealerCustomerManagementScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildActionCard(
                    icon: Icons.analytics,
                    title: 'Dealer Analytics',
                    description: 'View sales and performance analytics',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DealerAnalyticsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildActionCard(
                    icon: Icons.verified_user,
                    title: 'Test App Activation',
                    description: 'Test license key validation and activation',
                    onTap: _showActivationTestDialog,
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact our support team for assistance with tenant setup and client management.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showSupportContactDialog(context);
                          },
                          icon: const Icon(Icons.support_agent),
                          label: const Text('Contact Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get help with dealer portal, tenant management, and technical issues.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildContactOption(
                icon: Icons.email,
                title: 'Email Support',
                value: 'support@extropos.com',
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'support@extropos.com'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              _buildContactOption(
                icon: Icons.phone,
                title: 'Phone Support',
                value: '+60 12-345 6789',
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '+60123456789'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              _buildContactOption(
                icon: Icons.chat_bubble,
                title: 'WhatsApp',
                value: 'Chat with us',
                onTap: () async {
                  final Uri whatsappUrl = Uri.parse(
                    'https://wa.me/60123456789?text=Hello%2C%20I%20need%20help%20with%20ExtroPOS%20Dealer%20Portal',
                  );
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(
                      whatsappUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open WhatsApp'),
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 24),
              _buildContactOption(
                icon: Icons.help_center,
                title: 'Help Center',
                value: 'Visit documentation',
                onTap: () async {
                  final Uri helpUrl = Uri.parse(
                    'https://docs.extropos.com/dealer-portal',
                  );
                  if (await canLaunchUrl(helpUrl)) {
                    await launchUrl(
                      helpUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open help center'),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Support Hours: Mon-Fri, 9:00 AM - 6:00 PM (GMT+8)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
            ),
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
                  const SizedBox(height: 2),
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 32, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
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
                key: formKey,
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
                        if (formKey.currentState!.validate()) {
                          final result = await _validateTestLicense(
                            licenseKeyController.text.trim(),
                          );
                          setState(() {
                            validationResult = result;
                          });
                        }
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

  Future<String> _validateTestLicense(String key) async {
    try {
      // Validate key format and checksum
      final isValid = LicenseKeyGenerator.validateKey(key);

      if (!isValid) {
        return '❌ Invalid License Key\n\nThe license key format or checksum is invalid.';
      }

      // Get license details
      final licenseType = LicenseKeyGenerator.getLicenseType(key);
      final expiryDate = LicenseKeyGenerator.getExpiryDate(key);
      final daysRemaining = LicenseKeyGenerator.getDaysRemaining(key);
      final isExpired = LicenseKeyGenerator.isExpired(key);

      if (licenseType == null) {
        return '❌ Invalid License Key\n\nCould not determine license type';
      }

      String message = '✅ Valid License Key\n\n';
      message += 'License Type: ${licenseType.name.toUpperCase()}\n';

      if (licenseType != LicenseType.lifetime) {
        message +=
            'Expiry Date: ${expiryDate?.toString().split(' ')[0] ?? 'N/A'}\n';

        if (isExpired) {
          message += 'Status: ❌ EXPIRED\n';
          message += 'Days Past Expiry: ${daysRemaining?.abs() ?? 0}';
        } else {
          message += 'Status: ✅ ACTIVE\n';
          message += 'Days Remaining: ${daysRemaining ?? 0}';
        }
      } else {
        message += 'Status: ✅ LIFETIME LICENSE';
      }

      return message;
    } catch (e) {
      return '❌ Validation Error\n\n$e';
    }
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
}
