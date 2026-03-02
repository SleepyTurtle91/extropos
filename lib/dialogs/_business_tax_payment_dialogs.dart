import 'package:extropos/models/business_info_model.dart';
import 'package:flutter/material.dart';

/// Tax settings and receipt configuration dialogs
class _TaxSettingsDialog extends StatefulWidget {
  final BusinessInfo businessInfo;
  final Function(BusinessInfo) onSave;

  const _TaxSettingsDialog({required this.businessInfo, required this.onSave});

  @override
  State<_TaxSettingsDialog> createState() => _TaxSettingsDialogState();
}

class _TaxSettingsDialogState extends State<_TaxSettingsDialog> {
  late TextEditingController _taxNumberController;
  late TextEditingController _taxRateController;
  late TextEditingController _serviceChargeRateController;
  late bool _isTaxEnabled;
  late bool _isServiceChargeEnabled;

  @override
  void initState() {
    super.initState();
    _taxNumberController = TextEditingController(
      text: widget.businessInfo.taxNumber ?? '',
    );
    _taxRateController = TextEditingController(
      text: (widget.businessInfo.taxRate * 100).toStringAsFixed(1),
    );
    _serviceChargeRateController = TextEditingController(
      text: (widget.businessInfo.serviceChargeRate * 100).toStringAsFixed(1),
    );
    _isTaxEnabled = widget.businessInfo.isTaxEnabled;
    _isServiceChargeEnabled = widget.businessInfo.isServiceChargeEnabled;
  }

  @override
  void dispose() {
    _taxNumberController.dispose();
    _taxRateController.dispose();
    _serviceChargeRateController.dispose();
    super.dispose();
  }

  void _save() {
    final taxRate = double.tryParse(_taxRateController.text) ?? 10.0;
    final serviceChargeRate =
        double.tryParse(_serviceChargeRateController.text) ?? 5.0;
    final updated = widget.businessInfo.copyWith(
      taxNumber: _taxNumberController.text.isEmpty
          ? null
          : _taxNumberController.text,
      taxRate: taxRate / 100,
      isTaxEnabled: _isTaxEnabled,
      serviceChargeRate: serviceChargeRate / 100,
      isServiceChargeEnabled: _isServiceChargeEnabled,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tax & Service Charge Settings'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tax Number',
                  border: OutlineInputBorder(),
                  hintText: 'GST/SST Number',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Tax'),
                subtitle: const Text('Apply tax to all transactions'),
                value: _isTaxEnabled,
                onChanged: (value) => setState(() => _isTaxEnabled = value),
              ),
              if (_isTaxEnabled) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _taxRateController,
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Service Charge'),
                subtitle: const Text(
                  'Apply service charge to all transactions',
                ),
                value: _isServiceChargeEnabled,
                onChanged: (value) =>
                    setState(() => _isServiceChargeEnabled = value),
              ),
              if (_isServiceChargeEnabled) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _serviceChargeRateController,
                  decoration: const InputDecoration(
                    labelText: 'Service Charge Rate (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(33, 150, 243, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These rates will be applied to all transactions',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Receipt settings and formatting dialog
class _ReceiptSettingsDialog extends StatefulWidget {
  final BusinessInfo businessInfo;
  final Function(BusinessInfo) onSave;

  const _ReceiptSettingsDialog({
    required this.businessInfo,
    required this.onSave,
  });

  @override
  State<_ReceiptSettingsDialog> createState() => _ReceiptSettingsDialogState();
}

class _ReceiptSettingsDialogState extends State<_ReceiptSettingsDialog> {
  late int _headerFontSize;
  late bool _headerBold;
  late bool _headerCentered;

  @override
  void initState() {
    super.initState();
    _headerFontSize = widget.businessInfo.receiptHeaderFontSize;
    _headerBold = widget.businessInfo.receiptHeaderBold;
    _headerCentered = widget.businessInfo.receiptHeaderCentered;
  }

  void _save() {
    final updated = widget.businessInfo.copyWith(
      receiptHeaderFontSize: _headerFontSize,
      receiptHeaderBold: _headerBold,
      receiptHeaderCentered: _headerCentered,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Receipt Header Settings'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configure how the business name appears on thermal receipts',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Header Font Size',
                  border: OutlineInputBorder(),
                  helperText: '1=Small, 2=Medium, 3=Large',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: _headerFontSize.toString(),
                ),
                onChanged: (value) {
                  final size = int.tryParse(value) ?? 2;
                  setState(() => _headerFontSize = size.clamp(1, 3));
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Bold Header'),
                subtitle: const Text('Make the business name bold'),
                value: _headerBold,
                onChanged: (value) => setState(() => _headerBold = value),
              ),
              SwitchListTile(
                title: const Text('Center Header'),
                subtitle: const Text('Center-align the business name'),
                value: _headerCentered,
                onChanged: (value) => setState(() => _headerCentered = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
