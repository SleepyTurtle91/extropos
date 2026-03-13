part of 'printer_service_clean.dart';

extension PrinterServicePrint on PrinterService {
  Future<bool> printOrder(
    Printer printer,
    Map<String, dynamic> orderData,
  ) async {
    return await _synchronized(() async {
      if (Platform.isAndroid) return await _androidService.printOrder(printer, orderData);
      if (Platform.isWindows) return await _windowsService.printOrder(printer, orderData);
      return false;
    });
  }

  Future<bool> printReceipt(
    Printer printer,
    Map<String, dynamic> receiptData, {
    ReceiptType receiptType = ReceiptType.customer,
  }) async {
    return await _synchronized(() async {
      final receiptPayload = Map<String, dynamic>.from(receiptData);
      try {
        final settings = await DatabaseService.instance.getReceiptSettings();
        _applyTemplateFields(settings, receiptPayload);
      } catch (_) {}

      if (printer.id == 'imin_printer' && Platform.isAndroid) {
        try {
          final iminService = IminPrinterService();
          await iminService.initialize();
          final content = receiptPayload['content'] as String? ?? '';
          return await iminService.printReceipt(content);
        } catch (e) {
          developer.log('iMin printer error: $e');
          return false;
        }
      }

      if (Platform.isAndroid) {
        try {
          final result = await _androidService.printReceipt(printer, receiptPayload);
          if (result) return true;

          final charWidth = (printer.paperSize?.name == 'mm80') ? 48 : 32;
          final settings = await DatabaseService.instance.getReceiptSettings();
          final formattedText = generateReceiptTextWithSettings(
            data: receiptPayload,
            settings: settings,
            charWidth: charWidth,
            receiptType: receiptType,
          );
          final fallbackReceiptData = Map<String, dynamic>.from(receiptPayload);
          fallbackReceiptData['content'] = formattedText;

          return await _androidService.printViaExternalService(
            fallbackReceiptData,
            paperSize: printer.paperSize,
          );
        } catch (e) {
          developer.log('Android printer error: $e');
          return false;
        }
      } else if (Platform.isWindows) {
        try {
          return await _windowsService.printReceipt(printer, receiptPayload);
        } catch (e) {
          developer.log('Windows printer error: $e');
          return false;
        }
      }
      return false;
    });
  }

  Future<bool> testPrint(Printer printer) async {
    return await _synchronized(() async {
      if (Platform.isAndroid) return await _androidService.testPrint(printer);
      if (Platform.isWindows) return await _windowsService.testPrint(printer);
      return false;
    });
  }

  Future<bool> printViaExternalService(
    Map<String, dynamic> receiptData, {
    ThermalPaperSize? paperSize,
  }) async {
    if (Platform.isAndroid) {
      return await _androidService.printViaExternalService(receiptData, paperSize: paperSize);
    }
    return false;
  }

  Future<bool> printKitchenOrder(Map<String, dynamic> orderData) async {
    try {
      final allPrinters = await DatabaseService.instance.getPrinters();
      final kitchenBarPrinters = allPrinters
          .where((p) => p.type == PrinterType.kitchen || p.type == PrinterType.bar)
          .toList();

      if (kitchenBarPrinters.isEmpty) return false;

      final allCategories = await DatabaseService.instance.getCategories();
      final categoryNameToId = {for (var cat in allCategories) cat.name: cat.id};

      bool anySuccess = false;
      for (final printer in kitchenBarPrinters) {
        final allItems = (orderData['items'] as List<dynamic>?) ?? [];
        final filteredItems = <dynamic>[];

        for (final item in allItems) {
          final printerOverride = item['printer_override'] as String?;
          if (printerOverride != null && printerOverride.isNotEmpty) {
            if (printerOverride == printer.id) filteredItems.add(item);
            continue;
          }

          if (printer.categories.isEmpty) {
            filteredItems.add(item);
          } else {
            final itemCategoryName = item['category'] as String?;
            if (itemCategoryName != null) {
              final itemCategoryId = categoryNameToId[itemCategoryName];
              if (itemCategoryId != null && printer.categories.contains(itemCategoryId)) {
                filteredItems.add(item);
              }
            }
          }
        }

        if (filteredItems.isEmpty) continue;

        final printerOrderData = Map<String, dynamic>.from(orderData)..['items'] = filteredItems;
        if (!printerOrderData.containsKey('order_header')) {
          printerOrderData['order_header'] = printer.type == PrinterType.kitchen ? 'Kitchen Order' : 'Bar Order';
        }
        if (!printerOrderData.containsKey('kitchen_template_style')) {
          printerOrderData['kitchen_template_style'] = 'standard';
        }

        try {
          if (Platform.isAndroid) {
            if (await _androidService.printOrder(printer, printerOrderData)) anySuccess = true;
          }
        } catch (e) {
          developer.log('Error printing to kitchen printer ${printer.name}: $e');
        }
      }
      return anySuccess;
    } catch (e) {
      developer.log('PrinterService: printKitchenOrder error: $e');
      return false;
    }
  }

  void _applyTemplateFields(ReceiptSettings settings, Map<String, dynamic> data) {
    if (settings.showTaxId) {
      final taxId = settings.taxIdText.trim();
      final effectiveTax = taxId.isNotEmpty ? taxId : (BusinessInfo.instance.taxNumber ?? '');
      if (effectiveTax.isNotEmpty) data.putIfAbsent('tax_id', () => effectiveTax);
    }
    if (settings.showWifiDetails && settings.wifiDetails.trim().isNotEmpty) {
      data.putIfAbsent('wifi_details', () => settings.wifiDetails.trim());
    }
    if (settings.showBarcode) {
      final barcode = settings.barcodeData.trim();
      data.putIfAbsent('barcode', () => barcode.isNotEmpty ? barcode : (data['bill_no'] ?? data['order_number']).toString());
    }
    if (settings.showQrCode && settings.qrData.trim().isNotEmpty) {
      data.putIfAbsent('qr_data', () => settings.qrData.trim());
    }
  }

  String? getLastPluginMessage() {
    for (final log in _recentPrinterLogs) {
      if (log.contains('printReceipt plugin message:') ||
          log.contains('printReceipt error') ||
          log.contains('NETWORK error') ||
          log.contains('USB error') ||
          log.contains('BLUETOOTH error') ||
          log.contains('structured build failed') ||
          log.contains('buildEscPosText failed')) {
        return log;
      }
    }
    return null;
  }

  Future<bool> debugForcePrint(
    Printer printer,
    Map<String, dynamic> receiptData,
  ) async {
    developer.log('PrinterService: debugForcePrint called for ${printer.name}');
    return await _synchronized(() async {
      try {
        if (printer.id == 'imin_printer' && Platform.isAndroid) {
          final iminService = IminPrinterService();
          await iminService.initialize();
          final content = receiptData['content'] as String? ?? '';
          return await iminService.printReceipt(content);
        }

        if (Platform.isAndroid) {
          return await _androidService.printReceipt(printer, receiptData);
        }
        if (Platform.isWindows) {
          return await _windowsService.printReceipt(printer, receiptData);
        }
        return false;
      } catch (e) {
        return false;
      }
    });
  }
}
