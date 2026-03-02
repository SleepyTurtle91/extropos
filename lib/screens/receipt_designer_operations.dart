part of 'receipt_designer_screen.dart';

extension ReceiptDesignerOperations on _ReceiptDesignerScreenState {
  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseService.instance.getReceiptSettings();
      final info = BusinessInfo.instance;
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _paperSize = settings.paperSize == ReceiptPaperSize.mm58 ? '58mm' : '80mm';
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
        _taxId = settings.taxIdText.isNotEmpty ? settings.taxIdText : (info.taxNumber ?? '');
        _wifiDetails = settings.wifiDetails.isNotEmpty ? settings.wifiDetails : _wifiDetails;
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
      final receiptPrinters = printers.where((p) => p.type == PrinterType.receipt).toList();

      if (!mounted) return;

      if (receiptPrinters.isEmpty) {
        ToastHelper.showToast(context, 'No receipt printers configured. Add one in Settings.');
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
      ToastHelper.showToast(context, success ? 'Test print sent' : 'Test print failed');
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Test print error: $e');
    }
  }

  Map<String, dynamic> _buildSampleReceiptData() {
    final now = DateTime.now();
    final addressLines = _address.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

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
      'items': _mockItems.map((item) => {'name': item.name, 'qty': item.qty, 'amt': item.price}).toList(),
      'sub_total_qty': _mockItems.fold<int>(0, (sum, item) => sum + item.qty),
      'sub_total_amt': 46.50,
      'discount': 0.00,
      'taxes': [{'name': 'SST (8%)', 'amt': 3.72}],
      'total': 50.22,
      'cash': 50.22,
      'cash_tendered': 50.22,
      'footer': _footerMessage,
    };
  }
}
