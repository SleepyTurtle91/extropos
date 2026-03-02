import 'package:extropos/models/business_info_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

/// Main file for business information dialogs
/// Additional dialog files:
/// - _business_tax_payment_dialogs.dart: Tax and receipt settings
/// - _business_hours_screen.dart: Business hours management

class _HappyHourDialog extends StatefulWidget {
  final BusinessInfo businessInfo;
  final ValueChanged<BusinessInfo> onSave;
  const _HappyHourDialog({required this.businessInfo, required this.onSave});

  @override
  State<_HappyHourDialog> createState() => _HappyHourDialogState();
}

class _HappyHourDialogState extends State<_HappyHourDialog> {
  late bool enabled;
  late TextEditingController startController;
  late TextEditingController endController;
  late TextEditingController percentController;

  @override
  void initState() {
    super.initState();
    enabled = widget.businessInfo.isHappyHourEnabled;
    startController = TextEditingController(
      text: widget.businessInfo.happyHourStart ?? '',
    );
    endController = TextEditingController(
      text: widget.businessInfo.happyHourEnd ?? '',
    );
    percentController = TextEditingController(
      text: (widget.businessInfo.happyHourDiscountPercent * 100)
          .toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    percentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Happy Hour Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Enabled'),
            value: enabled,
            onChanged: (v) => setState(() => enabled = v),
          ),
          TextField(
            controller: startController,
            decoration: const InputDecoration(labelText: 'Start (HH:mm)'),
          ),
          TextField(
            controller: endController,
            decoration: const InputDecoration(labelText: 'End (HH:mm)'),
          ),
          TextField(
            controller: percentController,
            decoration: const InputDecoration(labelText: 'Discount %'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newInfo = widget.businessInfo.copyWith(
              isHappyHourEnabled: enabled,
              happyHourStart: startController.text.isEmpty
                  ? null
                  : startController.text,
              happyHourEnd: endController.text.isEmpty
                  ? null
                  : endController.text,
              happyHourDiscountPercent:
                  double.tryParse(percentController.text) != null
                  ? (double.parse(percentController.text) / 100.0)
                  : 0.0,
            );
            widget.onSave(newInfo);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Business Details Dialog
class _BusinessDetailsDialog extends StatefulWidget {
  final BusinessInfo businessInfo;
  final Function(BusinessInfo) onSave;

  const _BusinessDetailsDialog({
    required this.businessInfo,
    required this.onSave,
  });

  @override
  State<_BusinessDetailsDialog> createState() => _BusinessDetailsDialogState();
}

class _BusinessDetailsDialogState extends State<_BusinessDetailsDialog> {
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postcodeController;
  late TextEditingController _registrationController;
  late TextEditingController _websiteController;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.businessInfo.businessName,
    );
    _ownerNameController = TextEditingController(
      text: widget.businessInfo.ownerName,
    );
    _emailController = TextEditingController(text: widget.businessInfo.email);
    _phoneController = TextEditingController(text: widget.businessInfo.phone);
    _addressController = TextEditingController(
      text: widget.businessInfo.address,
    );
    _cityController = TextEditingController(text: widget.businessInfo.city);
    _stateController = TextEditingController(text: widget.businessInfo.state);
    _postcodeController = TextEditingController(
      text: widget.businessInfo.postcode,
    );
    _registrationController = TextEditingController(
      text: widget.businessInfo.registrationNumber ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.businessInfo.website ?? '',
    );

    // initialize logo path from existing business info
    _logoPath = widget.businessInfo.logo;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _registrationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<String> _copyToLocal(String src, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'images'));
    if (!imagesDir.existsSync()) await imagesDir.create(recursive: true);
    final ext = p.extension(src);
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = p.join(imagesDir.path, filename);
    await File(src).copy(dest);
    return dest;
  }

  Future<void> _save() async {
    final updated = widget.businessInfo.copyWith(
      // logo is handled elsewhere in the dialog state
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      postcode: _postcodeController.text,
      registrationNumber: _registrationController.text.isEmpty
          ? null
          : _registrationController.text,
      website: _websiteController.text.isEmpty ? null : _websiteController.text,
    );
    // If a logoPath was selected in the dialog, copy to app local storage and include it
    String? logoToSave = updated.logo;
    if (_logoPath != null && _logoPath!.isNotEmpty) {
      try {
        // If already under app dir we can keep it
        final appDir = await getApplicationDocumentsDirectory();
        if (!_logoPath!.startsWith(appDir.path)) {
          logoToSave = await _copyToLocal(_logoPath!, 'logo');
        } else {
          logoToSave = _logoPath;
        }
      } catch (_) {
        // ignore copy failures and fall back to original path
        logoToSave = _logoPath;
      }
    }

    final finalUpdated = updated.copyWith(logo: logoToSave ?? updated.logo);
    if (!mounted) return;
    widget.onSave(finalUpdated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Business Details'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo preview and upload
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _logoPath != null && _logoPath!.isNotEmpty
                        ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                        : (widget.businessInfo.logo != null &&
                              widget.businessInfo.logo!.isNotEmpty)
                        ? Image.file(
                            File(widget.businessInfo.logo!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.photo, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            setState(() {
                              _logoPath = result.files.single.path!;
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Logo'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _logoPath = null;
                          });
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _postcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postcode *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
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

/// Re-export dialog classes from split files for backward compatibility
// _TaxSettingsDialog and _ReceiptSettingsDialog are in _business_tax_payment_dialogs.dart
// _BusinessHoursScreen and _DayHoursCard are in _business_hours_screen.dart