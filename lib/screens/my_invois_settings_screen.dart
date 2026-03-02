import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/my_invois_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'my_invois_settings_screen_ui.dart';

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
                          child: buildSettingsCard(),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth / 2) - 32 : constraints.maxWidth,
                          child: buildStatusCard(),
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
