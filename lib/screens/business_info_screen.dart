import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  late BusinessInfo businessInfo;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    businessInfo = BusinessInfo.instance;
  }

  void _editBusinessDetails() {
    showDialog(
      context: context,
      builder: (context) => _BusinessDetailsDialog(
        businessInfo: businessInfo,
        onSave: (updated) {
          setState(() {
            businessInfo = updated;
            BusinessInfo.updateInstance(updated);
          });
          ToastHelper.showToast(context, 'Business details updated');
        },
      ),
    );
  }

  void _editTaxSettings() {
    showDialog(
      context: context,
      builder: (context) => _TaxSettingsDialog(
        businessInfo: businessInfo,
        onSave: (updated) {
          setState(() {
            businessInfo = updated;
            BusinessInfo.updateInstance(updated);
          });
          ToastHelper.showToast(context, 'Tax settings updated');
        },
      ),
    );
  }

  void _editBusinessHours() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BusinessHoursScreen(
          businessHours: businessInfo.businessHours,
          onSave: (updated) {
            final newInfo = businessInfo.copyWith(businessHours: updated);
            setState(() {
              businessInfo = newInfo;
              BusinessInfo.updateInstance(newInfo);
            });
          },
        ),
      ),
    );
  }

  void _editHappyHour() {
    showDialog(
      context: context,
      builder: (context) => _HappyHourDialog(
        businessInfo: businessInfo,
        onSave: (updated) {
          setState(() {
            businessInfo = updated;
            BusinessInfo.updateInstance(updated);
          });
          ToastHelper.showToast(context, 'Happy Hour settings updated');
        },
      ),
    );
  }

  void _editReceiptSettings() {
    showDialog(
      context: context,
      builder: (context) => _ReceiptSettingsDialog(
        businessInfo: businessInfo,
        onSave: (updated) {
          setState(() {
            businessInfo = updated;
            BusinessInfo.updateInstance(updated);
          });
          ToastHelper.showToast(context, 'Receipt settings updated');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Information'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(37, 99, 235, 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store,
                      size: 40,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    businessInfo.businessName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    businessInfo.fullAddress,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoChip(icon: Icons.phone, label: businessInfo.phone),
                      _InfoChip(icon: Icons.email, label: businessInfo.email),
                      if (businessInfo.website != null)
                        _InfoChip(
                          icon: Icons.language,
                          label: businessInfo.website!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Business Details Section
          _SectionHeader(
            title: 'Business Details',
            onEdit: _editBusinessDetails,
          ),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.person,
                  label: 'Owner Name',
                  value: businessInfo.ownerName,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.business,
                  label: 'Registration Number',
                  value: businessInfo.registrationNumber ?? 'Not set',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.location_on,
                  label: 'City',
                  value: businessInfo.city,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.map,
                  label: 'State',
                  value: businessInfo.state,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.mail,
                  label: 'Postcode',
                  value: businessInfo.postcode,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.flag,
                  label: 'Country',
                  value: businessInfo.country,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tax & Currency Section
          _SectionHeader(title: 'Tax & Currency', onEdit: _editTaxSettings),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.receipt,
                  label: 'Tax Number',
                  value: businessInfo.taxNumber ?? 'Not set',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.percent,
                  label: 'Tax Rate',
                  value: businessInfo.isTaxEnabled
                      ? businessInfo.taxRatePercentage
                      : 'Disabled',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.room_service,
                  label: 'Service Charge',
                  value: businessInfo.isServiceChargeEnabled
                      ? businessInfo.serviceChargeRatePercentage
                      : 'Disabled',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.attach_money,
                  label: 'Currency',
                  value:
                      '${businessInfo.currency} (${businessInfo.currencySymbol})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Hours Section
          _SectionHeader(title: 'Business Hours', onEdit: _editBusinessHours),
          Card(
            child: Column(
              children: [
                _BusinessHoursTile(
                  day: 'Monday',
                  hours: businessInfo.businessHours.monday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Tuesday',
                  hours: businessInfo.businessHours.tuesday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Wednesday',
                  hours: businessInfo.businessHours.wednesday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Thursday',
                  hours: businessInfo.businessHours.thursday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Friday',
                  hours: businessInfo.businessHours.friday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Saturday',
                  hours: businessInfo.businessHours.saturday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Sunday',
                  hours: businessInfo.businessHours.sunday,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Receipt Settings Section
          _SectionHeader(
            title: 'Receipt Settings',
            onEdit: _editReceiptSettings,
          ),
          const SizedBox(height: 24),
          // Happy Hour Section
          _SectionHeader(title: 'Happy Hour', onEdit: _editHappyHour),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.local_offer,
                  label: 'Enabled',
                  value: businessInfo.isHappyHourEnabled ? 'Yes' : 'No',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.timer,
                  label: 'Start',
                  value: businessInfo.happyHourStart ?? 'Not set',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.timer_off,
                  label: 'End',
                  value: businessInfo.happyHourEnd ?? 'Not set',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.percent,
                  label: 'Discount',
                  value:
                      '${(businessInfo.happyHourDiscountPercent * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.text_fields,
                  label: 'Header Font Size',
                  value: businessInfo.receiptHeaderFontSize.toString(),
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.format_bold,
                  label: 'Header Bold',
                  value: businessInfo.receiptHeaderBold ? 'Yes' : 'No',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.format_align_center,
                  label: 'Header Centered',
                  value: businessInfo.receiptHeaderCentered ? 'Yes' : 'No',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;

  const _SectionHeader({required this.title, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
      label: Text(label),
    );
  }
}

class _BusinessHoursTile extends StatelessWidget {
  final String day;
  final TimeRange hours;

  const _BusinessHoursTile({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        hours.isOpen ? Icons.access_time : Icons.close,
        color: hours.isOpen ? Colors.green : Colors.grey,
      ),
      title: Text(day),
      trailing: Text(
        hours.displayText,
        style: TextStyle(
          color: hours.isOpen ? Colors.black87 : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
  final BusinessHours businessHours;
  final ValueChanged<BusinessHours> onSave;

  const _BusinessHoursScreen({required this.businessHours, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Hours')),
      body: const Center(child: Text('Business hours editor placeholder')),
    );
  }
}
