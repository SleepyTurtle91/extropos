import 'dart:convert';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual receipt designer screen with drag-and-drop layout builder
class ReceiptDesignerScreen extends StatefulWidget {
  const ReceiptDesignerScreen({super.key});

  @override
  State<ReceiptDesignerScreen> createState() => _ReceiptDesignerScreenState();
}

class _ReceiptDesignerScreenState extends State<ReceiptDesignerScreen> {
  late ReceiptSettings _settings;
  bool _isLoading = true;

  // Receipt template structure
  List<ReceiptElement> _receiptElements = [];
  ReceiptElement? _selectedElement;

  // Preview settings
  bool _showPreview = true;
  double _previewZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseService.instance.getReceiptSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _initializeDefaultTemplate();
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading receipt settings: $e');
      if (!mounted) return;
      setState(() {
        _settings = ReceiptSettings();
        _initializeDefaultTemplate();
        _isLoading = false;
      });
    }
  }

  void _initializeDefaultTemplate() {
    _receiptElements = [
      ReceiptElement(
        type: ElementType.header,
        content: _settings.headerText,
        alignment: TextAlign.center,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        order: 0,
      ),
      ReceiptElement(
        type: ElementType.businessInfo,
        content: 'Business Name & Address',
        alignment: TextAlign.center,
        fontSize: 12,
        order: 1,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 12,
        order: 2,
      ),
      ReceiptElement(
        type: ElementType.orderInfo,
        content: 'Date, Time, Order Number',
        alignment: TextAlign.left,
        fontSize: 12,
        order: 3,
      ),
      ReceiptElement(
        type: ElementType.itemsTable,
        content: 'Items List',
        alignment: TextAlign.left,
        fontSize: 12,
        order: 4,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 12,
        order: 5,
      ),
      ReceiptElement(
        type: ElementType.totals,
        content: 'Subtotal, Tax, Service Charge, Total',
        alignment: TextAlign.right,
        fontSize: 12,
        order: 6,
      ),
      ReceiptElement(
        type: ElementType.paymentInfo,
        content: 'Payment Method, Amount Paid, Change',
        alignment: TextAlign.left,
        fontSize: 12,
        order: 7,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 12,
        order: 8,
      ),
      ReceiptElement(
        type: ElementType.footer,
        content: _settings.thankYouMessage,
        alignment: TextAlign.center,
        fontSize: 12,
        order: 9,
      ),
    ];
  }

  Future<void> _saveTemplate() async {
    try {
      // Convert receipt elements to settings
      // This would require extending ReceiptSettings model
      await DatabaseService.instance.saveReceiptSettings(_settings);
      if (!mounted) return;
      ToastHelper.showToast(context, 'Receipt template saved successfully!');
    } catch (e) {
      developer.log('Error saving template: $e');
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error saving template: $e');
    }
  }

  Future<void> _testPrint() async {
    try {
      if (!mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing test receipt...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Get sample receipt data
      final receiptData = _generateSampleReceiptData();

      // Load printers
      final printers = await DatabaseService.instance.getPrinters();
      final receiptPrinters = printers
          .where((p) => p.type == PrinterType.receipt)
          .toList();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (receiptPrinters.isEmpty) {
        ToastHelper.showToast(
          context,
          'No receipt printers configured. Please add a printer in Settings.',
        );
        return;
      }

      // Show printer selection if multiple printers
      final printer = receiptPrinters.length == 1
          ? receiptPrinters.first
          : await showDialog<Printer>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Select Printer'),
                children: receiptPrinters
                    .map((p) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, p),
                          child: ListTile(
                            leading: Icon(
                              p.isDefault ? Icons.star : Icons.print,
                              color: p.isDefault ? Colors.amber : null,
                            ),
                            title: Text(p.name),
                            subtitle: Text(p.connectionType.name),
                          ),
                        ))
                    .toList(),
              ),
            );

      if (printer == null || !mounted) return;

      // Print test receipt
      final success = await PrinterService().printReceipt(printer, receiptData);

      if (!mounted) return;
      if (success) {
        ToastHelper.showToast(context, '✅ Test print sent successfully!');
      } else {
        ToastHelper.showToast(
          context,
          '❌ Test print failed. Check printer connection.',
        );
      }
    } catch (e) {
      developer.log('Test print error: $e');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close any dialogs
      ToastHelper.showToast(context, 'Test print error: $e');
    }
  }

  Map<String, dynamic> _generateSampleReceiptData() {
    final info = BusinessInfo.instance;
    return {
      'businessName': info.businessName,
      'address': info.fullAddress,
      'taxNumber': info.taxNumber ?? '',
      'orderNumber': '001',
      'dateTime': DateTime.now().toIso8601String(),
      'items': [
        {
          'name': 'Sample Item 1',
          'quantity': 2,
          'price': 10.00,
          'total': 20.00,
          'modifiers': [],
        },
        {
          'name': 'Sample Item 2',
          'quantity': 1,
          'price': 15.50,
          'total': 15.50,
          'modifiers': [
            {'name': 'Extra Cheese', 'priceAdjustment': 2.00},
          ],
        },
      ],
      'subtotal': 35.50,
      'tax': info.isTaxEnabled ? 35.50 * info.taxRate : 0.0,
      'serviceCharge': info.isServiceChargeEnabled
          ? 35.50 * info.serviceChargeRate
          : 0.0,
      'total':
          35.50 +
          (info.isTaxEnabled ? 35.50 * info.taxRate : 0.0) +
          (info.isServiceChargeEnabled ? 35.50 * info.serviceChargeRate : 0.0),
      'paymentMethod': 'Cash',
      'amountPaid': 50.00,
      'change':
          50.00 -
          (35.50 +
              (info.isTaxEnabled ? 35.50 * info.taxRate : 0.0) +
              (info.isServiceChargeEnabled
                  ? 35.50 * info.serviceChargeRate
                  : 0.0)),
      'currency': info.currencySymbol,
      'merchantId': '',
    };
  }

  Future<void> _showPresetDialog() async {
    final preset = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Template Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPresetTile(
              'Minimal',
              'Simple, clean layout with essentials only',
              Icons.minimize,
            ),
            _buildPresetTile(
              'Standard',
              'Balanced layout with all key information',
              Icons.receipt,
            ),
            _buildPresetTile(
              'Detailed',
              'Comprehensive layout with extra details',
              Icons.article,
            ),
            _buildPresetTile(
              'Modern',
              'Contemporary design with visual elements',
              Icons.auto_awesome,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (preset != null) {
      _loadPreset(preset);
    }
  }

  Widget _buildPresetTile(String name, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        onTap: () => Navigator.pop(context, name),
      ),
    );
  }

  void _loadPreset(String presetName) {
    setState(() {
      switch (presetName) {
        case 'Minimal':
          _receiptElements = _getMinimalPreset();
          break;
        case 'Standard':
          _initializeDefaultTemplate();
          break;
        case 'Detailed':
          _receiptElements = _getDetailedPreset();
          break;
        case 'Modern':
          _receiptElements = _getModernPreset();
          break;
      }
      _selectedElement = null;
    });
    ToastHelper.showToast(context, '$presetName template loaded');
  }

  List<ReceiptElement> _getMinimalPreset() {
    return [
      ReceiptElement(
        type: ElementType.header,
        content: _settings.headerText,
        alignment: TextAlign.center,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        order: 0,
      ),
      ReceiptElement(
        type: ElementType.orderInfo,
        content: 'Order #, Date',
        alignment: TextAlign.left,
        fontSize: 11,
        order: 1,
        spacingBefore: 1,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 10,
        order: 2,
      ),
      ReceiptElement(
        type: ElementType.itemsTable,
        content: 'Items',
        alignment: TextAlign.left,
        fontSize: 11,
        order: 3,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 10,
        order: 4,
      ),
      ReceiptElement(
        type: ElementType.totals,
        content: 'Total',
        alignment: TextAlign.right,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        order: 5,
      ),
      ReceiptElement(
        type: ElementType.footer,
        content: 'Thank you!',
        alignment: TextAlign.center,
        fontSize: 11,
        order: 6,
        spacingBefore: 2,
      ),
    ];
  }

  List<ReceiptElement> _getDetailedPreset() {
    return [
      ReceiptElement(
        type: ElementType.logo,
        content: 'Logo',
        alignment: TextAlign.center,
        fontSize: 12,
        order: 0,
      ),
      ReceiptElement(
        type: ElementType.header,
        content: _settings.headerText,
        alignment: TextAlign.center,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        order: 1,
        spacingAfter: 1,
      ),
      ReceiptElement(
        type: ElementType.businessInfo,
        content: 'Business Info',
        alignment: TextAlign.center,
        fontSize: 11,
        order: 2,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 10,
        order: 3,
        spacingBefore: 1,
      ),
      ReceiptElement(
        type: ElementType.orderInfo,
        content: 'Order Details',
        alignment: TextAlign.left,
        fontSize: 11,
        order: 4,
      ),
      ReceiptElement(
        type: ElementType.customerInfo,
        content: 'Customer Info',
        alignment: TextAlign.left,
        fontSize: 11,
        order: 5,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 10,
        order: 6,
      ),
      ReceiptElement(
        type: ElementType.itemsTable,
        content: 'Items',
        alignment: TextAlign.left,
        fontSize: 11,
        order: 7,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 10,
        order: 8,
      ),
      ReceiptElement(
        type: ElementType.totals,
        content: 'Totals',
        alignment: TextAlign.right,
        fontSize: 11,
        order: 9,
      ),
      ReceiptElement(
        type: ElementType.paymentInfo,
        content: 'Payment',
        alignment: TextAlign.left,
        fontSize: 11,
        order: 10,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '━' * 32,
        alignment: TextAlign.center,
        fontSize: 10,
        order: 11,
        spacingBefore: 1,
      ),
      ReceiptElement(
        type: ElementType.qrCode,
        content: 'QR Code',
        alignment: TextAlign.center,
        fontSize: 12,
        order: 12,
      ),
      ReceiptElement(
        type: ElementType.footer,
        content: _settings.thankYouMessage,
        alignment: TextAlign.center,
        fontSize: 11,
        order: 13,
        spacingBefore: 1,
      ),
      ReceiptElement(
        type: ElementType.customText,
        content: _settings.termsAndConditions.isNotEmpty
            ? 'Terms & Conditions'
            : '',
        alignment: TextAlign.center,
        fontSize: 9,
        order: 14,
      ),
    ];
  }

  List<ReceiptElement> _getModernPreset() {
    return [
      ReceiptElement(
        type: ElementType.header,
        content: _settings.headerText.toUpperCase(),
        alignment: TextAlign.center,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        order: 0,
        spacingAfter: 1,
      ),
      ReceiptElement(
        type: ElementType.businessInfo,
        content: 'Business Name & Contact',
        alignment: TextAlign.center,
        fontSize: 12,
        order: 1,
      ),
      ReceiptElement(
        type: ElementType.spacer,
        content: '',
        alignment: TextAlign.center,
        fontSize: 12,
        order: 2,
      ),
      ReceiptElement(
        type: ElementType.orderInfo,
        content: 'Order Info',
        alignment: TextAlign.left,
        fontSize: 12,
        order: 3,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '═' * 32,
        alignment: TextAlign.center,
        fontSize: 12,
        order: 4,
        spacingBefore: 1,
      ),
      ReceiptElement(
        type: ElementType.itemsTable,
        content: 'Items',
        alignment: TextAlign.left,
        fontSize: 12,
        order: 5,
      ),
      ReceiptElement(
        type: ElementType.divider,
        content: '═' * 32,
        alignment: TextAlign.center,
        fontSize: 12,
        order: 6,
      ),
      ReceiptElement(
        type: ElementType.totals,
        content: 'Totals',
        alignment: TextAlign.right,
        fontSize: 12,
        order: 7,
      ),
      ReceiptElement(
        type: ElementType.paymentInfo,
        content: 'Payment',
        alignment: TextAlign.left,
        fontSize: 12,
        order: 8,
      ),
      ReceiptElement(
        type: ElementType.spacer,
        content: '',
        alignment: TextAlign.center,
        fontSize: 12,
        order: 9,
      ),
      ReceiptElement(
        type: ElementType.qrCode,
        content: 'Scan for digital receipt',
        alignment: TextAlign.center,
        fontSize: 10,
        order: 10,
      ),
      ReceiptElement(
        type: ElementType.spacer,
        content: '',
        alignment: TextAlign.center,
        fontSize: 12,
        order: 11,
      ),
      ReceiptElement(
        type: ElementType.footer,
        content: _settings.thankYouMessage,
        alignment: TextAlign.center,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        order: 12,
      ),
    ];
  }

  Future<void> _exportTemplate() async {
    try {
      // Create template data
      final templateData = {
        'version': '1.0',
        'name': 'Custom Receipt Template',
        'elements': _receiptElements
            .map(
              (e) => {
                'type': e.type.name,
                'content': e.content,
                'alignment': e.alignment.name,
                'fontSize': e.fontSize,
                'fontWeight': e.fontWeight.index,
                'spacingBefore': e.spacingBefore,
                'spacingAfter': e.spacingAfter,
                'order': e.order,
              },
            )
            .toList(),
      };

      // Convert to JSON string (prettified)
      final jsonEncoder = const JsonEncoder.withIndent('  ');
      final jsonString = jsonEncoder.convert(templateData);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (!mounted) return;
      ToastHelper.showToast(
        context,
        'Template exported to clipboard! You can save it to a file.',
      );

      // Show export dialog with the JSON
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Template Exported'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonString));
                if (!mounted) return;
                ToastHelper.showToast(context, 'Copied to clipboard');
              },
              child: const Text('Copy Again'),
            ),
          ],
        ),
      );
    } catch (e) {
      developer.log('Export error: $e');
      if (!mounted) return;
      ToastHelper.showToast(context, 'Export error: $e');
    }
  }

  Future<void> _importTemplate() async {
    final controller = TextEditingController();

    final imported = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your template JSON below:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{\n  "version": "1.0",\n  ...\n}',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (imported != true || controller.text.isEmpty) return;

    try {
      final data = jsonDecode(controller.text) as Map<String, dynamic>;
      final elements = (data['elements'] as List).map((e) {
        return ReceiptElement(
          type: ElementType.values.firstWhere((t) => t.name == e['type']),
          content: e['content'] as String,
          alignment: TextAlign.values.firstWhere(
            (a) => a.name == e['alignment'],
            orElse: () => TextAlign.left,
          ),
          fontSize: e['fontSize'] as int,
          fontWeight: FontWeight.values[e['fontWeight'] as int],
          spacingBefore: e['spacingBefore'] as int? ?? 0,
          spacingAfter: e['spacingAfter'] as int? ?? 0,
          order: e['order'] as int,
        );
      }).toList();

      setState(() {
        _receiptElements = elements;
        _selectedElement = null;
      });

      if (!mounted) return;
      ToastHelper.showToast(context, 'Template imported successfully!');
    } catch (e) {
      developer.log('Import error: $e');
      if (!mounted) return;
      ToastHelper.showToast(context, 'Import error: Invalid JSON format');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Designer'),
        backgroundColor: const Color(0xFF2563EB),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
            tooltip: _showPreview ? 'Hide Preview' : 'Show Preview',
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Template',
            onPressed: _saveTemplate,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
            onSelected: (value) async {
              switch (value) {
                case 'test_print':
                  await _testPrint();
                  break;
                case 'load_preset':
                  await _showPresetDialog();
                  break;
                case 'export':
                  await _exportTemplate();
                  break;
                case 'import':
                  await _importTemplate();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test_print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Test Print'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'load_preset',
                child: Row(
                  children: [
                    Icon(Icons.palette),
                    SizedBox(width: 8),
                    Text('Load Preset'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('Export Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Import Template'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Default',
            onPressed: () {
              setState(() {
                _initializeDefaultTemplate();
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Element Library
          SizedBox(width: 250, child: _buildElementLibrary()),

          // Center Panel - Receipt Builder
          Expanded(flex: 3, child: _buildReceiptBuilder()),

          // Right Panel - Properties & Preview
          if (_showPreview)
            SizedBox(
              width: 350,
              child: Column(
                children: [
                  // Properties Panel
                  Expanded(flex: 2, child: _buildPropertiesPanel()),

                  const Divider(height: 1),

                  // Live Preview
                  Expanded(flex: 3, child: _buildLivePreview()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildElementLibrary() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Text(
              'Element Library',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildElementTile(
                  ElementType.header,
                  Icons.title,
                  'Header Text',
                  'Main receipt title',
                ),
                _buildElementTile(
                  ElementType.businessInfo,
                  Icons.business,
                  'Business Info',
                  'Name, address, phone',
                ),
                _buildElementTile(
                  ElementType.logo,
                  Icons.image,
                  'Logo',
                  'Business logo image',
                ),
                _buildElementTile(
                  ElementType.orderInfo,
                  Icons.receipt,
                  'Order Info',
                  'Order #, date, time',
                ),
                _buildElementTile(
                  ElementType.customerInfo,
                  Icons.person,
                  'Customer Info',
                  'Name, phone, email',
                ),
                _buildElementTile(
                  ElementType.itemsTable,
                  Icons.list,
                  'Items Table',
                  'Ordered items list',
                ),
                _buildElementTile(
                  ElementType.totals,
                  Icons.calculate,
                  'Totals',
                  'Subtotal, tax, total',
                ),
                _buildElementTile(
                  ElementType.paymentInfo,
                  Icons.payment,
                  'Payment Info',
                  'Payment method, change',
                ),
                _buildElementTile(
                  ElementType.qrCode,
                  Icons.qr_code,
                  'QR Code',
                  'Receipt QR code',
                ),
                _buildElementTile(
                  ElementType.barcode,
                  Icons.barcode_reader,
                  'Barcode',
                  'Receipt barcode',
                ),
                _buildElementTile(
                  ElementType.divider,
                  Icons.horizontal_rule,
                  'Divider',
                  'Separator line',
                ),
                _buildElementTile(
                  ElementType.spacer,
                  Icons.space_bar,
                  'Spacer',
                  'Blank space',
                ),
                _buildElementTile(
                  ElementType.footer,
                  Icons.message,
                  'Footer Text',
                  'Thank you message',
                ),
                _buildElementTile(
                  ElementType.customText,
                  Icons.text_fields,
                  'Custom Text',
                  'Any custom text',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementTile(
    ElementType type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        dense: true,
        onTap: () => _addElement(type),
      ),
    );
  }

  void _addElement(ElementType type) {
    setState(() {
      final newElement = ReceiptElement(
        type: type,
        content: _getDefaultContent(type),
        alignment: _getDefaultAlignment(type),
        fontSize: 12,
        order: _receiptElements.length,
      );
      _receiptElements.add(newElement);
    });
  }

  String _getDefaultContent(ElementType type) {
    switch (type) {
      case ElementType.header:
        return 'RECEIPT';
      case ElementType.businessInfo:
        return BusinessInfo.instance.businessName;
      case ElementType.footer:
        return 'Thank you!';
      case ElementType.divider:
        return '━' * 32;
      case ElementType.spacer:
        return '';
      default:
        return type.name.toUpperCase();
    }
  }

  TextAlign _getDefaultAlignment(ElementType type) {
    switch (type) {
      case ElementType.header:
      case ElementType.businessInfo:
      case ElementType.footer:
      case ElementType.divider:
      case ElementType.logo:
      case ElementType.qrCode:
      case ElementType.barcode:
        return TextAlign.center;
      case ElementType.totals:
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Widget _buildReceiptBuilder() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'Receipt Layout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear All',
                  onPressed: () {
                    setState(() {
                      _receiptElements.clear();
                      _selectedElement = null;
                    });
                  },
                ),
              ],
            ),
          ),

          // Receipt Builder Area
          Expanded(
            child: _receiptElements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drag elements from the library\nto build your receipt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _receiptElements.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex--;
                        }
                        final element = _receiptElements.removeAt(oldIndex);
                        _receiptElements.insert(newIndex, element);
                        // Update order values
                        for (int i = 0; i < _receiptElements.length; i++) {
                          _receiptElements[i].order = i;
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      final element = _receiptElements[index];
                      final isSelected = _selectedElement == element;

                      return Card(
                        key: ValueKey(element.id),
                        color: isSelected
                            ? const Color(0xFF2563EB).withOpacity(0.1)
                            : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _getElementIcon(element.type),
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.grey[600],
                          ),
                          title: Text(
                            element.type.displayName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            element.content.isEmpty
                                ? '(empty)'
                                : element.content.length > 50
                                ? '${element.content.substring(0, 50)}...'
                                : element.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedElement = element;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _receiptElements.remove(element);
                                    if (_selectedElement == element) {
                                      _selectedElement = null;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedElement = element;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getElementIcon(ElementType type) {
    switch (type) {
      case ElementType.header:
        return Icons.title;
      case ElementType.businessInfo:
        return Icons.business;
      case ElementType.logo:
        return Icons.image;
      case ElementType.orderInfo:
        return Icons.receipt;
      case ElementType.customerInfo:
        return Icons.person;
      case ElementType.itemsTable:
        return Icons.list;
      case ElementType.totals:
        return Icons.calculate;
      case ElementType.paymentInfo:
        return Icons.payment;
      case ElementType.qrCode:
        return Icons.qr_code;
      case ElementType.barcode:
        return Icons.barcode_reader;
      case ElementType.divider:
        return Icons.horizontal_rule;
      case ElementType.spacer:
        return Icons.space_bar;
      case ElementType.footer:
        return Icons.message;
      case ElementType.customText:
        return Icons.text_fields;
    }
  }

  Widget _buildPropertiesPanel() {
    if (_selectedElement == null) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Text(
            'Select an element to edit properties',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Properties',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Content
          if (_selectedElement!.type == ElementType.customText ||
              _selectedElement!.type == ElementType.header ||
              _selectedElement!.type == ElementType.footer) ...[
            const Text(
              'Content:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _selectedElement!.content)
                ..selection = TextSelection.collapsed(
                  offset: _selectedElement!.content.length,
                ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter text',
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _selectedElement!.content = value;
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Alignment
          const Text(
            'Alignment:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<TextAlign>(
            segments: const [
              ButtonSegment(
                value: TextAlign.left,
                icon: Icon(Icons.format_align_left, size: 18),
                label: Text('Left'),
              ),
              ButtonSegment(
                value: TextAlign.center,
                icon: Icon(Icons.format_align_center, size: 18),
                label: Text('Center'),
              ),
              ButtonSegment(
                value: TextAlign.right,
                icon: Icon(Icons.format_align_right, size: 18),
                label: Text('Right'),
              ),
            ],
            selected: {_selectedElement!.alignment},
            onSelectionChanged: (Set<TextAlign> selection) {
              setState(() {
                _selectedElement!.alignment = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),

          // Font Size
          const Text(
            'Font Size:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _selectedElement!.fontSize.toDouble(),
                  min: 8,
                  max: 32,
                  divisions: 24,
                  label: '${_selectedElement!.fontSize}pt',
                  onChanged: (value) {
                    setState(() {
                      _selectedElement!.fontSize = value.toInt();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${_selectedElement!.fontSize}pt',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Font Weight
          const Text(
            'Font Weight:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<FontWeight>(
            value: _selectedElement!.fontWeight,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: FontWeight.normal, child: Text('Normal')),
              DropdownMenuItem(value: FontWeight.bold, child: Text('Bold')),
              DropdownMenuItem(value: FontWeight.w300, child: Text('Light')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedElement!.fontWeight = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Spacing
          const Text(
            'Spacing (lines):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _selectedElement!.spacingBefore.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: '${_selectedElement!.spacingBefore}',
                  onChanged: (value) {
                    setState(() {
                      _selectedElement!.spacingBefore = value.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('Before'),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _selectedElement!.spacingAfter.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: '${_selectedElement!.spacingAfter}',
                  onChanged: (value) {
                    setState(() {
                      _selectedElement!.spacingAfter = value.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('After'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          // Preview Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[300],
            child: Row(
              children: [
                const Text(
                  'Live Preview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed: () {
                    setState(() {
                      _previewZoom = (_previewZoom - 0.1).clamp(0.5, 2.0);
                    });
                  },
                ),
                Text('${(_previewZoom * 100).toInt()}%'),
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: () {
                    setState(() {
                      _previewZoom = (_previewZoom + 0.1).clamp(0.5, 2.0);
                    });
                  },
                ),
              ],
            ),
          ),

          // Preview Area
          Expanded(
            child: Center(
              child: Transform.scale(
                scale: _previewZoom,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(child: _buildReceiptPreview()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _receiptElements.map((element) {
        return Column(
          children: [
            // Spacing before
            if (element.spacingBefore > 0)
              ...List.generate(
                element.spacingBefore,
                (_) => const SizedBox(height: 4),
              ),

            // Element content
            _buildElementPreview(element),

            // Spacing after
            if (element.spacingAfter > 0)
              ...List.generate(
                element.spacingAfter,
                (_) => const SizedBox(height: 4),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildElementPreview(ReceiptElement element) {
    switch (element.type) {
      case ElementType.divider:
        return Text(
          element.content,
          textAlign: element.alignment,
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontWeight: element.fontWeight,
            fontFamily: 'monospace',
          ),
        );

      case ElementType.spacer:
        return SizedBox(height: element.fontSize.toDouble());

      case ElementType.logo:
        return Icon(Icons.business, size: element.fontSize.toDouble() * 3);

      case ElementType.qrCode:
        return Icon(Icons.qr_code_2, size: element.fontSize.toDouble() * 5);

      case ElementType.barcode:
        return Container(
          height: element.fontSize.toDouble() * 3,
          alignment: Alignment.center,
          child: Text(
            '||||| ||||| ||||| |||||',
            style: TextStyle(
              fontSize: element.fontSize.toDouble() * 2,
              fontFamily: 'monospace',
            ),
          ),
        );

      case ElementType.itemsTable:
        return _buildItemsTablePreview(element);

      case ElementType.totals:
        return _buildTotalsPreview(element);

      default:
        return Text(
          element.content,
          textAlign: element.alignment,
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontWeight: element.fontWeight,
            fontFamily: 'monospace',
          ),
        );
    }
  }

  Widget _buildItemsTablePreview(ReceiptElement element) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item                 Qty  Amount',
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sample Item 1          2   20.00',
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'Another Item           1   15.50',
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsPreview(ReceiptElement element) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Subtotal:        RM 35.50',
          textAlign: element.alignment,
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'Tax (6%):         RM 2.13',
          textAlign: element.alignment,
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'Total:           RM 37.63',
          textAlign: element.alignment,
          style: TextStyle(
            fontSize: element.fontSize.toDouble(),
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// Receipt Element Model
class ReceiptElement {
  final String id;
  ElementType type;
  String content;
  TextAlign alignment;
  int fontSize;
  FontWeight fontWeight;
  int spacingBefore;
  int spacingAfter;
  int order;

  ReceiptElement({
    String? id,
    required this.type,
    required this.content,
    required this.alignment,
    required this.fontSize,
    this.fontWeight = FontWeight.normal,
    this.spacingBefore = 0,
    this.spacingAfter = 0,
    required this.order,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}

// Element Types
enum ElementType {
  header,
  businessInfo,
  logo,
  orderInfo,
  customerInfo,
  itemsTable,
  totals,
  paymentInfo,
  qrCode,
  barcode,
  divider,
  spacer,
  footer,
  customText,
}

extension ElementTypeExtension on ElementType {
  String get displayName {
    switch (this) {
      case ElementType.header:
        return 'Header Text';
      case ElementType.businessInfo:
        return 'Business Info';
      case ElementType.logo:
        return 'Logo';
      case ElementType.orderInfo:
        return 'Order Info';
      case ElementType.customerInfo:
        return 'Customer Info';
      case ElementType.itemsTable:
        return 'Items Table';
      case ElementType.totals:
        return 'Totals';
      case ElementType.paymentInfo:
        return 'Payment Info';
      case ElementType.qrCode:
        return 'QR Code';
      case ElementType.barcode:
        return 'Barcode';
      case ElementType.divider:
        return 'Divider';
      case ElementType.spacer:
        return 'Spacer';
      case ElementType.footer:
        return 'Footer';
      case ElementType.customText:
        return 'Custom Text';
    }
  }
}
