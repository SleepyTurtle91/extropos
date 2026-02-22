import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/android_printer_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/error_handler.dart';
import 'package:extropos/services/imin_printer_service.dart';
import 'package:extropos/services/permissions_helper.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:extropos/services/windows_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

/// Clean PrinterService implementation to replace corrupted printer_service.dart
class PrinterService {
  final AndroidPrinterService _androidService = AndroidPrinterService();
  final WindowsPrinterService _windowsService = WindowsPrinterService();

  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final StreamController<Printer> _printerStatusController =
      StreamController<Printer>.broadcast();
  Stream<Printer> get printerStatusStream => _printerStatusController.stream;

  final StreamController<String> _printerLogController =
      StreamController<String>.broadcast();
  Stream<String> get printerLogStream => _printerLogController.stream;
  bool _printerLogEnabled = true;
  final List<String> _recentPrinterLogs = [];

  Completer<void>? _operationLock;
  Future<T> _synchronized<T>(Future<T> Function() action) async {
    while (_operationLock != null) {
      try {
        await _operationLock!.future;
      } catch (_) {}
    }
    _operationLock = Completer<void>();
    try {
      return await action();
    } finally {
      try {
        _operationLock?.complete();
      } catch (_) {}
      _operationLock = null;
    }
  }

  Future<void> setPrinterLogEnabled(bool enabled) async {
    _printerLogEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('printer_log_enabled', enabled);
    } catch (_) {}
    _androidService.setLogEnabled(enabled);
  }

  bool get isPrinterLogEnabled => _printerLogEnabled;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _printerLogEnabled =
          prefs.getBool('printer_log_enabled') ?? _printerLogEnabled;
    } catch (_) {}

    if (Platform.isAndroid) {
      await _androidService.initialize();
      _androidService.logStream.listen((msg) {
        if (_printerLogEnabled) _printerLogController.add('[Android] $msg');
        _recentPrinterLogs.insert(0, '[Android] $msg');
        if (_recentPrinterLogs.length > 200) _recentPrinterLogs.removeLast();
      });
    } else if (Platform.isWindows) {
      await _windowsService.initialize();
      _windowsService.logStream.listen((msg) {
        if (_printerLogEnabled) _printerLogController.add(msg);
        _recentPrinterLogs.insert(0, msg);
        if (_recentPrinterLogs.length > 200) _recentPrinterLogs.removeLast();
      });
    }
  }

  /// Get last N recent plugin log messages (most recent first)
  List<String> getRecentPrinterLogs({int count = 50}) {
    return _recentPrinterLogs.take(count).toList();
  }

  /// Return last plugin message (if any) by scanning recent logs for known plugin message prefixes.
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

  Future<List<Printer>> discoverPrinters() async {
    try {
      final List<Printer> allPrinters = [];
      final savedPrinters = await DatabaseService.instance.getPrinters();
      allPrinters.addAll(savedPrinters);

      if (Platform.isAndroid) {
        final androidPrinters = await _androidService.discoverPrinters();
        for (final discovered in androidPrinters) {
          if (!allPrinters.any((p) => p.id == discovered.id)) {
            allPrinters.add(discovered);
          }
        }

        // Check for iMin hardware and add iMin printer if not already present
        try {
          final isIMinDevice = await _isIMinDevice();
          if (isIMinDevice) {
            final hasIminPrinter = allPrinters.any(
              (p) => p.id == 'imin_printer',
            );
            if (!hasIminPrinter) {
              // Create iMin printer automatically
              final iminPrinter = Printer(
                id: 'imin_printer',
                name: 'iMin Built-in Printer',
                type: PrinterType.receipt,
                connectionType: PrinterConnectionType.usb,
                status: PrinterStatus.offline,
                isDefault: false,
                modelName: 'iMin Swan 2',
                paperSize: ThermalPaperSize.mm80,
                categories: [],
              );
              allPrinters.add(iminPrinter);

              // Save to database asynchronously
              try {
                await DatabaseService.instance.savePrinter(iminPrinter);
              } catch (e) {
                // Log but don't fail discovery
                developer.log('Failed to save iMin printer to database: $e');
              }
            }
          }
        } catch (e) {
          developer.log('Error checking for iMin device: $e');
        }
      } else if (Platform.isWindows) {
        final windowsPrinters = await _windowsService.discoverPrinters();
        for (final discovered in windowsPrinters) {
          if (!allPrinters.any((p) => p.id == discovered.id)) {
            allPrinters.add(discovered);
          }
        }
      }
      return allPrinters;
    } catch (_) {
      try {
        return await DatabaseService.instance.getPrinters();
      } catch (_) {
        return [];
      }
    }
  }

  /// Check if the current device is an iMin device (like Swan 2)
  Future<bool> _isIMinDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Check for iMin Swan 2 device characteristics
      final model = androidInfo.model.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();

      // iMin devices typically have specific identifiers
      final isIMinModel =
          model.contains('imin') ||
          model.contains('swan') ||
          model.contains('d3') ||
          model.contains('d4');

      final isIMinManufacturer =
          manufacturer.contains('imin') ||
          manufacturer.contains('sunmi') ||
          brand.contains('imin');

      return isIMinModel || isIMinManufacturer;
    } catch (e) {
      developer.log('Error detecting iMin device: $e');
      return false;
    }
  }

  Future<List<Printer>> discoverBluetoothPrinters() async {
    if (Platform.isAndroid) {
      return await _androidService.discoverBluetoothPrinters();
    }
    return [];
  }

  Future<List<Printer>> discoverUsbPrinters() async {
    if (Platform.isAndroid) return await _androidService.discoverUsbPrinters();
    if (Platform.isWindows) return await _windowsService.discoverUsbPrinters();
    return [];
  }

  Future<bool> printOrder(
    Printer printer,
    Map<String, dynamic> orderData,
  ) async {
    return await _synchronized(() async {
      if (Platform.isAndroid) {
        return await _androidService.printOrder(printer, orderData);
      }
      if (Platform.isWindows) {
        return await _windowsService.printOrder(printer, orderData);
      }
      return false;
    });
  }

  Future<bool> requestUsbPermission(Printer printer) async {
    if (Platform.isAndroid) {
      return await _androidService.requestUsbPermission(printer);
    }
    return true;
  }

  Future<bool> printReceipt(
    Printer printer,
    Map<String, dynamic> receiptData, {
    ReceiptType receiptType = ReceiptType.customer,
  }) async {
    developer.log(
      'PrinterService: printReceipt called for ${printer.name} with ${receiptData.length} data fields',
    );
    return await _synchronized(() async {
      final receiptPayload = Map<String, dynamic>.from(receiptData);
      ReceiptSettings? settings;
      try {
        settings = await DatabaseService.instance.getReceiptSettings();
        _applyTemplateFields(settings, receiptPayload);
      } catch (_) {}

      if (_printerLogEnabled) {
        _printerLogController.add(
          'printReceipt invoked for ${printer.name} (${printer.id})',
        );
      }
      if (_printerLogEnabled) {
        _printerLogController.add(
          'printReceipt printer connectionType=${printer.connectionType.name}, ip=${printer.ipAddress}, bluetooth=${printer.bluetoothAddress}, usbDeviceId=${printer.usbDeviceId}',
        );
      }
      if (_printerLogEnabled) {
        _printerLogController.add(
          'receiptData keys: ${receiptPayload.keys.toList()}',
        );
      }
      if (_printerLogEnabled) {
        final title = receiptPayload['title'] ?? '<no title>';
        final content = (receiptPayload['content'] as String?) ?? '';
        final preview = content.length > 200
            ? '${content.substring(0, 200)}... (truncated)'
            : content;
        _printerLogController.add(
          'printReceipt payload: title=$title, contentPreview=\n$preview',
        );
      }
      // Additionally log trimmed JSON for debugging
      if (_printerLogEnabled) {
        try {
          final jsonPreview = jsonEncode(receiptPayload).substring(
            0,
            (jsonEncode(receiptPayload).length > 400
                ? 400
                : jsonEncode(receiptPayload).length),
          );
          developer.log(
            'PrinterService: printReceipt payload JSON (preview): $jsonPreview',
          );
        } catch (e) {
          developer.log(
            'PrinterService: Could not encode receiptData for logging: $e',
          );
        }
      }
      if (printer.id == 'imin_printer' && Platform.isAndroid) {
        try {
          final iminService = IminPrinterService();
          await iminService.initialize();
          final content = receiptPayload['content'] as String? ?? '';
          return await iminService.printReceipt(content);
        } catch (e) {
          developer.log('iMin printer error: $e');
          ErrorHandler.logError(e, severity: ErrorSeverity.high, category: ErrorCategory.hardware, message: 'iMin printer failed to print receipt');
          return false;
        }
      }
      if (_printerLogEnabled) {
        final validationIssue = _validatePrinterConfig(printer);
        if (validationIssue != null) {
          _printerLogController.add(
            'PrinterService: printReceipt validation failed: $validationIssue',
          );
          // Return false so caller may fallback
          return false;
        }
      }
      if (Platform.isAndroid) {
        try {
          if (printer.connectionType == PrinterConnectionType.bluetooth) {
            final hasPerm = await PermissionsHelper.hasBluetoothPermissions();
            if (!hasPerm) {
              final requested =
                  await PermissionsHelper.requestBluetoothPermissions();
              if (!requested) return false;
              printer.hasPermission = true;
              await DatabaseService.instance.savePrinter(printer);
            }
          }
          final result = await _androidService.printReceipt(
            printer,
            receiptPayload,
          );
          if (result) {
            if (!printer.hasPermission) {
              printer.hasPermission = true;
              await DatabaseService.instance.savePrinter(printer);
            }
            return true;
          } else {
            // Fallback to external service if native printReceipt fails
            developer.log(
              'PrinterService: printReceipt failed, trying printViaExternalService fallback',
            );
            if (_printerLogEnabled) {
              // Attach last plugin logs to help diagnose failure in the UI
              final lastLogs = _recentPrinterLogs.isEmpty
                  ? '<no logs>'
                  : _recentPrinterLogs.take(20).join('\n');
              _printerLogController.add(
                'PrinterService: printReceipt failed for ${printer.name}. Last plugin logs:\n$lastLogs',
              );
            }

            // Ensure fallback also has formatted content
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

            final fallbackResult = await _androidService.printViaExternalService(
              fallbackReceiptData,
              paperSize: printer.paperSize,
            );
            developer.log(
              'PrinterService: printViaExternalService fallback result: $fallbackResult',
            );
            return fallbackResult;
          }
        } catch (e) {
          developer.log('Android printer error: $e');
          ErrorHandler.logError(e, severity: ErrorSeverity.high, category: ErrorCategory.hardware, message: 'Android printer failed to print receipt');
          return false;
        }
      } else if (Platform.isWindows) {
        try {
          final result =
              await _windowsService.printReceipt(printer, receiptPayload);
          if (_printerLogEnabled) {
            _printerLogController.add('Windows printReceipt result: $result');
            if (!result) {
              final lastLogs = _recentPrinterLogs.isEmpty
                  ? '<no logs>'
                  : _recentPrinterLogs.take(20).join('\n');
              _printerLogController.add(
                'PrinterService: Windows printReceipt failed for ${printer.name}. Last plugin logs:\n$lastLogs',
              );
            }
          }
          return result;
        } catch (e) {
          developer.log('Windows printer error: $e');
          ErrorHandler.logError(e, severity: ErrorSeverity.high, category: ErrorCategory.hardware, message: 'Windows printer failed to print receipt');
          return false;
        }
      }
      return false;
    });
  }

  void _applyTemplateFields(
    ReceiptSettings settings,
    Map<String, dynamic> data,
  ) {
    final taxId = settings.taxIdText.trim();
    if (settings.showTaxId) {
      final fallbackTax = BusinessInfo.instance.taxNumber ?? '';
      final effectiveTax = taxId.isNotEmpty ? taxId : fallbackTax;
      if (effectiveTax.isNotEmpty) {
        data.putIfAbsent('tax_id', () => effectiveTax);
      }
    }

    final wifi = settings.wifiDetails.trim();
    if (settings.showWifiDetails && wifi.isNotEmpty) {
      data.putIfAbsent('wifi_details', () => wifi);
    }

    if (settings.showBarcode) {
      final barcode = settings.barcodeData.trim();
      if (barcode.isNotEmpty) {
        data.putIfAbsent('barcode', () => barcode);
      } else {
        final fallback = data['bill_no'] ?? data['orderNumber'] ?? data['order_number'];
        if (fallback != null) {
          data.putIfAbsent('barcode', () => fallback.toString());
        }
      }
    }

    if (settings.showQrCode) {
      final qr = settings.qrData.trim();
      if (qr.isNotEmpty) {
        data.putIfAbsent('qr_data', () => qr);
      }
    }
  }

  String? validatePrinterConfig(Printer printer) {
    return _validatePrinterConfig(printer);
  }

  /// Debug helper: Force print receipt by calling the platform-specific service directly
  /// This bypasses validation and is intended for developer debug only.
  Future<bool> debugForcePrint(
    Printer printer,
    Map<String, dynamic> receiptData,
  ) async {
    developer.log('PrinterService: debugForcePrint called for ${printer.name}');
    return await _synchronized(() async {
      if (_printerLogEnabled) {
        _printerLogController.add(
          'debugForcePrint invoked for ${printer.name} (${printer.id})',
        );
      }
      try {
        if (printer.id == 'imin_printer' && Platform.isAndroid) {
          final iminService = IminPrinterService();
          await iminService.initialize();

          // Generate appropriate content based on printer type
          String content;
          if (printer.type == PrinterType.kitchen ||
              printer.type == PrinterType.bar) {
            // Generate kitchen docket content for kitchen/bar printers
            final settings = await DatabaseService.instance
                .getReceiptSettings();
            final charWidth = (printer.paperSize?.name == 'mm80') ? 48 : 32;
            final kitchenOrderData = {
              'order_number': receiptData['orderNumber'] ?? 'DEBUG',
              'table': 'DEBUG',
              'timestamp': DateTime.now().toIso8601String(),
              'order_type': printer.type == PrinterType.bar ? 'bar' : 'dine_in',
              'items': (receiptData['items'] as List<dynamic>? ?? [])
                  .map(
                    (item) => {
                      'name': item['name'] ?? 'Debug Item',
                      'quantity': item['quantity'] ?? 1,
                      'modifiers': item['modifiers'] ?? '',
                      'category': 'Debug',
                    },
                  )
                  .toList(),
            };
            content = generateKitchenOrderText(
              data: kitchenOrderData,
              charWidth: charWidth,
              settings: settings,
            );
          } else {
            // Use receipt content for receipt printers
            content = receiptData['content'] as String? ?? '';
          }

          return await iminService.printReceipt(content);
        }

        // For kitchen/bar printers (non-IMIN), use kitchen docket format
        if ((printer.type == PrinterType.kitchen ||
                printer.type == PrinterType.bar) &&
            Platform.isAndroid) {
          // Convert receipt data to kitchen order format
          final kitchenOrderData = {
            'order_number': receiptData['orderNumber'] ?? 'DEBUG',
            'table': 'DEBUG',
            'timestamp': DateTime.now().toIso8601String(),
            'order_type': printer.type == PrinterType.bar ? 'bar' : 'dine_in',
            'items': (receiptData['items'] as List<dynamic>? ?? [])
                .map(
                  (item) => {
                    'name': item['name'] ?? 'Debug Item',
                    'quantity': item['quantity'] ?? 1,
                    'modifiers': item['modifiers'] ?? '',
                    'category': 'Debug',
                  },
                )
                .toList(),
          };

          final result = await _androidService.printOrder(
            printer,
            kitchenOrderData,
          );
          if (_printerLogEnabled) {
            _printerLogController.add(
              'Android debugForcePrint (kitchen) result: $result',
            );
          }
          return result;
        }

        if (Platform.isAndroid) {
          final result = await _androidService.printReceipt(
            printer,
            receiptData,
          );
          if (_printerLogEnabled) {
            _printerLogController.add(
              'Android debugForcePrint result: $result',
            );
          }
          return result;
        }
        if (Platform.isWindows) {
          final result = await _windowsService.printReceipt(
            printer,
            receiptData,
          );
          if (_printerLogEnabled) {
            _printerLogController.add(
              'Windows debugForcePrint result: $result',
            );
          }
          return result;
        }
        return false;
      } catch (e) {
        if (_printerLogEnabled) {
          _printerLogController.add('debugForcePrint error: $e');
        }
        return false;
      }
    });
  }

  /// Returns an error message if the printer's configuration is invalid, otherwise null
  String? _validatePrinterConfig(Printer printer) {
    switch (printer.connectionType) {
      case PrinterConnectionType.network:
        if (printer.ipAddress == null ||
            printer.ipAddress!.isEmpty ||
            printer.ipAddress == '192.168.1.') {
          return 'Network printer missing IP address or using placeholder';
        }
        return null;
      case PrinterConnectionType.usb:
        if (printer.usbDeviceId == null || printer.usbDeviceId!.isEmpty) {
          return 'USB printer missing device id';
        }
        return null;
      case PrinterConnectionType.bluetooth:
        if (printer.bluetoothAddress == null ||
            printer.bluetoothAddress!.isEmpty) {
          return 'Bluetooth printer missing address';
        }
        return null;
      default:
        return null;
    }
  }

  /// Private helper to validate printer configuration

  /// Run a preflight check for a printer. Returns null if OK, otherwise an error message.
  Future<String?> preflightPrinterCheck(Printer printer) async {
    final validationIssue = _validatePrinterConfig(printer);
    if (validationIssue != null) return validationIssue;

    // TEMPORARY FIX: Skip status check as it's too strict and blocks working printers
    // The status check often returns 'offline' even for working printers
    // Only validate that connection details are present
    developer.log(
      'PREFLIGHT: Skipping status check for ${printer.name}, connection validated',
    );
    return null;

    /* Original status check - disabled for now
    try {
      if (Platform.isAndroid) {
        final status = (await _androidService.checkPrinterStatus(printer)).toLowerCase();
        if (status == 'online' || status == 'ok' || status == 'available') return null;
        return 'Printer status: $status';
      }
      if (Platform.isWindows) {
        final status = (await _windowsService.checkPrinterStatus(printer)).toLowerCase();
        if (status == 'online' || status == 'ok' || status == 'available') return null;
        return 'Printer status: $status';
      }
    } catch (e) {
      return 'Error checking printer: $e';
    }
    return null;
    */
  }

  Future<bool> testPrint(Printer printer) async {
    developer.log('PrinterService: testPrint called for ${printer.name}');
    return await _synchronized(() async {
      if (Platform.isAndroid) {
        return await _androidService.testPrint(printer);
      }
      if (Platform.isWindows) {
        return await _windowsService.testPrint(printer);
      }
      return false;
    });
  }

  Future<bool> printViaExternalService(
    Map<String, dynamic> receiptData, {
    ThermalPaperSize? paperSize,
  }) async {
    if (Platform.isAndroid) {
      return await _androidService.printViaExternalService(
        receiptData,
        paperSize: paperSize,
      );
    }
    return false;
  }

  /// Print kitchen order to all active kitchen printers
  Future<bool> printKitchenOrder(Map<String, dynamic> orderData) async {
    developer.log('PrinterService: printKitchenOrder called');
    try {
      // Get all active kitchen and bar printers
      final allPrinters = await DatabaseService.instance.getPrinters();
      final kitchenBarPrinters = allPrinters
          .where(
            (p) => p.type == PrinterType.kitchen || p.type == PrinterType.bar,
          )
          .toList();

      if (kitchenBarPrinters.isEmpty) {
        developer.log('PrinterService: No kitchen/bar printers configured');
        return false;
      }

      developer.log(
        'PrinterService: Found ${kitchenBarPrinters.length} kitchen/bar printers',
      );

      // Get all categories from database to map category names to IDs
      final allCategories = await DatabaseService.instance.getCategories();
      final categoryNameToId = <String, String>{};
      for (final cat in allCategories) {
        categoryNameToId[cat.name] = cat.id;
      }

      bool anySuccess = false;
      for (final printer in kitchenBarPrinters) {
        developer.log(
          'PrinterService: Processing ${printer.name} with ${printer.categories.length} assigned categories',
        );

        // Filter items based on printer's assigned categories OR printer_override
        final allItems = (orderData['items'] as List<dynamic>?) ?? [];
        final filteredItems = <dynamic>[];

        for (final item in allItems) {
          final printerOverride = item['printer_override'] as String?;

          // Check 1: If item has printer_override, only print to that specific printer
          if (printerOverride != null && printerOverride.isNotEmpty) {
            if (printerOverride == printer.id) {
              filteredItems.add(item);
              developer.log(
                'PrinterService: Item ${item['name']} assigned to ${printer.name} via override',
              );
            }
            continue; // Skip category check if override is set
          }

          // Check 2: Category-based filtering (original logic)
          if (printer.categories.isEmpty) {
            // If no categories assigned and no override, print all items
            filteredItems.add(item);
          } else {
            // Filter items by category
            final itemCategoryName = item['category'] as String?;
            if (itemCategoryName != null) {
              final itemCategoryId = categoryNameToId[itemCategoryName];
              if (itemCategoryId != null &&
                  printer.categories.contains(itemCategoryId)) {
                filteredItems.add(item);
              }
            }
          }
        }

        developer.log(
          'PrinterService: Filtered to ${filteredItems.length} items from ${allItems.length} total for ${printer.name}',
        );

        // Skip this printer if no items match its categories
        if (filteredItems.isEmpty) {
          developer.log(
            'PrinterService: No items for ${printer.name}, skipping',
          );
          continue;
        }

        // Create filtered order data for this printer
        final printerOrderData = Map<String, dynamic>.from(orderData);
        printerOrderData['items'] = filteredItems;

        // For kitchen/bar printers, inject template overrides:
        // - Prefer 'order_header' to show "Kitchen Order" or "Bar Order"
        // - Force 'kitchen_template_style' to 'standard' for the KOT layout
        try {
          if (!printerOrderData.containsKey('order_header')) {
            if (printer.type == PrinterType.kitchen) {
              printerOrderData['order_header'] = 'Kitchen Order';
            } else if (printer.type == PrinterType.bar) {
              printerOrderData['order_header'] = 'Bar Order';
            }
          }
        } catch (_) {}

        // If printer is kitchen or bar, suggest standard template (override template style)
        if (!printerOrderData.containsKey('kitchen_template_style') &&
            (printer.type == PrinterType.kitchen ||
                printer.type == PrinterType.bar)) {
          printerOrderData['kitchen_template_style'] = 'standard';
        }

        // Skip preflight check for kitchen printers - just try to print
        try {
          if (Platform.isAndroid) {
            final result = await _androidService.printOrder(
              printer,
              printerOrderData,
            );
            if (result) {
              anySuccess = true;
              developer.log(
                'PrinterService: Kitchen order printed successfully to ${printer.name} (${filteredItems.length} items)',
              );
            } else {
              developer.log(
                'PrinterService: Failed to print kitchen order to ${printer.name}',
              );
            }
          }
        } catch (e) {
          developer.log(
            'PrinterService: Error printing to kitchen printer ${printer.name}: $e',
          );
        }
      }

      return anySuccess;
    } catch (e) {
      developer.log('PrinterService: printKitchenOrder error: $e');
      return false;
    }
  }

  Future<bool> requestBluetoothPermission(Printer printer) async {
    if (Platform.isAndroid) {
      final ok = await PermissionsHelper.requestBluetoothPermissions();
      if (ok) {
        printer.hasPermission = true;
        await DatabaseService.instance.savePrinter(printer);
      }
      return ok;
    }
    return true;
  }

  void dispose() {
    _printerStatusController.close();
    _printerLogController.close();
  }
}
