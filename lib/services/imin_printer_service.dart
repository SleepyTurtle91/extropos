import 'dart:async';

import 'package:extropos/models/printer_model.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:imin_printer/enums.dart' as imin;
import 'package:imin_printer/imin_printer.dart';
// import 'package:imin_vice_screen/enums.dart';  // DISABLED - Incompatible with Android SDK 36
// import 'package:imin_vice_screen/imin_vice_screen.dart';  // DISABLED
import 'package:universal_io/io.dart';

/// IMIN-specific printer service that isolates IMIN functionality
/// from the generic Android printer implementation
class IminPrinterService {
  static final IminPrinterService _instance = IminPrinterService._internal();
  factory IminPrinterService() => _instance;
  IminPrinterService._internal();

  IminPrinter? _iminPrinter;
  // IminViceScreen? _iminViceScreen;  // DISABLED - Incompatible with Android SDK 36
  bool _isInitialized = false;
  bool _hasViceScreen = false;
  bool _isViceScreenAwake = false;

  /// Initialize IMIN printer service
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      _iminPrinter = IminPrinter();
      // _iminViceScreen = IminViceScreen();  // DISABLED - Incompatible with Android SDK 36

      // Add timeout to prevent hanging on non-IMIN devices
      await _iminPrinter!.initPrinter().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('IMIN printer initialization timeout');
        },
      );

      _isInitialized = true;
      await _initializeViceScreenMode();
    } catch (_) {
      _isInitialized = false;
      _hasViceScreen = false;
      _isViceScreenAwake = false;
    }
  }

  Future<void> _initializeViceScreenMode() async {
    if (!Platform.isAndroid || !_isInitialized) {
      _hasViceScreen = false;
      _isViceScreenAwake = false;
      return;
    }

    // Plugin is disabled for SDK compatibility. We use printer init success as
    // proxy signal that IMIN hardware is available and Flutter-route vice mode
    // can be used.
    _hasViceScreen = true;
    _isViceScreenAwake = true;
    debugPrint('IMIN: Vice screen mode initialized (Flutter route mode)');
  }

  /// Check if IMIN printer is available
  Future<bool> isIminPrinterAvailable() async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.getPrinterStatus();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get IMIN printer status
  Future<app.PrinterStatus?> getPrinterStatus() async {
    if (!Platform.isAndroid || !_isInitialized) return null;
    try {
      final status = await _iminPrinter!.getPrinterStatus();
      return _mapIminStatusToPrinterStatus(status);
    } catch (_) {
      return null;
    }
  }

  /// Print receipt using IMIN printer
  Future<bool> printReceipt(String content) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      final lines = content.split('\n');
      for (final line in lines) {
        await _iminPrinter!.printText(line);
        await _iminPrinter!.printAndLineFeed();
      }
      await _iminPrinter!.partialCut();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> printAndFeed() async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.printAndLineFeed();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cutPaper() async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.partialCut();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Print text with formatting options
  Future<bool> printTextWithFormat(
    String text, {
    imin.IminPrintAlign alignment = imin.IminPrintAlign.left,
    imin.IminFontStyle style = imin.IminFontStyle.normal,
    int size = 1,
  }) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      debugPrint('IMIN: Setting alignment to $alignment');
      await setAlignment(alignment);
      debugPrint('IMIN: Setting style to $style');
      await setTextStyle(style);
      debugPrint('IMIN: Setting size to $size');
      await setTextSize(size);
      debugPrint('IMIN: Printing text: "$text"');
      await _iminPrinter!.printText(text);
      await _iminPrinter!.printAndLineFeed();
      return true;
    } catch (e) {
      debugPrint('IMIN: Error printing text: $e');
      return false;
    }
  }

  Future<bool> setAlignment(imin.IminPrintAlign alignment) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.setAlignment(alignment);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setTextSize(int size) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.setTextSize(size);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setTextStyle(imin.IminFontStyle style) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.setTextStyle(style);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDualDisplaySupported() async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    return _hasViceScreen;
  }

  Future<bool> sendTextToCustomerDisplay(String text) async {
    return displayOnViceScreen(text);
  }

  Future<bool> clearCustomerDisplay() async {
    return clearViceScreen();
  }

  Future<bool> showWelcomeOnCustomerDisplay(String businessName) async {
    return displayDoubleOnViceScreen('WELCOME', businessName.toUpperCase());
  }

  Future<bool> showOrderTotalOnCustomerDisplay(
    double total,
    String currency,
  ) async {
    return displayDoubleOnViceScreen(
      'TOTAL',
      '$currency${total.toStringAsFixed(2)}',
    );
  }

  Future<bool> showPaymentAmountOnCustomerDisplay(
    double amount,
    String currency,
  ) async {
    return displayDoubleOnViceScreen(
      'PAYMENT',
      '$currency${amount.toStringAsFixed(2)}',
    );
  }

  Future<bool> showChangeOnCustomerDisplay(
    double change,
    String currency,
  ) async {
    return displayDoubleOnViceScreen(
      'CHANGE',
      '$currency${change.toStringAsFixed(2)}',
    );
  }

  Future<bool> showThankYouOnCustomerDisplay() async {
    return displayDoubleOnViceScreen('THANK YOU', 'PLEASE COME AGAIN');
  }

  app.PrinterStatus _mapIminStatusToPrinterStatus(dynamic _) {
    // Basic mapping fallback
    return app.PrinterStatus.online;
  }

  /// Check if vice screen is available
  bool get hasViceScreen => _hasViceScreen;

  bool get isViceScreenAwake => _isViceScreenAwake;

  /// Display text on vice screen
  Future<bool> displayOnViceScreen(String text) async {
    if (!Platform.isAndroid || !_isInitialized || !_hasViceScreen) {
      return false;
    }

    _isViceScreenAwake = true;
    debugPrint('IMIN Vice: $text');
    return true;
  }

  /// Display double line text on vice screen
  Future<bool> displayDoubleOnViceScreen(
    String topText,
    String bottomText,
  ) async {
    return displayOnViceScreen('$topText\n$bottomText');
  }

  /// Clear vice screen
  Future<bool> clearViceScreen() async {
    if (!Platform.isAndroid || !_isInitialized || !_hasViceScreen) {
      return false;
    }

    _isViceScreenAwake = true;
    debugPrint('IMIN Vice: cleared');
    return true;
  }

  /// Public method to wake up the vice screen
  Future<bool> wakeViceScreen() async {
    if (!Platform.isAndroid || !_isInitialized || !_hasViceScreen) {
      return false;
    }

    _isViceScreenAwake = true;
    debugPrint('IMIN: Vice screen wake requested');
    return true;
  }
}
