import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service.dart';

/// Layer A: Business logic for printer operations (database, device detection, service initialization)
/// This service handles all printer-related operations without UI dependencies.
/// The screen uses callbacks to update UI state after operations complete.
class PrinterBusinessLogicService {
  final PrinterService _printerService;

  PrinterBusinessLogicService(this._printerService);

  /// Load printers from database
  /// Returns the list of saved printers
  static Future<List<Printer>> loadPrinters() async {
    try {
      final savedPrinters = await DatabaseService.instance.getPrinters();
      return savedPrinters;
    } catch (e) {
      debugPrint('Error loading printers: $e');
      return [];
    }
  }

  /// Load categories from database
  /// Returns the list of available categories
  static Future<List<Category>> loadCategories() async {
    try {
      final categories = await DatabaseService.instance.getCategories();
      return categories;
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
  }

  /// Detect if device is iMin (e.g., iMin Swan 2)
  /// Used to enable/disable iMin-specific features
  static Future<bool> isIMinDevice() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().deviceInfo;
      if (deviceInfo is AndroidDeviceInfo) {
        final model = deviceInfo.model.toLowerCase();
        final manufacturer = deviceInfo.manufacturer.toLowerCase();
        final brand = deviceInfo.brand.toLowerCase();

        debugPrint('📱 Device info: $manufacturer $brand $model');

        // iMin Swan 2 detection
        return model.contains('swan') ||
            manufacturer.contains('imin') ||
            brand.contains('imin') ||
            model.contains('imin');
      }
    } catch (e) {
      debugPrint('❌ Failed to detect device: $e');
    }

    return false;
  }

  /// Initialize the printer service
  /// Must be called before any printer operations
  Future<void> initializePrinterService() async {
    try {
      debugPrint('🔧 Initializing printer service...');
      await _printerService.initialize();
      debugPrint('✅ Printer service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize printer service: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Test print to a specific printer
  /// Updates printer status and last printed timestamp in database
  /// Returns true if test print succeeded
  Future<bool> testPrint(Printer printer) async {
    try {
      final success = await _printerService.testPrint(printer);

      if (success) {
        // Update printer status to online and save to database
        printer.status = PrinterStatus.online;
        printer.lastPrintedAt = DateTime.now();
        if (!printer.hasPermission) {
          printer.hasPermission = true;
        }
        await DatabaseService.instance.savePrinter(printer);
      } else {
        // Update printer status to error when test print fails
        printer.status = PrinterStatus.error;
        await DatabaseService.instance.savePrinter(printer);
      }

      return success;
    } catch (e) {
      debugPrint('Error testing printer: $e');
      rethrow;
    }
  }

  /// Print via external service (e.g., ESCPrint)
  /// Returns true if the external service was opened
  Future<bool> printViaExternalService(
    Map<String, dynamic> receipt, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm80,
  }) async {
    try {
      return await _printerService.printViaExternalService(
        receipt,
        paperSize: paperSize,
      );
    } catch (e) {
      debugPrint('Error printing via external service: $e');
      rethrow;
    }
  }

  /// Request USB permission for a printer
  /// Returns true if permission was granted
  Future<bool> requestUsbPermission(Printer printer) async {
    try {
      return await _printerService.requestUsbPermission(printer).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('USB permission request timed out');
              return false;
            },
          );
    } catch (e) {
      debugPrint('Error requesting USB permission: $e');
      rethrow;
    }
  }

  /// Request Bluetooth permission for a printer
  /// Returns true if permission was granted
  Future<bool> requestBluetoothPermission(Printer printer) async {
    try {
      return await _printerService.requestBluetoothPermission(printer);
    } catch (e) {
      debugPrint('Error requesting Bluetooth permission: $e');
      rethrow;
    }
  }

  /// Toggle default printer status
  /// Ensures only one printer per type is marked as default
  /// Returns updated printer with new default status, or null if error
  static Future<Printer?> toggleDefault(
    Printer printer,
    List<Printer> allPrinters,
  ) async {
    try {
      // Create updated copy with toggled default status
      final updated = printer.copyWith(isDefault: !printer.isDefault);

      // If setting as default, unset other printers of same type
      if (updated.isDefault) {
        for (var p in allPrinters) {
          if (p.type == updated.type && p.id != updated.id && p.isDefault) {
            p.isDefault = false;
            await DatabaseService.instance.savePrinter(p);
          }
        }
      }

      // Save the updated printer
      await DatabaseService.instance.savePrinter(updated);
      return updated;
    } catch (e) {
      debugPrint('Error toggling default printer: $e');
      rethrow;
    }
  }

  /// Save a new printer to database
  /// Returns the saved printer
  static Future<Printer> savePrinter(Printer printer) async {
    try {
      await DatabaseService.instance.savePrinter(printer);
      return printer;
    } catch (e) {
      debugPrint('Error saving printer: $e');
      rethrow;
    }
  }

  /// Delete a printer from database
  /// Returns true if deletion succeeded
  static Future<bool> deletePrinter(String printerId) async {
    try {
      await DatabaseService.instance.deletePrinter(printerId);
      return true;
    } catch (e) {
      debugPrint('Error deleting printer: $e');
      return false;
    }
  }
}
