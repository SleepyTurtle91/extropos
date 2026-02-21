import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/permissions_helper.dart';
import 'package:extropos/services/qr_code_generator.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';

/// Android-specific printer detection service.
/// Handles USB, Bluetooth, and network printer discovery on Android platform.
class AndroidPrinterService {
  static const MethodChannel _channel = MethodChannel(
    'com.extrotarget.extropos/printer',
  );

  // Singleton pattern
  static final AndroidPrinterService _instance =
      AndroidPrinterService._internal();
  factory AndroidPrinterService() => _instance;
  AndroidPrinterService._internal();

  // Stream for native plugin log messages
  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  bool _logEnabled = true;
  bool _isInitialized = false;

  /// Enable or disable logging
  void setLogEnabled(bool enabled) {
    _logEnabled = enabled;
  }

  /// Initialize the Android printer service
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Not on Android platform, skipping initialization',
        );
      }
      developer.log(
        'AndroidPrinterService: Not on Android platform, skipping initialization',
      );
      return;
    }

    if (_isInitialized) {
      return;
    }

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');
      _isInitialized = true;
      if (_logEnabled) {
        _logController.add('AndroidPrinterService: Initialized successfully');
      }
      developer.log('AndroidPrinterService: Initialized successfully');
    } catch (e) {
      if (_logEnabled) {
        _logController.add('AndroidPrinterService: Failed to initialize: $e');
      }
      developer.log('AndroidPrinterService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Discover USB printers on Android
  Future<List<Printer>> discoverUsbPrinters() async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      await initialize();
      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Starting USB printer discovery...',
        );
      }
      developer.log('AndroidPrinterService: Starting USB printer discovery...');

      final result = await _channel.invokeMethod('discoverUsbPrinters');

      if (result == null) {
        developer.log('AndroidPrinterService: USB discovery returned null');
        return [];
      }

      final printers = _parsePrintersList(result);

      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Discovered ${printers.length} USB printers',
        );
        for (final printer in printers) {
          _logController.add('  - ${printer.name} (${printer.usbDeviceId})');
        }
      }
      developer.log(
        'AndroidPrinterService: Discovered ${printers.length} USB printers',
      );
      return printers;
    } catch (e, stackTrace) {
      if (_logEnabled) {
        _logController.add('AndroidPrinterService: USB discovery failed: $e');
      }
      developer.log('AndroidPrinterService: USB discovery failed: $e');
      developer.log('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Discover Bluetooth printers on Android
  Future<List<Printer>> discoverBluetoothPrinters() async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      await initialize();
      // Ensure we have runtime Bluetooth permissions (Android 12+)
      final hasPerm = await PermissionsHelper.hasBluetoothPermissions();
      if (!hasPerm) {
        developer.log(
          'AndroidPrinterService: Requesting Bluetooth permissions...',
        );
        final requested = await PermissionsHelper.requestBluetoothPermissions();
        if (!requested) {
          _logController.add(
            'AndroidPrinterService: Bluetooth permissions not granted, aborting discovery',
          );
          developer.log(
            'AndroidPrinterService: Bluetooth permissions not granted, aborting discovery',
          );
          return [];
        }
      }
      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Starting Bluetooth printer discovery...',
        );
      }
      developer.log(
        'AndroidPrinterService: Starting Bluetooth printer discovery...',
      );

      final result = await _channel.invokeMethod('discoverBluetoothPrinters');

      if (result == null) {
        developer.log(
          'AndroidPrinterService: Bluetooth discovery returned null',
        );
        return [];
      }

      final printers = _parsePrintersList(result);

      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Discovered ${printers.length} Bluetooth printers',
        );
        for (final printer in printers) {
          _logController.add(
            '  - ${printer.name} (${printer.bluetoothAddress})',
          );
        }
      }
      developer.log(
        'AndroidPrinterService: Discovered ${printers.length} Bluetooth printers',
      );
      return printers;
    } catch (e, stackTrace) {
      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Bluetooth discovery failed: $e',
        );
      }
      developer.log('AndroidPrinterService: Bluetooth discovery failed: $e');
      developer.log('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Discover network printers on Android
  Future<List<Printer>> discoverNetworkPrinters() async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      await initialize();
      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Network printers require manual configuration',
        );
      }
      final result = await _channel.invokeMethod('discoverNetworkPrinters');
      final printers = _parsePrintersList(result);
      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Found ${printers.length} network printers',
        );
      }
      developer.log(
        'AndroidPrinterService: Found ${printers.length} network printers',
      );
      return printers;
    } catch (e) {
      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: Network discovery failed: $e',
        );
      }
      developer.log('AndroidPrinterService: Network discovery failed: $e');
      return [];
    }
  }

  /// Discover all printers on Android (USB, Bluetooth, Network)
  Future<List<Printer>> discoverPrinters() async {
    if (!Platform.isAndroid) return [];

    try {
      final List<Printer> allPrinters = [];

      // Discover USB printers
      final usbPrinters = await discoverUsbPrinters();
      allPrinters.addAll(usbPrinters);

      // Discover Bluetooth printers
      final bluetoothPrinters = await discoverBluetoothPrinters();
      allPrinters.addAll(bluetoothPrinters);

      // Discover network printers
      final networkPrinters = await discoverNetworkPrinters();
      allPrinters.addAll(networkPrinters);

      if (_logEnabled) {
        _logController.add(
          'Android discovered ${allPrinters.length} total printers (${usbPrinters.length} USB, ${bluetoothPrinters.length} Bluetooth, ${networkPrinters.length} Network)',
        );
      }
      developer.log('Android discovered ${allPrinters.length} total printers');

      return allPrinters;
    } catch (e) {
      if (_logEnabled) {
        _logController.add('Android printer discovery failed: $e');
      }
      developer.log('Android printer discovery failed: $e');
      return [];
    }
  }

  /// Print receipt using Android printer
  Future<bool> printReceipt(
    Printer printer,
    Map<String, dynamic> receiptData, {
    ReceiptType receiptType = ReceiptType.customer,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final connectionDetails = _buildConnectionDetails(printer);

      // Ensure we send a formatted receipt content string for platforms that expect it
      final charWidth = (printer.paperSize?.name == 'mm80') ? 48 : 32;
      // Load receipt settings and use settings-aware generator so template toggles take effect
      final settings = await DatabaseService.instance.getReceiptSettings();
      developer.log(
        'Android printReceipt: using ReceiptSettings: ${settings.toJson()}',
      );
      final formattedText = generateReceiptTextWithSettings(
        data: receiptData,
        settings: settings,
        charWidth: charWidth,
        receiptType: receiptType,
      );

      final Map<String, dynamic> outgoingReceiptData =
          Map<String, dynamic>.from(receiptData);
      outgoingReceiptData['content'] = formattedText;

      // Generate QR image if e-wallet QR present
      if (receiptData['ewallet_qr'] != null) {
        try {
          final qrBytes = await QRCodeGenerator.generateQRImageBytes(
            data: receiptData['ewallet_qr'] as String,
            size: charWidth == 48 ? 200 : 150,
          );
          if (qrBytes != null) {
            outgoingReceiptData['ewallet_qr_image'] = qrBytes;
          }
        } catch (e) {
          developer.log('Failed to generate QR image: $e');
        }
      }

      final printData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': connectionDetails,
        'paperSize': printer.paperSize?.name,
        'receiptData': outgoingReceiptData,
      };

      if (_logEnabled) {
        _logController.add(
          'Android printReceipt: ${printer.name} (${printer.connectionType.name})',
        );
        _logController.add(
          'Android printReceipt connectionDetails: $connectionDetails',
        );
        _logController.add(
          'Android printReceipt content (preview):\n${formattedText.substring(0, formattedText.length > 200 ? 200 : formattedText.length)}${formattedText.length > 200 ? '... (truncated)' : ''}',
        );
      }

      // Validate connection details locally before invoking plugin; if missing, skip and return false so Dart can fallback
      bool hasValidConnection = true;
      switch (printer.connectionType) {
        case PrinterConnectionType.network:
          final ip = connectionDetails['ipAddress'] as String?;
          if (ip == null || ip.isEmpty || ip == '192.168.1.') {
            hasValidConnection = false;
          }
          break;
        case PrinterConnectionType.usb:
          final usbId = connectionDetails['usbDeviceId'] as String?;
          final platformId = connectionDetails['platformSpecificId'] as String?;
          if ((usbId == null || usbId.isEmpty) &&
              (platformId == null || platformId.isEmpty)) {
            hasValidConnection = false;
          }
          break;
        case PrinterConnectionType.bluetooth:
          final addr = connectionDetails['bluetoothAddress'] as String?;
          if (addr == null || addr.isEmpty) hasValidConnection = false;
          break;
        default:
          break;
      }

      if (!hasValidConnection) {
        if (_logEnabled) {
          _logController.add(
            'Android printReceipt: Invalid/missing connection details - will fallback to external printing',
          );
        }
        return false;
      }

      final result = await _channel.invokeMethod('printReceipt', printData);
      // The plugin may return either a boolean or a structured map with success/message
      if (result is bool) {
        return result;
      } else if (result is Map) {
        final success = result['success'] == true;
        final message = result['message'] as String?;
        if (!success && _logEnabled && message != null) {
          _logController.add('Android printReceipt plugin message: $message');
        }
        return success;
      }
      return false;
    } catch (e) {
      if (_logEnabled) {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        _logController.add('Android printReceipt error: $msg');
      }
      return false;
    }
  }

  /// Print order using Android printer
  Future<bool> printOrder(
    Printer printer,
    Map<String, dynamic> orderData,
  ) async {
    if (!Platform.isAndroid) return false;

    try {
      final connectionDetails = _buildConnectionDetails(printer);

      // Load receipt settings to get kitchen template preferences
      final settings = await DatabaseService.instance.getReceiptSettings();

      final charWidth = (printer.paperSize?.name == 'mm80') ? 48 : 32;
      final formattedText = generateKitchenOrderText(
        data: orderData,
        charWidth: charWidth,
        settings: settings,
      );

      final Map<String, dynamic> outgoingOrderData = Map<String, dynamic>.from(
        orderData,
      );
      outgoingOrderData['content'] = formattedText;

      // CRITICAL: Remove 'items' array for kitchen/bar printers
      // If items exist, Android native code will use buildStructuredReceipt()
      // which generates its own format with pricing instead of using our
      // pre-formatted kitchen template in 'content'
      outgoingOrderData.remove('items');

      // For kitchen/bar printers, don't cut paper (no empty paper waste)
      outgoingOrderData['noCut'] = true;
      final printData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': connectionDetails,
        'paperSize': printer.paperSize?.name,
        'orderData': outgoingOrderData,
      };

      final result = await _channel.invokeMethod('printOrder', printData);
      return result as bool;
    } catch (e) {
      if (_logEnabled) {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        _logController.add('Android printOrder error: $msg');
      }
      return false;
    }
  }

  /// Test print using Android printer
  Future<bool> testPrint(Printer printer) async {
    if (!Platform.isAndroid) return false;

    try {
      final connectionDetails = _buildConnectionDetails(printer);

      final testData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': connectionDetails,
        'paperSize': printer.paperSize?.name,
      };

      if (_logEnabled) {
        _logController.add('Android testPrint: ${printer.name}');
        _logController.add('Android testPrint data: $testData');
      }

      if (_logEnabled) {
        _logController.add(
          'AndroidPrinterService: testPrint starting for ${printer.name}',
        );
        _logController.add('AndroidPrinterService: testData = $testData');
      }
      developer.log(
        'AndroidPrinterService: testPrint starting for ${printer.name}',
      );
      developer.log('AndroidPrinterService: testData = $testData');

      // Use printReceipt for testPrint to ensure we exercise the structured printing path
      final result = await _channel.invokeMethod('printReceipt', {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': connectionDetails,
        'paperSize': printer.paperSize?.name,
        'receiptData': {
          'title': 'TEST PRINT',
          'items': [
            {'name': 'Sample Item', 'quantity': 1, 'price': 1.0},
          ],
          'subtotal': 1.0,
          'total': 1.0,
          'content': 'This is a test print from Flutter POS',
        },
      });
      if (_logEnabled) {
        _logController.add('AndroidPrinterService: testPrint result = $result');
      }
      developer.log('AndroidPrinterService: testPrint result = $result');

      if (_logEnabled) {
        _logController.add('Android testPrint result: $result');
      }

      // Handle both bool and Map response types from the plugin
      if (result is bool) {
        return result;
      } else if (result is Map) {
        final success = result['success'] == true;
        final message = result['message'] as String?;
        if (!success && _logEnabled && message != null) {
          _logController.add('Android testPrint plugin message: $message');
        }
        return success;
      }

      // Default to false if result type is unexpected
      return false;
    } catch (e) {
      developer.log('AndroidPrinterService: testPrint ERROR: $e');

      if (_logEnabled) {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        _logController.add('Android testPrint error: $msg');
      }
      return false;
    }
  }

  /// Build connection details map for native code
  Map<String, dynamic> _buildConnectionDetails(Printer printer) {
    final details = <String, dynamic>{};

    switch (printer.connectionType) {
      case PrinterConnectionType.usb:
        details['usbDeviceId'] = printer.usbDeviceId ?? '';
        details['platformSpecificId'] = printer.platformSpecificId ?? '';
        details['usbMode'] = 'native'; // or 'serial' based on detection
        break;
      case PrinterConnectionType.bluetooth:
        details['bluetoothAddress'] = printer.bluetoothAddress ?? '';
        details['platformSpecificId'] = printer.platformSpecificId ?? '';
        break;
      case PrinterConnectionType.network:
        details['ipAddress'] = printer.ipAddress ?? '';
        details['port'] = printer.port ?? 9100;
        break;
      case PrinterConnectionType.posmac:
        details['platformSpecificId'] = printer.platformSpecificId ?? '';
        break;
    }

    return details;
  }

  /// Print via external Android service (share intent)
  Future<bool> printViaExternalService(
    Map<String, dynamic> receiptData, {
    ThermalPaperSize? paperSize,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final args = {'paperSize': paperSize?.name, 'receiptData': receiptData};
      final result = await _channel.invokeMethod(
        'printViaExternalService',
        args,
      );
      return result == true;
    } catch (e) {
      if (_logEnabled) {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        _logController.add('Android printViaExternalService error: $msg');
      }
      return false;
    }
  }

  /// Request USB permission for a specific printer
  Future<bool> requestUsbPermission(Printer printer) async {
    if (!Platform.isAndroid ||
        printer.connectionType != PrinterConnectionType.usb) {
      return false;
    }

    try {
      await initialize();
      final result = await _channel.invokeMethod('requestUsbPermission', {
        'printerId': printer.id,
        'usbDeviceId': printer.usbDeviceId,
        'platformSpecificId': printer.platformSpecificId,
      });
      return result == true;
    } catch (e) {
      developer.log('AndroidPrinterService: USB permission request failed: $e');
      return false;
    }
  }

  /// Parse printer list from native platform result
  List<Printer> _parsePrintersList(dynamic result) {
    if (result == null) return [];

    try {
      final List<dynamic> rawList = result as List<dynamic>;
      return rawList.map((item) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          item as Map,
        );
        return _parsePrinterFromMap(data);
      }).toList();
    } catch (e) {
      developer.log('AndroidPrinterService: Failed to parse printer list: $e');
      return [];
    }
  }

  /// Parse single printer from map data
  Printer _parsePrinterFromMap(Map<String, dynamic> data) {
    final connectionType = PrinterConnectionType.values.firstWhere(
      (e) => e.name == data['connectionType'],
      orElse: () => PrinterConnectionType.usb,
    );

    final type = PrinterType.values.firstWhere(
      (e) => e.name == (data['printerType'] ?? data['type']),
      orElse: () => PrinterType.receipt,
    );

    final paperSize = data['paperSize'] != null
        ? ThermalPaperSize.values.firstWhere(
            (e) => e.name == data['paperSize'],
            orElse: () => ThermalPaperSize.mm80,
          )
        : ThermalPaperSize.mm80;

    // Determine status based on detection, not just permissions
    // A printer can be detected but require permission to use
    final rawStatus =
        data['status'] as String? ?? 'online'; // Default to online if detected
    final hasPermission =
        data['hasPermission'] as bool? ?? true; // Default to true

    final status = PrinterStatus.values.firstWhere(
      (e) => e.name == rawStatus,
      orElse: () =>
          PrinterStatus.online, // Default to online for detected printers
    );

    switch (connectionType) {
      case PrinterConnectionType.usb:
        return Printer.usb(
          id:
              data['id'] ??
              'unknown_usb_${DateTime.now().millisecondsSinceEpoch}',
          name: data['name'] ?? 'Unknown USB Printer',
          type: type,
          usbDeviceId: data['usbDeviceId'],
          platformSpecificId: data['platformSpecificId'],
          modelName: data['modelName'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
        );
      case PrinterConnectionType.bluetooth:
        return Printer.bluetooth(
          id:
              data['id'] ??
              'unknown_bt_${DateTime.now().millisecondsSinceEpoch}',
          name: data['name'] ?? 'Unknown Bluetooth Printer',
          type: type,
          bluetoothAddress: data['bluetoothAddress'],
          platformSpecificId: data['platformSpecificId'],
          modelName: data['modelName'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
        );
      case PrinterConnectionType.network:
        return Printer.network(
          id:
              data['id'] ??
              'unknown_net_${DateTime.now().millisecondsSinceEpoch}',
          name: data['name'] ?? 'Unknown Network Printer',
          type: type,
          ipAddress: data['ipAddress'] ?? '',
          port: data['port'] ?? 9100,
          modelName: data['modelName'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
        );
      default:
        return Printer.usb(
          id: data['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
          name: data['name'] ?? 'Unknown Printer',
          type: type,
          usbDeviceId: data['usbDeviceId'],
          modelName: data['modelName'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
        );
    }
  }

  /// Handle method calls from native Android code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'printerLog':
        final message = call.arguments['message'] as String?;
        if (message != null) {
          developer.log('AndroidPrinterService: $message');
        }
        break;
      default:
        developer.log(
          'AndroidPrinterService: Unknown method call: ${call.method}',
        );
    }
  }

  /// Check printer status for a saved printer using the native plugin
  Future<String> checkPrinterStatus(Printer printer) async {
    if (!Platform.isAndroid) return 'unsupported';
    try {
      await initialize();
      final connectionDetails = _buildConnectionDetails(printer);
      final args = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': connectionDetails,
      };
      final result = await _channel.invokeMethod('checkPrinterStatus', args);
      if (result is String) return result;
      return result?.toString() ?? 'unknown';
    } catch (e) {
      if (_logEnabled) {
        _logController.add('Android checkPrinterStatus error: $e');
      }
      developer.log('AndroidPrinterService: checkPrinterStatus failed: $e');
      return 'error';
    }
  }

  /// Check if USB permission is granted for a printer
  Future<bool> hasUsbPermission(Printer printer) async {
    if (!Platform.isAndroid ||
        printer.connectionType != PrinterConnectionType.usb) {
      return false;
    }

    try {
      await initialize();
      final result = await _channel.invokeMethod('hasUsbPermission', {
        'printerId': printer.id,
        'usbDeviceId': printer.usbDeviceId,
        'platformSpecificId': printer.platformSpecificId,
      });
      return result == true;
    } catch (e) {
      developer.log('AndroidPrinterService: USB permission check failed: $e');
      return false;
    }
  }

  Future<String?> preflightPrinterCheck(Printer printer) async {
    // Basic validation - just check if we can communicate with the service
    try {
      await initialize();
      return null; // OK
    } catch (e) {
      return 'Printer service initialization failed: $e';
    }
  }
}
