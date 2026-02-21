import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/my_invois_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyInvoisSettingsScreen extends StatefulWidget {
  const MyInvoisSettingsScreen({super.key});

  @override
  State<MyInvoisSettingsScreen> createState() => _MyInvoisSettingsScreenState();
}

class _MyInvoisSettingsScreenState extends State<MyInvoisSettingsScreen> {
  static const int _defaultGuardHours = 24;
  final _formKey = GlobalKey<FormState>();
  final _sstController = TextEditingController();
  final _brnController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isEnabled = false;
  bool _useSandbox = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool? _lastTestSuccess;
  DateTime? _lastTestedAt;
  int _guardHours = _defaultGuardHours;

  bool get _hasRecentSuccessfulTest {
    if (_lastTestSuccess != true || _lastTestedAt == null) return false;
    return DateTime.now().difference(_lastTestedAt!).inHours < _guardHours;
  }

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
    BusinessInfo.instance.addListener(_handleBusinessInfoChanged);
  }

  @override
  void dispose() {
    BusinessInfo.instance.removeListener(_handleBusinessInfoChanged);
    _sstController.dispose();
    _brnController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadBusinessInfo() {
    final info = BusinessInfo.instance;
    _isEnabled = info.isMyInvoisEnabled;
    _useSandbox = info.useMyInvoisSandbox;
    _sstController.text = info.sstRegistrationNumber ?? '';
    _brnController.text = info.businessRegistrationNumber ?? '';
    _emailController.text = info.businessEmail ?? '';
    _phoneController.text = info.businessPhone ?? '';
    _addressController.text = info.businessAddress ?? '';
    _lastTestSuccess = info.myInvoisLastTestSuccess;
    if (info.myInvoisLastTestedAt != null) {
      _lastTestedAt =
          DateTime.fromMillisecondsSinceEpoch(info.myInvoisLastTestedAt!);
    }
    _guardHours = info.myInvoisProductionGuardHours;
    if (!_hasRecentSuccessfulTest && !_useSandbox) {
      _useSandbox = true;
    }
    setState(() {});
  }

  void _handleBusinessInfoChanged() {
    // Reload from shared instance to reflect external updates
    _loadBusinessInfo();
  }

  void _onEnvironmentChanged(bool useSandbox) {
    if (!useSandbox && !_hasRecentSuccessfulTest) {
      _showProductionBlocked();
      return;
    }
    if (!useSandbox) {
      _confirmProductionSwitch().then((confirmed) {
        if (mounted && confirmed) {
          setState(() => _useSandbox = false);
        } else if (mounted) {
          setState(() => _useSandbox = true);
        }
      });
      return;
    }
    setState(() => _useSandbox = true);
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    if (_isEnabled && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = BusinessInfo.instance.copyWith(
        isMyInvoisEnabled: _isEnabled,
        useMyInvoisSandbox: _useSandbox,
        sstRegistrationNumber: _sstController.text.trim().isEmpty
            ? null
            : _sstController.text.trim(),
        businessRegistrationNumber: _brnController.text.trim().isEmpty
            ? null
            : _brnController.text.trim(),
        businessEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        businessPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        businessAddress: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        myInvoisLastTestSuccess: _lastTestSuccess,
        myInvoisLastTestedAt: _lastTestedAt?.millisecondsSinceEpoch,
        myInvoisProductionGuardHours: _guardHours,
      );

      BusinessInfo.updateInstance(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MyInvois settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    if (_isSaving || _isTesting) return;

    setState(() {
      _isEnabled = false;
      _useSandbox = true;
      _sstController.clear();
      _brnController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _lastTestSuccess = null;
      _lastTestedAt = null;
      _guardHours = _defaultGuardHours;
    });

    await BusinessInfo.updateInstance(
      BusinessInfo.instance.copyWith(
        isMyInvoisEnabled: false,
        useMyInvoisSandbox: true,
        sstRegistrationNumber: null,
        businessRegistrationNumber: null,
        businessEmail: null,
        businessPhone: null,
        businessAddress: null,
        myInvoisLastTestSuccess: null,
        myInvoisLastTestedAt: null,
        myInvoisProductionGuardHours: _defaultGuardHours,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MyInvois settings reset to defaults')),
      );
    }
  }

  Future<void> _confirmResetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset MyInvois settings?'),
          content: const Text('This will clear all MyInvois fields and revert to sandbox.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _resetToDefaults();
    }
  }

  Future<bool> _confirmProductionSwitch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Switch to production?'),
          content: const Text(
            'Invoices will be submitted live to MyInvois. Ensure details are correct and a recent test succeeded.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay in sandbox'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Go to production'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _testConnection() async {
    if (_isTesting || !_isEnabled) return;
    if (_sstController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter SST registration number to test')),
      );
      return;
    }

    setState(() => _isTesting = true);
    try {
      final ok = await MyInvoiceService(useSandboxOverride: _useSandbox).validateSSTRegistration(
        _sstController.text.trim(),
      );
      _lastTestSuccess = ok;
      _lastTestedAt = DateTime.now();

      await BusinessInfo.updateInstance(
        BusinessInfo.instance.copyWith(
          myInvoisLastTestSuccess: _lastTestSuccess,
          myInvoisLastTestedAt: _lastTestedAt!.millisecondsSinceEpoch,
        ),
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'SST registration is valid' : 'SST registration validation failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyInvois Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final content = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.start,
                      children: [
                        SizedBox(
                          width: isWide ? (constraints.maxWidth / 2) - 32 : constraints.maxWidth,
                          child: _buildSettingsCard(),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth / 2) - 32 : constraints.maxWidth,
                          child: _buildStatusCard(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed:
                              (_isSaving || _isTesting) ? null : _confirmResetToDefaults,
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset to defaults'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveSettings,
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );

          return Center(child: content);
        },
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Integration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: (val) {
                    setState(() => _isEnabled = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Enable MyInvois integration for e-Invoice compliance (Malaysia).',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Environment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Switch.adaptive(
                  value: _useSandbox,
                  onChanged: (val) => _onEnvironmentChanged(val),
                  activeColor: Colors.green,
                ),
              ],
            ),
            Text(
              _useSandbox
                  ? 'Sandbox mode: safe for testing submissions'
                  : 'Production mode: live submissions to MyInvois',
              style: TextStyle(
                color: _useSandbox ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _sstController,
              label: 'SST Registration Number',
              hint: 'e.g., A123456789',
              validator: (value) {
                if (!_isEnabled) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Required when MyInvois is enabled';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _brnController,
              label: 'Business Registration Number (BRN)',
              hint: 'e.g., 202201234567',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: 'Business Email',
              hint: 'billing@yourcompany.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (!_isEnabled) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Email required when enabled';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: 'Business Phone',
              hint: '+60 12-345 6789',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Business Address',
              hint: 'Street, City, State, Postcode',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _isEnabled && !_isTesting ? _testConnection : null,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status & Requirements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(
                  _isEnabled ? 'Enabled' : 'Disabled',
                  _isEnabled ? Colors.green : Colors.orange,
                  _isEnabled ? Icons.verified : Icons.privacy_tip_outlined,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  _useSandbox
                      ? 'Sandbox'
                      : _hasRecentSuccessfulTest
                          ? 'Production'
                          : 'Production (blocked)',
                  _useSandbox
                      ? Colors.blue
                      : _hasRecentSuccessfulTest
                          ? Colors.redAccent
                          : Colors.orange,
                  _useSandbox
                      ? Icons.science
                      : _hasRecentSuccessfulTest
                          ? Icons.public
                          : Icons.lock_clock,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('SST Registration', _sstController.text.isEmpty ? 'Not set' : _sstController.text),
            _buildStatusRow('BRN', _brnController.text.isEmpty ? 'Not set' : _brnController.text),
            _buildStatusRow('Email', _emailController.text.isEmpty ? 'Not set' : _emailController.text),
            _buildStatusRow('Phone', _phoneController.text.isEmpty ? 'Not set' : _phoneController.text),
            _buildStatusRow('Address', _addressController.text.isEmpty ? 'Not set' : _addressController.text),
            _buildStatusRow('Guard window', '$_guardHours hours'),
            const SizedBox(height: 12),
            _buildLastTestBadge(),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            if (!_useSandbox && !_hasRecentSuccessfulTest)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGuardNotice(),
              ),
            _buildGuardSelector(),
            const Text(
              'Checklist',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildChecklistItem('SST registration number is required when enabled'),
            _buildChecklistItem('Use sandbox environment for testing invoices'),
            _buildChecklistItem('Ensure accurate business details for submissions'),
            _buildChecklistItem(
              'Successful test in last $_guardHours hours required before production',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildLastTestBadge() {
    String label = 'Not tested';
    Color color = Colors.grey;
    IconData icon = Icons.help_outline;
    String timeText = '';

    if (_lastTestedAt != null) {
      timeText = ' • ${DateFormat.yMMMd().add_jm().format(_lastTestedAt!)}';
      if (_lastTestSuccess == true) {
        label = 'Last test: Passed';
        color = Colors.green;
        icon = Icons.check_circle;
      } else if (_lastTestSuccess == false) {
        label = 'Last test: Failed';
        color = Colors.redAccent;
        icon = Icons.error_outline;
      } else {
        label = 'Last test: Unknown';
        color = Colors.orange;
        icon = Icons.help_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label$timeText',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          if (_lastTestedAt != null)
            TextButton(
              onPressed: _isEnabled && !_isTesting ? _testConnection : null,
              child: const Text('Retest'),
            ),
        ],
      ),
    );
  }

  Widget _buildGuardNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Production locked. Run a successful test within the last $_guardHours hours to go live.',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardSelector() {
    const options = [6, 12, 24, 48, 72];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Production guard window',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _guardHours,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: options
                .map(
                  (h) => DropdownMenuItem(
                    value: h,
                    child: Text('$h hours'),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => _guardHours = val);
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'Require a recent successful test before allowing production.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showProductionBlocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Production mode requires a successful test within the last $_guardHours hours.',
        ),
      ),
    );
  }
}
