import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class BusinessModeScreen extends StatefulWidget {
  const BusinessModeScreen({super.key});

  @override
  State<BusinessModeScreen> createState() => _BusinessModeScreenState();
}

class _BusinessModeScreenState extends State<BusinessModeScreen> {
  late BusinessMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = BusinessInfo.instance.selectedBusinessMode;
  }

  void _selectMode(BusinessMode mode) async {
    if (mode == _selectedMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Business Mode'),
        content: Text(
          'Are you sure you want to switch to ${mode.displayName} mode? '
          'This will change how your POS system operates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Switch Mode'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _selectedMode = mode;
      });

      BusinessInfo.updateInstance(
        BusinessInfo.instance.copyWith(selectedBusinessMode: mode),
      );

      ToastHelper.showToast(context, 'Switched to ${mode.displayName} mode');

      // Show restart suggestion
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mode Changed'),
          content: const Text(
            'Business mode has been changed. For the best experience, '
            'consider restarting the app to ensure all features work correctly.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildModeOption(BusinessMode mode) {
    final isSelected = _selectedMode == mode;
    final description = _getModeDescription(mode);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _selectMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? const Color.fromRGBO(37, 99, 235, 0.1)
                : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getModeIcon(mode),
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(BusinessMode mode) {
    switch (mode) {
      case BusinessMode.retail:
        return Icons.shopping_cart;
      case BusinessMode.cafe:
        return Icons.local_cafe;
      case BusinessMode.restaurant:
        return Icons.restaurant;
    }
  }

  String _getModeDescription(BusinessMode mode) {
    switch (mode) {
      case BusinessMode.retail:
        return 'Direct sales workflow with immediate checkout. '
            'Customers select items and pay directly at the counter. '
            'Best for shops, convenience stores, and quick service.';
      case BusinessMode.cafe:
        return 'Order numbering system for takeaway and counter service. '
            'Customers receive order numbers and wait for their items. '
            'Perfect for cafes, bakeries, and fast food outlets.';
      case BusinessMode.restaurant:
        return 'Full table service with table management. '
            'Waitstaff can assign orders to specific tables, '
            'manage seating, and handle table-based billing. '
            'Ideal for sit-down restaurants and fine dining.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Mode'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your business operation mode',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildModeOption(BusinessMode.retail),
            _buildModeOption(BusinessMode.cafe),
            _buildModeOption(BusinessMode.restaurant),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text(
                          'Mode Change Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Changing business mode affects how orders are processed and managed. '
                      'Some features may behave differently based on the selected mode.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
