import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/qr_code_generator.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';

/// Windows-specific printer detection service.
/// Handles USB, network, and local printer discovery on Windows platform.
class WindowsPrinterService {
  static const MethodChannel _channel = MethodChannel(
    'net.nfet.printing',
  );
  // Fallback to the legacy runner channel that supports network/usb printing
  static const MethodChannel _runnerChannel = MethodChannel(
    'com.extrotarget.extropos/printer',
  );

  // Singleton pattern
  static final WindowsPrinterService _instance =
      WindowsPrinterService._internal();
  factory WindowsPrinterService() => _instance;
  WindowsPrinterService._internal();

  bool _isInitialized = false;
  MethodChannel? _activeChannel;
  final StreamController<String> _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  /// Initialize the Windows printer service
  Future<void> initialize() async {
    if (!Platform.isWindows) {
      developer.log(
        'WindowsPrinterService: Not on Windows platform, skipping initialization',
      );
      return;
    }

    if (_isInitialized) {
      return;
    }

    try {
      // Debug logging: set method handler for primary channel
      developer.log(
        'WindowsPrinterService: calling _channel.setMethodCallHandler',
      );
      _channel.setMethodCallHandler(_handleMethodCall);
      // Also set method handler for runner fallback channel so we can receive logs from both
      developer.log('WindowsPrinterService: calling _runnerChannel.setMethodCallHandler');
      _runnerChannel.setMethodCallHandler(_handleMethodCall);
      developer.log('WindowsPrinterService: invoking initialize on channel');
      try {
        final result = await _channel.invokeMethod('initialize');
        developer.log(
          'WindowsPrinterService: invokeMethod initialize returned -> $result',
        );
        try {
          final name = await _channel.invokeMethod('getPluginName');
          developer.log('WindowsPrinterService: primary channel plugin name -> $name');
          _logController.add('[Windows] primary plugin -> $name');
        } catch (e) {}
        _isInitialized = true;
        _activeChannel = _channel;
      } catch (e) {
        developer.log('WindowsPrinterService: primary channel initialize failed: $e; trying runner fallback');
        try {
          final fallbackResult = await _runnerChannel.invokeMethod('initialize');
          developer.log('WindowsPrinterService: runner fallback initialize returned -> $fallbackResult');
          _isInitialized = true;
          _activeChannel = _runnerChannel;
          try {
            final name = await _runnerChannel.invokeMethod('getPluginName');
            developer.log('WindowsPrinterService: runner channel plugin name -> $name');
            _logController.add('[Windows] runner plugin -> $name');
          } catch (e) {}
          _isInitialized = true;
        } catch (err) {
          developer.log('WindowsPrinterService: runner fallback initialize also failed: $err');
          rethrow;
        }
      }
      // Set debug flag on both channels so any plugin implementation that supports
      // debug hex previews will enable them for diagnostics.
      try {
        await _channel.invokeMethod('setDebugEnabled', {'enabled': true});
      } catch (_) {}
      try {
        await _runnerChannel.invokeMethod('setDebugEnabled', {'enabled': true});
      } catch (_) {}
      developer.log('WindowsPrinterService: Initialized successfully, active channel: ${_activeChannel == _channel ? 'net.nfet.printing' : 'com.extrotarget.extropos/printer'}');
    } catch (e) {
      developer.log('WindowsPrinterService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Discover USB printers on Windows
  Future<List<Printer>> discoverUsbPrinters() async {
    if (!Platform.isWindows) {
      return [];
    }

    try {
      await initialize();
      final MethodChannel callChannel = _activeChannel ?? _channel;
      try {
        final result = await callChannel.invokeMethod('discoverUsbPrinters');
        final printers = _parsePrintersList(result);
        developer.log(
          'WindowsPrinterService: Discovered ${printers.length} USB printers',
        );
        return printers;
      } catch (e) {
        developer.log('WindowsPrinterService: Primary channel USB discovery failed: $e');
        // Runner fallback
        try {
          final fallback = await _runnerChannel.invokeMethod('discoverUsbPrinters');
          final printers = _parsePrintersList(fallback);
          developer.log('WindowsPrinterService: Runner fallback discovered ${printers.length} USB printers');
          return printers;
        } catch (err) {
          developer.log('WindowsPrinterService: Runner fallback USB discovery failed: $err');
          return [];
        }
      }
    } catch (e) {
      developer.log('WindowsPrinterService: USB discovery failed: $e');
      return [];
    }
  }

  /// Discover network printers on Windows
  Future<List<Printer>> discoverNetworkPrinters() async {
    if (!Platform.isWindows) {
      return [];
    }

    try {
      await initialize();
      final MethodChannel callChannel = _activeChannel ?? _channel;
      try {
        final result = await callChannel.invokeMethod('discoverNetworkPrinters');
        final printers = _parsePrintersList(result);
        developer.log(
          'WindowsPrinterService: Discovered ${printers.length} network printers',
        );
        return printers;
      } catch (e) {
        developer.log('WindowsPrinterService: Primary channel network discovery failed: $e');
        try {
          final fallback = await _runnerChannel.invokeMethod('discoverNetworkPrinters');
          final printers = _parsePrintersList(fallback);
          developer.log('WindowsPrinterService: Runner fallback discovered ${printers.length} network printers');
          return printers;
        } catch (err) {
          developer.log('WindowsPrinterService: Runner fallback network discovery failed: $err');
          return [];
        }
      }
    } catch (e) {
      developer.log('WindowsPrinterService: Network discovery failed: $e');
      return [];
    }
  }

  /// Discover all local Windows printers
  Future<List<Printer>> discoverLocalPrinters() async {
    if (!Platform.isWindows) {
      return [];
    }

    try {
      await initialize();
      final MethodChannel callChannel = _activeChannel ?? _channel;
      try {
        final result = await callChannel.invokeMethod('discoverLocalPrinters');
        final printers = _parsePrintersList(result);
        developer.log(
          'WindowsPrinterService: Discovered ${printers.length} local printers',
        );
        return printers;
      } catch (e) {
        developer.log('WindowsPrinterService: Primary channel local discovery failed: $e');
        try {
          final fallback = await _runnerChannel.invokeMethod('discoverLocalPrinters');
          final printers = _parsePrintersList(fallback);
          developer.log('WindowsPrinterService: Runner fallback discovered ${printers.length} local printers');
          return printers;
        } catch (err) {
          developer.log('WindowsPrinterService: Runner fallback local discovery failed: $err');
          return [];
        }
      }
    } catch (e) {
      developer.log(
        'WindowsPrinterService: Local printer discovery failed: $e',
      );
      return [];
    }
  }

  /// Discover all printers on Windows (USB, Network, Local)
  Future<List<Printer>> discoverPrinters() async {
    if (!Platform.isWindows) return [];

    try {
      final List<Printer> allPrinters = [];

      // Discover USB printers
      final usbPrinters = await discoverUsbPrinters();
      allPrinters.addAll(usbPrinters);

      // Discover network printers
      final networkPrinters = await discoverNetworkPrinters();
      allPrinters.addAll(networkPrinters);

      // Discover local printers
      final localPrinters = await discoverLocalPrinters();
      allPrinters.addAll(localPrinters);

      developer.log(
        'Windows discovered ${allPrinters.length} total printers (${usbPrinters.length} USB, ${networkPrinters.length} Network, ${localPrinters.length} Local)',
      );

      return allPrinters;
    } catch (e) {
      developer.log('Windows printer discovery failed: $e');
      return [];
    }
  }

  /// Print receipt using Windows printer
  Future<bool> printReceipt(
    Printer printer,
    Map<String, dynamic> receiptData, {
    ReceiptType receiptType = ReceiptType.customer,
  }) async {
    if (!Platform.isWindows) return false;

    try {
      // Format the receipt data into text using the receipt generator
      final charWidth = (printer.paperSize?.name == 'mm80') ? 48 : 32;

      // Generate formatted receipt text using receipt settings so template toggles apply
      final settings = await DatabaseService.instance.getReceiptSettings();
      developer.log('Windows printReceipt: using ReceiptSettings: ${settings.toJson()}');
      final receiptText = generateReceiptTextWithSettings(
        data: receiptData,
        settings: settings,
        charWidth: charWidth,
        receiptType: receiptType,
      );

      developer.log('Windows: Formatted receipt text (preview):\n${receiptText.substring(0, receiptText.length > 200 ? 200 : receiptText.length)}${receiptText.length > 200 ? '... (truncated)' : ''}');

      final Map<String, dynamic> outgoingData = {
        'content': receiptText,
      };

      // Generate QR image if e-wallet QR present
      if (receiptData['ewallet_qr'] != null) {
        try {
          final qrBytes = await QRCodeGenerator.generateQRImageBytes(
            data: receiptData['ewallet_qr'] as String,
            size: 200,
          );
          if (qrBytes != null) {
            outgoingData['ewallet_qr_image'] = qrBytes;
          }
        } catch (e) {
          developer.log('Failed to generate QR image: $e');
        }
      }

      final printData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _buildConnectionDetails(printer),
        'paperSize': printer.paperSize?.name,
        'receiptData': outgoingData,
      };
      final connPreviewOrder = printData['connectionDetails'] as Map<String, dynamic>?;
      if (connPreviewOrder != null) {
        developer.log('Windows printOrder connectionDetails: $connPreviewOrder');
        _logController.add('[Windows] printOrder connectionDetails: $connPreviewOrder');
      }
      // (no-op) previously used for print order logging
      // Log connectionDetails for debugging
      final connPreview = printData['connectionDetails'] as Map<String, dynamic>?;
      if (connPreview != null) {
        developer.log('Windows printReceipt connectionDetails: $connPreview');
        _logController.add('[Windows] printReceipt connectionDetails: $connPreview');
      }

      final MethodChannel callChannel = _activeChannel ?? _channel;
      final result = await callChannel.invokeMethod('printReceipt', printData);
      if (result == true) return true;

      // Fallback: if the chosen plugin failed and we have ip/usb details, try the runner plugin
      try {
        final conn = printData['connectionDetails'] as Map<String, dynamic>?;
        if (conn != null && ((conn['ipAddress'] != null && (conn['ipAddress'] as String).isNotEmpty) || (conn['usbDeviceId'] != null && (conn['usbDeviceId'] as String).isNotEmpty))) {
          developer.log('Windows printReceipt: primary plugin failed, trying runner channel fallback');
          _logController.add('[Windows] printReceipt: primary plugin printing failed, invoking runner fallback');
          final fallbackResult = await _runnerChannel.invokeMethod('printReceipt', printData);
          developer.log('Windows printReceipt: runner fallback result: $fallbackResult');
          if (fallbackResult == true) return true;
        }
      } catch (e) {
        developer.log('Windows printReceipt: fallback runner invocation error: $e');
      }
      return result as bool;
    } catch (e) {
      developer.log('Windows printReceipt error: $e');
      return false;
    }
  }

  /// Print order using Windows printer
  Future<bool> printOrder(
    Printer printer,
    Map<String, dynamic> orderData,
  ) async {
    if (!Platform.isWindows) return false;

    try {
      final printData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _buildConnectionDetails(printer),
        'paperSize': printer.paperSize?.name,
        'orderData': orderData,
      };

      final MethodChannel callChannel = _activeChannel ?? _channel;
      final result = await callChannel.invokeMethod('printOrder', printData);
      if (result == true) return true;
      // Fallback
      try {
        final conn = printData['connectionDetails'] as Map<String, dynamic>?;
        if (conn != null && ((conn['ipAddress'] != null && (conn['ipAddress'] as String).isNotEmpty) || (conn['usbDeviceId'] != null && (conn['usbDeviceId'] as String).isNotEmpty))) {
          developer.log('Windows printOrder: net.nfet print failed, trying runner channel fallback');
          _logController.add('[Windows] printOrder: net.nfet printing failed, invoking runner fallback');
          final fallbackResult = await _runnerChannel.invokeMethod('printOrder', printData);
          developer.log('Windows printOrder: runner fallback result: $fallbackResult');
          if (fallbackResult == true) return true;
        }
      } catch (e) {
        developer.log('Windows printOrder: fallback runner invocation error: $e');
      }
      return result as bool;
    } catch (e) {
      developer.log('Windows printOrder error: $e');
      return false;
    }
  }

  /// Test print using Windows printer
  Future<bool> testPrint(Printer printer) async {
    if (!Platform.isWindows) return false;

    try {
      final testData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _buildConnectionDetails(printer),
        'paperSize': printer.paperSize?.name,
      };
      final connPreview = testData['connectionDetails'] as Map<String, dynamic>?;
      if (connPreview != null) {
        developer.log('Windows testPrint connectionDetails: $connPreview');
        _logController.add('[Windows] testPrint connectionDetails: $connPreview');
      }

      final MethodChannel callChannel = _activeChannel ?? _channel;
      final result = await callChannel.invokeMethod('testPrint', testData);
      _logController.add('Windows testPrint result: $result');
      if (result == true) return true;
      // Try runner plugin fallback for raw socket test prints
      try {
        final conn = testData['connectionDetails'] as Map<String, dynamic>?;
        if (conn != null && (conn['ipAddress'] != null && (conn['ipAddress'] as String).isNotEmpty)) {
          developer.log('Windows testPrint: net.nfet test failed, trying runner channel fallback');
          _logController.add('[Windows] testPrint: net.nfet test failed, invoking runner fallback');
          final fallbackResult = await _runnerChannel.invokeMethod('testPrint', testData);
          _logController.add('Windows testPrint fallback result: $fallbackResult');
          if (fallbackResult == true) return true;
        }
      } catch (e) {
        developer.log('Windows testPrint: fallback runner invocation error: $e');
      }
      return result as bool;
    } catch (e) {
      developer.log('Windows testPrint error: $e');
      return false;
    }
  }

