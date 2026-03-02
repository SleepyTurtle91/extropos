// Receipt settings screen
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/screens/kitchen_docket_settings_screen.dart';
import 'package:extropos/screens/receipt_designer_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'receipt_settings_ui.dart';
part 'receipt_settings_preview.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  late ReceiptSettings _settings;
  bool _isLoading = true;

  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  final _thankYouController = TextEditingController();
  final _termsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _thankYouController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final currentContext = context;
    try {
      final settings = await DatabaseService.instance.getReceiptSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _headerController.text = _settings.headerText;
        _footerController.text = _settings.footerText;
        _thankYouController.text = _settings.thankYouMessage;
        _termsController.text = _settings.termsAndConditions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settings = ReceiptSettings();
        _headerController.text = _settings.headerText;
        _footerController.text = _settings.footerText;
        _thankYouController.text = _settings.thankYouMessage;
        _termsController.text = _settings.termsAndConditions;
        _isLoading = false;
      });
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    final currentContext = context;
    final updatedSettings = _settings.copyWith(
      headerText: _headerController.text,
      footerText: _footerController.text,
      thankYouMessage: _thankYouController.text,
      termsAndConditions: _termsController.text,
    );

    try {
      await DatabaseService.instance.saveReceiptSettings(updatedSettings);
      if (!mounted) return;
      setState(() {
        _settings = updatedSettings;
      });
      ToastHelper.showToast(
        currentContext,
        'Receipt settings saved successfully',
      );
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Error saving settings: $e');
    }
  }

  void _previewReceipt() {
    showDialog(
      context: context,
      builder: (context) => _ReceiptPreviewDialog(settings: _settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Receipt Settings'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.design_services),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReceiptDesignerScreen(),
                ),
              );
            },
            tooltip: 'Visual Designer',
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _previewReceipt,
            tooltip: 'Preview Receipt',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Paper Size'),
          _buildPaperSizeCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Font Size'),
          _buildFontSizeCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Display Options'),
          _buildDisplayOptionsCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Header Text'),
          _buildTextFieldCard(
            _headerController,
            'Header Text',
            'Enter business name or header',
            Icons.business,
            2,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Footer Text'),
          _buildTextFieldCard(
            _footerController,
            'Footer Text',
            'Enter footer message',
            Icons.text_fields,
            2,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Thank You Message'),
          _buildTextFieldCard(
            _thankYouController,
            'Thank You Message',
            'Enter thank you message',
            Icons.favorite,
            3,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Terms & Conditions'),
          _buildTextFieldCard(
            _termsController,
            'Terms & Conditions',
            'Enter terms and conditions (optional)',
            Icons.description,
            4,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Print Options'),
          _buildPrintOptionsCard(),
          const SizedBox(height: 24),

          // Kitchen Docket Settings Link
          _buildSectionHeader('🍳 Kitchen Docket Settings'),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.restaurant_menu,
                color: Color(0xFF2563EB),
              ),
              title: const Text('Kitchen Docket Configuration'),
              subtitle: const Text(
                'Customize kitchen printing templates and settings',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KitchenDocketSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Helper widget for paper size selection with radio button styling
class _PaperSizeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaperSizeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : Colors.grey[600];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
