import 'dart:async';
import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/android_printer_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/imin_printer_service.dart';
import 'package:extropos/services/permissions_helper.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:extropos/services/windows_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

part 'printer_service_clean_discovery.dart';
part 'printer_service_clean_print.dart';

/// Clean PrinterService implementation
class PrinterService {
  final AndroidPrinterService _androidService = AndroidPrinterService();
  final WindowsPrinterService _windowsService = WindowsPrinterService();

  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final StreamController<Printer> _printerStatusController = StreamController<Printer>.broadcast();
  Stream<Printer> get printerStatusStream => _printerStatusController.stream;

  final StreamController<String> _printerLogController = StreamController<String>.broadcast();
  Stream<String> get printerLogStream => _printerLogController.stream;
  
  bool _printerLogEnabled = true;
  final List<String> _recentPrinterLogs = [];
  Completer<void>? _operationLock;

  Future<T> _synchronized<T>(Future<T> Function() action) async {
    while (_operationLock != null) {
      try { await _operationLock!.future; } catch (_) {}
    }
    _operationLock = Completer<void>();
    try { return await action(); } finally {
      try { _operationLock?.complete(); } catch (_) {}
      _operationLock = null;
    }
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _printerLogEnabled = prefs.getBool('printer_log_enabled') ?? true;
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

  List<String> getRecentPrinterLogs({int count = 50}) => _recentPrinterLogs.take(count).toList();

  Future<void> setPrinterLogEnabled(bool enabled) async {
    _printerLogEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('printer_log_enabled', enabled);
    } catch (_) {}
    _androidService.setLogEnabled(enabled);
  }

  String? validatePrinterConfig(Printer printer) {
    switch (printer.connectionType) {
      case PrinterConnectionType.network:
        return (printer.ipAddress == null || printer.ipAddress!.isEmpty || printer.ipAddress == '192.168.1.') 
          ? 'Network printer missing IP' : null;
      case PrinterConnectionType.usb:
        return (printer.usbDeviceId == null || printer.usbDeviceId!.isEmpty) ? 'USB printer missing device id' : null;
      case PrinterConnectionType.bluetooth:
        return (printer.bluetoothAddress == null || printer.bluetoothAddress!.isEmpty) ? 'Bluetooth printer missing address' : null;
      default:
        return null;
    }
  }

  Future<String?> preflightPrinterCheck(Printer printer) async => validatePrinterConfig(printer);

  void dispose() {
    _printerStatusController.close();
    _printerLogController.close();
  }
}
