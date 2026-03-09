import 'package:extropos/models/enum_models.dart';
import 'package:extropos/services/license_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// Activation Screen - Handle software license activation
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _licenseKeyController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  ActivationMode _selectedMode = ActivationMode.offline;
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    _checkActivationStatus();
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkActivationStatus() async {
    if (!LicenseService.instance.isInited) {
      await LicenseService.instance.init();
    }

    setState(() {
      _isActivated = LicenseService.instance.isActivated;
      _selectedMode = LicenseService.instance.activationMode;
    });
  }

  Future<void> _activateOffline() async {
    final licenseKey = _licenseKeyController.text.trim();
    if (licenseKey.isEmpty) {
      ToastHelper.showToast(context, 'Please enter a license key');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await LicenseService.instance.activateOffline(licenseKey);
      if (success) {
        setState(() => _isActivated = true);
        ToastHelper.showToast(context, 'Software activated successfully!');
        Navigator.of(context).pop();
      } else {
        ToastHelper.showToast(context, 'Invalid license key');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Activation failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activateTenant() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ToastHelper.showToast(context, 'Please enter your email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await LicenseService.instance.activateTenant(email);
      if (success) {
        setState(() => _isActivated = true);
        ToastHelper.showToast(context, 'Tenant activation initiated. Check your email.');
        Navigator.of(context).pop();
      } else {
        ToastHelper.showToast(context, 'Tenant activation failed');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Activation failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isActivated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Activation'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Software is Activated',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Your FlutterPOS is ready to use'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Software Activation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose Activation Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Activation mode selector
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ActivationMode>(
                    title: const Text('Offline Activation'),
                    subtitle: const Text('Use license key'),
                    value: ActivationMode.offline,
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      setState(() => _selectedMode = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<ActivationMode>(
                    title: const Text('Tenant Activation'),
                    subtitle: const Text('Cloud-connected'),
                    value: ActivationMode.tenant,
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      setState(() => _selectedMode = value!);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Input fields based on selected mode
            if (_selectedMode == ActivationMode.offline) ...[
              TextField(
                controller: _licenseKeyController,
                decoration: const InputDecoration(
                  labelText: 'License Key',
                  hintText: 'Enter your license key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _activateOffline,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Activate'),
              ),
            ] else ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your business email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _activateTenant,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request Activation'),
              ),
            ],

            const Spacer(),

            // Info text
            const Text(
              'Activation is required to use all features of FlutterPOS. Contact support if you need assistance.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}