  /// Get printer capabilities/status
  Future<Map<String, dynamic>?> getPrinterCapabilities(
    String printerName,
  ) async {
    if (!Platform.isWindows) {
      return null;
    }

    try {
      await initialize();
      final MethodChannel callChannel = _activeChannel ?? _channel;
      try {
        final result = await callChannel.invokeMethod('getPrinterCapabilities', {
          'printerName': printerName,
        });
        return Map<String, dynamic>.from(result as Map);
      } catch (e) {
        developer.log('WindowsPrinterService: Primary getPrinterCapabilities failed: $e');
        try {
          final fallback = await _runnerChannel.invokeMethod('getPrinterCapabilities', {
            'printerName': printerName,
          });
          return Map<String, dynamic>.from(fallback as Map);
        } catch (err) {
          developer.log('WindowsPrinterService: Runner fallback getPrinterCapabilities failed: $err');
          return null;
        }
      }
    } catch (e) {
      developer.log(
        'WindowsPrinterService: Failed to get printer capabilities: $e',
      );
      return null;
    }
  }

  /// Parse printer list from native Windows result
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
      developer.log('WindowsPrinterService: Failed to parse printer list: $e');
      return [];
    }
  }

  /// Parse single printer from map data
  Printer _parsePrinterFromMap(Map<String, dynamic> data) {
    final type = PrinterType.values.firstWhere(
      (e) => e.name == data['type'],
      orElse: () => PrinterType.receipt,
    );

    final paperSize = data['paperSize'] != null
        ? ThermalPaperSize.values.firstWhere(
            (e) => e.name == data['paperSize'],
            orElse: () => ThermalPaperSize.mm80,
          )
        : ThermalPaperSize.mm80;

    // For Windows, most printers are accessed via POSMAC or direct Windows printing
    return Printer.posmac(
      id: data['id'] ?? 'win_printer_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? 'Unknown Windows Printer',
      type: type,
      platformSpecificId: data['platformSpecificId'] ?? data['printerName'],
      modelName: data['modelName'] ?? data['driverName'],
      paperSize: paperSize,
    );
  }

  /// Build connection details map for native plugin based on the printer type
  Map<String, dynamic> _buildConnectionDetails(Printer printer) {
    final details = <String, dynamic>{};

    switch (printer.connectionType) {
      case PrinterConnectionType.usb:
        details['usbDeviceId'] = printer.usbDeviceId ?? '';
        details['platformSpecificId'] = printer.platformSpecificId ?? '';
        details['usbMode'] = 'native';
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

  /// Handle method calls from native Windows code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'printerLog':
        final message = call.arguments['message'] as String?;
        if (message != null) {
          developer.log('WindowsPrinterService: $message');
          _logController.add('[Windows] $message');
        }
        break;
      case 'printerStatusChanged':
        final printerName = call.arguments['printerName'] as String?;
        final status = call.arguments['status'] as String?;
        if (printerName != null && status != null) {
          developer.log(
            'WindowsPrinterService: Printer $printerName status changed to $status',
          );
        }
        break;
      default:
        developer.log(
          'WindowsPrinterService: Unknown method call: ${call.method}',
        );
    }
  }

  /// Check printer status for a saved printer via the plugin
  Future<String> checkPrinterStatus(Printer printer) async {
    if (!Platform.isWindows) return 'unsupported';
    try {
      await initialize();
      final args = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _buildConnectionDetails(printer),
      };
      // Prefer the net.nfet channel; in case it doesn't implement, fallback to runner channel
      final MethodChannel callChannel = _activeChannel ?? _channel;
      try {
        final result = await callChannel.invokeMethod('checkPrinterStatus', args);
        if (result is String) return result;
        return result?.toString() ?? 'unknown';
      } catch (e) {
        developer.log('WindowsPrinterService: primary checkPrinterStatus failed: $e');
        try {
          final fallback = await _runnerChannel.invokeMethod('checkPrinterStatus', args);
          if (fallback is String) return fallback;
          return fallback?.toString() ?? 'unknown';
        } catch (_) {
          return 'unknown';
        }
      }
    } catch (e) {
      developer.log('WindowsPrinterService: checkPrinterStatus failed: $e');
      return 'error';
    }
  }

  /// Check if a printer is available/online
  Future<bool> isPrinterOnline(String printerName) async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      await initialize();
      final MethodChannel callChannel = _activeChannel ?? _channel;
      try {
        final result = await callChannel.invokeMethod('isPrinterOnline', {
          'printerName': printerName,
        });
        return result == true;
      } catch (e) {
        developer.log('WindowsPrinterService: Primary isPrinterOnline failed: $e; trying runner fallback');
        try {
          final fallback = await _runnerChannel.invokeMethod('isPrinterOnline', {
            'printerName': printerName,
          });
          return fallback == true;
        } catch (err) {
          developer.log('WindowsPrinterService: Runner fallback isPrinterOnline failed: $err');
          return false;
        }
      }
    } catch (e) {
      developer.log('WindowsPrinterService: Printer online check failed: $e');
      return false;
    }
  }
}
