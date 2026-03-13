import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/receipt_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late ReceiptSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ReceiptService.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error loading settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ReceiptService.saveSettings(_settings);
      if (mounted) {
        ToastHelper.showToast(context, 'Settings saved successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error saving settings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Layout Options'),
              SwitchListTile(
                title: const Text('Show Logo'),
                subtitle: const Text('Display business logo on receipt'),
                value: _settings.showLogo,
                onChanged: (val) => setState(() => _settings.showLogo = val),
              ),
              SwitchListTile(
                title: const Text('Show Date & Time'),
                value: _settings.showDateTime,
                onChanged: (val) => setState(() => _settings.showDateTime = val),
              ),
              SwitchListTile(
                title: const Text('Show Order Number'),
                value: _settings.showOrderNumber,
                onChanged: (val) => setState(() => _settings.showOrderNumber = val),
              ),
              SwitchListTile(
                title: const Text('Show Customer Info'),
                value: _settings.showCustomerInfo,
                onChanged: (val) => setState(() => _settings.showCustomerInfo = val),
              ),
              const Divider(),
              _buildSectionTitle('Custom Text'),
              TextFormField(
                initialValue: _settings.headerText,
                decoration: const InputDecoration(
                  labelText: 'Header Text',
                  hintText: 'Welcome to our store',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (val) => _settings.headerText = val,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _settings.footerText,
                decoration: const InputDecoration(
                  labelText: 'Footer Text',
                  hintText: 'Thank you for your purchase!',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (val) => _settings.footerText = val,
              ),
              const Divider(),
              _buildSectionTitle('Advanced'),
              SwitchListTile(
                title: const Text('Show Barcode'),
                subtitle: const Text('Print receipt ID as barcode'),
                value: _settings.showBarcode,
                onChanged: (val) => setState(() => _settings.showBarcode = val),
              ),
              if (_settings.showBarcode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    initialValue: _settings.barcodeData,
                    decoration: const InputDecoration(
                      labelText: 'Barcode Data Override',
                      hintText: 'Leave empty for default ID',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _settings.barcodeData = val,
                  ),
                ),
              SwitchListTile(
                title: const Text('Show QR Code'),
                value: _settings.showQrCode,
                onChanged: (val) => setState(() => _settings.showQrCode = val),
              ),
              if (_settings.showQrCode)
                TextFormField(
                  initialValue: _settings.qrData,
                  decoration: const InputDecoration(
                    labelText: 'QR Code Data',
                    hintText: 'Website URL or custom data',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _settings.qrData = val,
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
