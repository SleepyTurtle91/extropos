import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class ReceiptTemplateCustomizationScreen extends StatefulWidget {
  const ReceiptTemplateCustomizationScreen({super.key});

  @override
  State<ReceiptTemplateCustomizationScreen> createState() =>
      _ReceiptTemplateCustomizationScreenState();
}

class _ReceiptTemplateCustomizationScreenState
    extends State<ReceiptTemplateCustomizationScreen> {
  late ReceiptSettings _settings;
  bool _isLoading = true;
  bool _hasChanges = false;

  // Form Controllers
  late TextEditingController _headerController;
  late TextEditingController _footerController;
  late TextEditingController _thankYouController;
  late TextEditingController _termsController;
  late TextEditingController _taxIdController;
  late TextEditingController _wifiDetailsController;
  late ReceiptPaperSize _selectedPaperSize;

  @override
  void initState() {
    super.initState();
    _loadReceiptSettings();
  }

  Future<void> _loadReceiptSettings() async {
    try {
      final settings = await DatabaseService.instance.getReceiptSettings();
      setState(() {
        _settings = settings;
        _headerController = TextEditingController(text: _settings.headerText);
        _footerController = TextEditingController(text: _settings.footerText);
        _thankYouController =
            TextEditingController(text: _settings.thankYouMessage);
        _termsController =
            TextEditingController(text: _settings.termsAndConditions);
        _taxIdController = TextEditingController(text: _settings.taxIdText);
        _wifiDetailsController =
            TextEditingController(text: _settings.wifiDetails);
        _selectedPaperSize = _settings.paperSize;
        _isLoading = false;
      });
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to load receipt settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final updated = ReceiptSettings(
        headerText: _headerController.text,
        footerText: _footerController.text,
        thankYouMessage: _thankYouController.text,
        termsAndConditions: _termsController.text,
        taxIdText: _taxIdController.text,
        wifiDetails: _wifiDetailsController.text,
        showLogo: _settings.showLogo,
        showDateTime: _settings.showDateTime,
        showOrderNumber: _settings.showOrderNumber,
        showCashierName: _settings.showCashierName,
        showTaxBreakdown: _settings.showTaxBreakdown,
        showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
        showThankYouMessage: _settings.showThankYouMessage,
        showTaxId: _settings.showTaxId,
        showWifiDetails: _settings.showWifiDetails,
        showBarcode: _settings.showBarcode,
        barcodeData: _settings.barcodeData,
        showQrCode: _settings.showQrCode,
        qrData: _settings.qrData,
        autoPrint: _settings.autoPrint,
        paperSize: _selectedPaperSize,
        paperWidth: _selectedPaperSize == ReceiptPaperSize.mm58 ? 58 : 80,
        fontSize: _settings.fontSize,
        kitchenHeaderText: _settings.kitchenHeaderText,
        kitchenFooterText: _settings.kitchenFooterText,
        kitchenShowDateTime: _settings.kitchenShowDateTime,
        kitchenShowTable: _settings.kitchenShowTable,
        kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
        kitchenShowModifiers: _settings.kitchenShowModifiers,
        kitchenFontSize: _settings.kitchenFontSize,
        kitchenTemplateStyle: _settings.kitchenTemplateStyle,
      );

      await DatabaseService.instance.saveReceiptSettings(updated);
      setState(() {
        _settings = updated;
        _hasChanges = false;
      });
      if (mounted) {
        ToastHelper.showToast(context, 'Receipt settings saved successfully');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to save receipt settings: $e');
    }
  }

  void _updateSetting(String field, dynamic value) {
    setState(() {
      _hasChanges = true;
      switch (field) {
        case 'showLogo':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: value,
            showDateTime: _settings.showDateTime,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'showDateTime':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: value,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'showOrderNumber':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: _settings.showDateTime,
            showOrderNumber: value,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'showCashierName':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: _settings.showDateTime,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: value,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'showTaxBreakdown':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: _settings.showDateTime,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: value,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'showServiceChargeBreakdown':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: _settings.showDateTime,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: value,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'showThankYouMessage':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: _settings.showDateTime,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: value,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'autoPrint':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: _settings.showDateTime,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: value,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: _settings.fontSize,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'fontSize':
          _settings = ReceiptSettings(
            headerText: _settings.headerText,
            footerText: _settings.footerText,
            showLogo: _settings.showLogo,
            showDateTime: _settings.showDateTime,
            showOrderNumber: _settings.showOrderNumber,
            showCashierName: _settings.showCashierName,
            showTaxBreakdown: _settings.showTaxBreakdown,
            showServiceChargeBreakdown: _settings.showServiceChargeBreakdown,
            showThankYouMessage: _settings.showThankYouMessage,
            showTaxId: _settings.showTaxId,
            taxIdText: _settings.taxIdText,
            showWifiDetails: _settings.showWifiDetails,
            wifiDetails: _settings.wifiDetails,
            showBarcode: _settings.showBarcode,
            barcodeData: _settings.barcodeData,
            showQrCode: _settings.showQrCode,
            qrData: _settings.qrData,
            autoPrint: _settings.autoPrint,
            paperSize: _settings.paperSize,
            paperWidth: _settings.paperWidth,
            fontSize: value,
            thankYouMessage: _settings.thankYouMessage,
            termsAndConditions: _settings.termsAndConditions,
            kitchenHeaderText: _settings.kitchenHeaderText,
            kitchenFooterText: _settings.kitchenFooterText,
            kitchenShowDateTime: _settings.kitchenShowDateTime,
            kitchenShowTable: _settings.kitchenShowTable,
            kitchenShowOrderNumber: _settings.kitchenShowOrderNumber,
            kitchenShowModifiers: _settings.kitchenShowModifiers,
            kitchenFontSize: _settings.kitchenFontSize,
            kitchenTemplateStyle: _settings.kitchenTemplateStyle,
          );
          break;
        case 'paperSize':
          _selectedPaperSize = value as ReceiptPaperSize;
          break;
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _thankYouController.dispose();
    _termsController.dispose();
    _taxIdController.dispose();
    _wifiDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receipt Template Customization')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Template Customization'),
        elevation: 0,
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Settings
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Text
                  Text(
                    'Receipt Content',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      labelText: 'Header Text',
                      hintText: 'e.g., My Coffee Shop',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _footerController,
                    decoration: const InputDecoration(
                      labelText: 'Footer Text',
                      hintText: 'e.g., Thank you for your business!',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _thankYouController,
                    decoration: const InputDecoration(
                      labelText: 'Thank You Message',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _termsController,
                    decoration: const InputDecoration(
                      labelText: 'Terms & Conditions (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                  const SizedBox(height: 24),

                  // Display Options
                  Text(
                    'Display Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Show Logo'),
                    value: _settings.showLogo,
                    onChanged: (value) =>
                        _updateSetting('showLogo', value ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Show Date & Time'),
                    value: _settings.showDateTime,
                    onChanged: (value) =>
                        _updateSetting('showDateTime', value ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Show Order Number'),
                    value: _settings.showOrderNumber,
                    onChanged: (value) =>
                        _updateSetting('showOrderNumber', value ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Show Cashier Name'),
                    value: _settings.showCashierName,
                    onChanged: (value) =>
                        _updateSetting('showCashierName', value ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Show Tax Breakdown'),
                    value: _settings.showTaxBreakdown,
                    onChanged: (value) =>
                        _updateSetting('showTaxBreakdown', value ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Show Service Charge'),
                    value: _settings.showServiceChargeBreakdown,
                    onChanged: (value) => _updateSetting(
                        'showServiceChargeBreakdown', value ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Show Thank You Message'),
                    value: _settings.showThankYouMessage,
                    onChanged: (value) =>
                        _updateSetting('showThankYouMessage', value ?? false),
                  ),
                  const SizedBox(height: 24),

                  // Printing Options
                  Text(
                    'Printing Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Auto-Print Receipt'),
                    subtitle: const Text('Print immediately after payment'),
                    value: _settings.autoPrint,
                    onChanged: (value) =>
                        _updateSetting('autoPrint', value ?? false),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Receipt Paper Size',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ReceiptPaperSize>(
                    segments: const [
                      ButtonSegment(
                        value: ReceiptPaperSize.mm58,
                        label: Text('58mm'),
                        icon: Icon(Icons.receipt),
                      ),
                      ButtonSegment(
                        value: ReceiptPaperSize.mm80,
                        label: Text('80mm'),
                        icon: Icon(Icons.receipt_long),
                      ),
                    ],
                    selected: {_selectedPaperSize},
                    onSelectionChanged: (Set<ReceiptPaperSize> selected) {
                      _updateSetting('paperSize', selected.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Font Size: ${_settings.fontSize}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.fontSize.toDouble(),
                    min: 10,
                    max: 32,
                    divisions: 22,
                    label: _settings.fontSize.toString(),
                    onChanged: (value) =>
                        _updateSetting('fontSize', value.toInt()),
                  ),
                ],
              ),
            ),
          ),

          // Right Panel: Live Preview
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Live Preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Header
                            if (_settings.headerText.isNotEmpty)
                              Text(
                                _settings.headerText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: (_settings.fontSize * 0.9).toDouble(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),

                            // Date/Time
                            if (_settings.showDateTime)
                              Text(
                                '${DateTime.now().toString().split('.')[0]}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      (_settings.fontSize * 0.7).toDouble(),
                                ),
                              ),

                            // Order Number
                            if (_settings.showOrderNumber)
                              Text(
                                'Order #12345',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      (_settings.fontSize * 0.7).toDouble(),
                                ),
                              ),

                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),

                            // Items
                            Text(
                              'Sample Item 1        RM 10.00',
                              style: TextStyle(
                                fontSize: (_settings.fontSize * 0.8).toDouble(),
                              ),
                            ),
                            Text(
                              'Sample Item 2        RM 15.00',
                              style: TextStyle(
                                fontSize: (_settings.fontSize * 0.8).toDouble(),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),

                            // Totals
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal',
                                    style: TextStyle(
                                      fontSize:
                                          (_settings.fontSize * 0.75).toDouble(),
                                    )),
                                Text('RM 25.00',
                                    style: TextStyle(
                                      fontSize:
                                          (_settings.fontSize * 0.75).toDouble(),
                                    )),
                              ],
                            ),

                            // Tax
                            if (_settings.showTaxBreakdown)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tax (8%)',
                                      style: TextStyle(
                                        fontSize:
                                            (_settings.fontSize * 0.75).toDouble(),
                                      )),
                                  Text('RM 2.00',
                                      style: TextStyle(
                                        fontSize:
                                            (_settings.fontSize * 0.75).toDouble(),
                                      )),
                                ],
                              ),

                            const SizedBox(height: 4),
                            Container(
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),

                            // Total
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: TextStyle(
                                      fontSize:
                                          (_settings.fontSize * 0.8).toDouble(),
                                      fontWeight: FontWeight.bold,
                                    )),
                                Text('RM 27.00',
                                    style: TextStyle(
                                      fontSize:
                                          (_settings.fontSize * 0.8).toDouble(),
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: Colors.grey.shade400,
                            ),

                            // Footer
                            if (_settings.showThankYouMessage)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _settings.thankYouMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize:
                                        (_settings.fontSize * 0.75).toDouble(),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            if (_settings.footerText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _settings.footerText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize:
                                        (_settings.fontSize * 0.7).toDouble(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
