import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class OrderItem {
  final String name;
  final int qty;
  final double price;

  OrderItem(this.name, this.qty, this.price);
}

class ReceiptDesignerScreen extends StatefulWidget {
  const ReceiptDesignerScreen({super.key});

  @override
  State<ReceiptDesignerScreen> createState() => _ReceiptDesignerScreenState();
}

class _ReceiptDesignerScreenState extends State<ReceiptDesignerScreen> {
  static const _indigo = Color(0xFF4F46E5);
  static const _emerald = Color(0xFF10B981);

  bool _isLoading = true;
  ReceiptSettings _settings = ReceiptSettings();

  // UI State
  String _paperSize = '80mm';
  String _activeTab = 'header';

  // Receipt Configuration State
  bool _showLogo = true;
  String _storeName = '';
  String _address = '';
  String _taxId = '';
  bool _showTaxId = true;
  bool _showOrderNumber = true;
  String _itemFontSize = 'normal';
  bool _showBarcode = true;
  String _barcodeData = '';
  String _footerMessage = '';
  bool _showWifi = true;
  String _wifiDetails = 'WiFi: DailyGrind_Guest\nPass: coffee123';
  bool _showQrCode = true;
  String _qrData = '';

  final _storeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _wifiCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _qrCtrl = TextEditingController();

