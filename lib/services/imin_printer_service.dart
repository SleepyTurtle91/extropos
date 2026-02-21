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
  bool _hasViceScreen = false;  // Always false when imin_vice_screen is disabled
  bool _isInitialized = false;

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

      // Check if vice screen is supported
      // NOTE: We do NOT initialize LCD mode here anymore to prevent overriding Flutter UI
      // We just check if the plugin is available
      /* DISABLED - imin_vice_screen incompatible with Android SDK 36
      try {
        // Just check if we can get an instance, don't send LCD commands
        if (_iminViceScreen != null) {
          // We assume it's supported if we're on an iMin device
          // A better check would be isSupportMultipleScreen() but that's async
          // For now, we'll rely on the DualDisplayService to handle the actual display
          _hasViceScreen = true;
          debugPrint('IMIN: Vice screen support detected');
        }
      } catch (e) {
        _hasViceScreen = false;
        debugPrint('IMIN: Vice screen not available: $e');
      }
      */
      _hasViceScreen = false;  // Disabled until imin_vice_screen is updated

      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
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

  // Future<bool> isDualDisplaySupported() async {
  //   if (!Platform.isAndroid) return false;
  //   try {
  //     _iminViceScreen ??= IminViceScreen();
  //     return await _iminViceScreen!.isSupportMultipleScreen() ?? false;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  // Future<bool> sendTextToCustomerDisplay(String text) async {
  //   if (!Platform.isAndroid) return false;
  //   try {
  //     _iminViceScreen ??= IminViceScreen();
  //     await _iminViceScreen!.doubleScreenOpen();
  //     await _iminViceScreen!.sendMsgToViceScreen(
  //       'text',
  //       params: {'data': text},
  //     );
  //     return true;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  // Future<bool> clearCustomerDisplay() async {
  //   if (!Platform.isAndroid) return false;
  //   try {
  //     _iminViceScreen ??= IminViceScreen();
  //     // Fallback clear: send empty text payload to overwrite screen
  //     await _iminViceScreen!.doubleScreenOpen();
  //     await _iminViceScreen!.sendMsgToViceScreen('text', params: {'data': ''});
  //     return true;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  Future<bool> isDualDisplaySupported() async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
    /* ORIGINAL CODE:
    if (!Platform.isAndroid) return false;
    try {
      _iminViceScreen ??= IminViceScreen();
      final supported =
          await _iminViceScreen!.isSupportMultipleScreen().timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          ) ??
          false;
      debugPrint('IMIN: isDualDisplaySupported = $supported');
      return supported;
    } catch (e) {
      debugPrint('IMIN: isDualDisplaySupported error: $e');
      return false;
    }
    */
  }

  Future<bool> sendTextToCustomerDisplay(String text) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
    /* ORIGINAL CODE:
    if (!Platform.isAndroid) return false;
    try {
      _iminViceScreen ??= IminViceScreen();
      await _iminViceScreen!.doubleScreenOpen();
      await _iminViceScreen!.sendMsgToViceScreen(
        'text',
        params: {'data': text},
      );
      debugPrint('IMIN: Sent text to vice screen: $text');
      return true;
    } catch (e) {
      debugPrint('IMIN: sendTextToCustomerDisplay error: $e');
      return false;
    }
    */
  }

  Future<bool> clearCustomerDisplay() async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  Future<bool> showWelcomeOnCustomerDisplay(String businessName) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  Future<bool> showOrderTotalOnCustomerDisplay(
    double total,
    String currency,
  ) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  Future<bool> showPaymentAmountOnCustomerDisplay(
    double amount,
    String currency,
  ) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  Future<bool> showChangeOnCustomerDisplay(
    double change,
    String currency,
  ) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  Future<bool> showThankYouOnCustomerDisplay() async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  app.PrinterStatus _mapIminStatusToPrinterStatus(dynamic _) {
    // Basic mapping fallback
    return app.PrinterStatus.online;
  }

  /// Check if vice screen is available
  bool get hasViceScreen => false;  // DISABLED - imin_vice_screen incompatible

  /// Display text on vice screen
  Future<bool> displayOnViceScreen(String text) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  /// Display double line text on vice screen
  Future<bool> displayDoubleOnViceScreen(
    String topText,
    String bottomText,
  ) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  /// Clear vice screen
  Future<bool> clearViceScreen() async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }

  /// Wake up the vice screen (unlock if locked)
  Future<void> _wakeViceScreen() async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return;
  }

  /// Public method to wake up the vice screen
  Future<bool> wakeViceScreen() async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    return false;
  }
}
