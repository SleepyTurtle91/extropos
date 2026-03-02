import 'package:extropos/models/business_info_model.dart';
import 'package:flutter/material.dart';

class _BusinessDetailsDialog extends StatelessWidget {
  final BusinessInfo businessInfo;
  final ValueChanged<BusinessInfo> onSave;

  const _BusinessDetailsDialog({required this.businessInfo, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Business Details'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class _TaxSettingsDialog extends StatelessWidget {
  final BusinessInfo businessInfo;
  final ValueChanged<BusinessInfo> onSave;

  const _TaxSettingsDialog({required this.businessInfo, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tax Settings'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class _HappyHourDialog extends StatelessWidget {
  final BusinessInfo businessInfo;
  final ValueChanged<BusinessInfo> onSave;

  const _HappyHourDialog({required this.businessInfo, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Happy Hour Settings'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class _ReceiptSettingsDialog extends StatelessWidget {
  final BusinessInfo businessInfo;
  final ValueChanged<BusinessInfo> onSave;

  const _ReceiptSettingsDialog({required this.businessInfo, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Receipt Settings'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class _BusinessHoursScreen extends StatelessWidget {
  final dynamic businessHours;
  final ValueChanged<dynamic> onSave;

  const _BusinessHoursScreen({required this.businessHours, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Hours')),
      body: const Center(child: Text('Business hours editor placeholder')),
    );
  }
}