  final List<OrderItem> _mockItems = [
    OrderItem('Latte (Hot)', 1, 12.00),
    OrderItem('Avocado Toast', 1, 18.50),
    OrderItem('Espresso', 2, 16.00),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _taxIdCtrl.dispose();
    _footerCtrl.dispose();
    _wifiCtrl.dispose();
    _barcodeCtrl.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseService.instance.getReceiptSettings();
      final info = BusinessInfo.instance;
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _paperSize = settings.paperSize == ReceiptPaperSize.mm58
            ? '58mm'
            : '80mm';
        _showLogo = settings.showLogo;
        _showOrderNumber = settings.showOrderNumber;
        _showTaxId = settings.showTaxId;
        _showWifi = settings.showWifiDetails;
        _showBarcode = settings.showBarcode;
        _showQrCode = settings.showQrCode;
        _footerMessage = settings.thankYouMessage;
        _itemFontSize = _fontSizeToLabel(settings.fontSize);
        _storeName = info.businessName;
        _address = info.fullAddress;
        _taxId = settings.taxIdText.isNotEmpty
            ? settings.taxIdText
            : (info.taxNumber ?? '');
        _wifiDetails = settings.wifiDetails.isNotEmpty
            ? settings.wifiDetails
            : _wifiDetails;
        _barcodeData = settings.barcodeData;
        _qrData = settings.qrData;
        _storeNameCtrl.text = _storeName;
        _addressCtrl.text = _address;
        _taxIdCtrl.text = _taxId;
        _footerCtrl.text = _footerMessage;
        _wifiCtrl.text = _wifiDetails;
        _barcodeCtrl.text = _barcodeData;
        _qrCtrl.text = _qrData;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading receipt settings: $e');
      if (!mounted) return;
      setState(() {
        _settings = ReceiptSettings();
        _paperSize = '80mm';
        _showLogo = _settings.showLogo;
        _showOrderNumber = _settings.showOrderNumber;
        _showTaxId = _settings.showTaxId;
        _showWifi = _settings.showWifiDetails;
        _showBarcode = _settings.showBarcode;
        _showQrCode = _settings.showQrCode;
        _footerMessage = _settings.thankYouMessage;
        _itemFontSize = _fontSizeToLabel(_settings.fontSize);
        _footerCtrl.text = _footerMessage;
        _storeNameCtrl.text = _storeName;
        _addressCtrl.text = _address;
        _taxIdCtrl.text = _taxId;
        _wifiCtrl.text = _wifiDetails;
        _barcodeCtrl.text = _barcodeData;
        _qrCtrl.text = _qrData;
        _isLoading = false;
      });
    }
  }

  String _fontSizeToLabel(int size) {
    if (size <= 10) return 'small';
    if (size >= 14) return 'large';
    return 'normal';
  }

  int _fontLabelToSize(String label) {
    switch (label) {
      case 'small':
        return 10;
      case 'large':
        return 14;
      default:
        return 12;
    }
  }

  ReceiptPaperSize _paperLabelToSize(String label) {
    return label == '58mm' ? ReceiptPaperSize.mm58 : ReceiptPaperSize.mm80;
  }

  Future<void> _saveTemplate() async {
    final updatedSettings = _settings.copyWith(
      showLogo: _showLogo,
      showOrderNumber: _showOrderNumber,
      paperSize: _paperLabelToSize(_paperSize),
      paperWidth: _paperLabelToSize(_paperSize).widthInMm,
      fontSize: _fontLabelToSize(_itemFontSize),
      thankYouMessage: _footerMessage,
      showThankYouMessage: _footerMessage.trim().isNotEmpty,
      showTaxId: _showTaxId,
      taxIdText: _taxId.trim(),
      showWifiDetails: _showWifi,
      wifiDetails: _wifiDetails.trim(),
      showBarcode: _showBarcode,
      barcodeData: _barcodeData.trim(),
      showQrCode: _showQrCode,
      qrData: _qrData.trim(),
    );

    try {
      await DatabaseService.instance.saveReceiptSettings(updatedSettings);
      if (!mounted) return;
      setState(() => _settings = updatedSettings);
      ToastHelper.showToast(context, 'Receipt template saved');
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Failed to save: $e');
    }
  }

  Future<void> _printTest() async {
    try {
      final printers = await DatabaseService.instance.getPrinters();
      final receiptPrinters =
          printers.where((p) => p.type == PrinterType.receipt).toList();

      if (!mounted) return;

      if (receiptPrinters.isEmpty) {
        ToastHelper.showToast(
          context,
          'No receipt printers configured. Add one in Settings.',
        );
        return;
      }

      final printer = receiptPrinters.length == 1
          ? receiptPrinters.first
          : await showDialog<Printer>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Select Printer'),
                children: receiptPrinters
                    .map(
                      (p) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, p),
                        child: ListTile(
                          leading: Icon(
                            p.isDefault ? Icons.star : Icons.print,
                            color: p.isDefault ? Colors.amber : null,
                          ),
                          title: Text(p.name),
                          subtitle: Text(p.connectionType.name),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );

      if (printer == null || !mounted) return;

      final updatedSettings = _settings.copyWith(
        showLogo: _showLogo,
        showOrderNumber: _showOrderNumber,
        paperSize: _paperLabelToSize(_paperSize),
        paperWidth: _paperLabelToSize(_paperSize).widthInMm,
        fontSize: _fontLabelToSize(_itemFontSize),
        thankYouMessage: _footerMessage,
        showThankYouMessage: _footerMessage.trim().isNotEmpty,
        showTaxId: _showTaxId,
        taxIdText: _taxId.trim(),
        showWifiDetails: _showWifi,
        wifiDetails: _wifiDetails.trim(),
        showBarcode: _showBarcode,
        barcodeData: _barcodeData.trim(),
        showQrCode: _showQrCode,
        qrData: _qrData.trim(),
      );

      await DatabaseService.instance.saveReceiptSettings(updatedSettings);

      final receiptData = _buildSampleReceiptData();
      final charWidth = _paperSize == '58mm' ? 32 : 48;
      receiptData['content'] = generateReceiptTextWithSettings(
        data: receiptData,
        settings: updatedSettings,
        charWidth: charWidth,
        receiptType: ReceiptType.customer,
      );

      final success = await PrinterService().printReceipt(
        printer,
        receiptData,
        receiptType: ReceiptType.customer,
      );

      if (!mounted) return;
      ToastHelper.showToast(
        context,
        success ? 'Test print sent' : 'Test print failed',
      );
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Test print error: $e');
    }
  }

  Map<String, dynamic> _buildSampleReceiptData() {
    final now = DateTime.now();
    final addressLines = _address
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return {
      'store_name': _storeName,
      'address': addressLines,
      'title': 'RECEIPT',
      'date': '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'customer': 'Walk-in Customer',
      'bill_no': 'RCP-082',
      'payment_mode': 'Card',
      'dr_ref': 'TXN-20260222',
      'tax_id': _taxId,
      'wifi_details': _wifiDetails,
      'barcode': _barcodeData.isNotEmpty ? _barcodeData : 'RCP-082',
      'qr_data': _qrData,
      'items': _mockItems
          .map(
            (item) => {
              'name': item.name,
              'qty': item.qty,
              'amt': item.price,
            },
          )
          .toList(),
      'sub_total_qty': _mockItems.fold<int>(0, (sum, item) => sum + item.qty),
      'sub_total_amt': 46.50,
      'discount': 0.00,
      'taxes': [
        {'name': 'SST (8%)', 'amt': 3.72},
      ],
      'total': 50.22,
      'cash': 50.22,
      'cash_tendered': 50.22,
      'footer': _footerMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 450,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              children: [
                _buildPanelHeader(),
                _buildTabs(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: _buildActiveTabContent(),
                  ),
                ),
                _buildActionsFooter(),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  Positioned(
                    top: 32,
                    right: 32,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: _emerald,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Text(
                            '$_paperSize THERMAL OUTPUT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade500,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildThermalPreview(),
                        ],
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

  Widget _buildPanelHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _indigo,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _indigo.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.print, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Receipt Builder',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'THERMAL PRINT LAYOUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _buildPaperToggle('80mm', '80mm Width')),
                Expanded(child: _buildPaperToggle('58mm', '58mm Width')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperToggle(String id, String label) {
    final isActive = _paperSize == id;
    return GestureDetector(
      onTap: () => setState(() => _paperSize = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? _indigo : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildTabBtn('header', 'Header', Icons.format_align_left),
          _buildTabBtn('items', 'Items', Icons.shopping_bag),
          _buildTabBtn('footer', 'Footer', Icons.text_fields),
          _buildTabBtn('advanced', 'Advanced', Icons.tune),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String id, String label, IconData icon) {
    final isActive = _activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? _indigo : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? _indigo : Colors.grey.shade400,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isActive ? _indigo : Colors.grey.shade400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'header':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggle(
              'Show Store Logo',
              _showLogo,
              (v) => setState(() => _showLogo = v),
              icon: Icons.image,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'Store Name',
              controller: _storeNameCtrl,
              onChanged: (v) => setState(() => _storeName = v),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'Store Address',
              controller: _addressCtrl,
              onChanged: (v) => setState(() => _address = v),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildToggle(
              'Show Tax/SST ID',
              _showTaxId,
              (v) => setState(() => _showTaxId = v),
            ),
            if (_showTaxId) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'Tax/SST ID',
                controller: _taxIdCtrl,
                onChanged: (v) => setState(() => _taxId = v),
              ),
            ],
          ],
        );
      case 'items':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggle(
              'Show Order Number',
              _showOrderNumber,
              (v) => setState(() => _showOrderNumber = v),
            ),
            const SizedBox(height: 24),
            const Text(
              'ITEM FONT SIZE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildFontSizeBtn('small')),
                const SizedBox(width: 8),
                Expanded(child: _buildFontSizeBtn('normal')),
                const SizedBox(width: 8),
                Expanded(child: _buildFontSizeBtn('large')),
              ],
            )
          ],
        );
      case 'footer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              'Footer Message',
              controller: _footerCtrl,
              onChanged: (v) => setState(() => _footerMessage = v),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildToggle(
              'Show WiFi Details',
              _showWifi,
              (v) => setState(() => _showWifi = v),
            ),
            if (_showWifi) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'WiFi Information',
                controller: _wifiCtrl,
                onChanged: (v) => setState(() => _wifiDetails = v),
                maxLines: 2,
                isMonospace: true,
              ),
            ],
          ],
        );
      case 'advanced':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggle(
              'Print Barcode (Receipt ID)',
              _showBarcode,
              (v) => setState(() => _showBarcode = v),
              icon: Icons.view_headline,
            ),
            if (_showBarcode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'Barcode Data',
                controller: _barcodeCtrl,
                onChanged: (v) => setState(() => _barcodeData = v),
              ),
            ],
            const SizedBox(height: 24),
            _buildToggle(
              'Print E-Invoice QR Code',
              _showQrCode,
              (v) => setState(() => _showQrCode = v),
              icon: Icons.qr_code,
            ),
            if (_showQrCode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'QR Data',
                controller: _qrCtrl,
                onChanged: (v) => setState(() => _qrData = v),
                maxLines: 2,
                isMonospace: true,
              ),
            ],
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildToggle(
    String label,
    bool value,
    Function(bool) onChanged, {
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: (val) => onChanged(val),
          activeColor: _indigo,
        )
      ],
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool isMonospace = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: isMonospace ? 'monospace' : 'sans-serif',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _indigo, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeBtn(String size) {
    final isActive = _itemFontSize == size;
    return InkWell(
      onTap: () => setState(() => _itemFontSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo.shade50 : Colors.white,
          border: Border.all(
            color: isActive ? _indigo : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            size[0].toUpperCase() + size.substring(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? _indigo : Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: _printTest,
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Test Print'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _saveTemplate,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: _indigo.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalPreview() {
    final width = _paperSize == '80mm' ? 350.0 : 260.0;
    final baseFontSize = _paperSize == '80mm' ? 14.0 : 12.0;
    final headerSize = _paperSize == '80mm' ? 24.0 : 20.0;

    double itemSize;
    if (_itemFontSize == 'small') {
      itemSize = baseFontSize - 4;
    } else if (_itemFontSize == 'large') {
      itemSize = baseFontSize + 2;
    } else {
      itemSize = baseFontSize - 2;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'monospace', color: Colors.black87),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_showLogo) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black26,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Icon(Icons.image, color: Colors.black26, size: 24),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                _storeName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: headerSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _address,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: baseFontSize - 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_showTaxId && _taxId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _taxId,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize - 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: 22/02/2026',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time: 14:30',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_showOrderNumber)
                    Text(
                      'Order: #082',
                      style: TextStyle(
                        fontSize: baseFontSize - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    'Term: 01',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ITEM',
                    style: TextStyle(fontSize: itemSize, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'AMT',
                    style: TextStyle(fontSize: itemSize, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._mockItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.qty}x ${item.name}',
                        style: TextStyle(
                          fontSize: itemSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.price.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: itemSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RM 46.50',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SST (8%)',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RM 3.72',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black87, width: 2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: baseFontSize + 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'RM 50.22',
                      style: TextStyle(
                        fontSize: baseFontSize + 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid (Credit Card)',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RM 50.22',
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _footerMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: baseFontSize - 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_showWifi) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black38)),
                  child: Text(
                    _wifiDetails,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (_showBarcode) ...[
                const SizedBox(height: 24),
                Column(
                  children: [
                    Container(
                      height: 40,
                      width: double.infinity,
                      color: Colors.black87,
                      margin: const EdgeInsets.only(bottom: 4),
                    ),
                    Text(
                      'RCP-82910482',
                      style: TextStyle(
                        fontSize: baseFontSize - 4,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                )
              ],
              if (_showQrCode) ...[
                const SizedBox(height: 24),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 2),
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        size: 64,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan for E-Invoice',
                      style: TextStyle(
                        fontSize: baseFontSize - 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.5;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54),
              ),
            );
          }),
        );
      },
    );
  }
}
