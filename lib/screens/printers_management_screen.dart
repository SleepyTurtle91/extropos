import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/screens/printer_debug_console.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/dialog_helpers.dart';
import 'package:extropos/widgets/responsive_row.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple printers management screen.
///
/// Allows adding/editing/deleting printers and includes a "Grant USB Permission"
/// action which calls into [PrinterService.requestUsbPermission].
class PrintersManagementScreen extends StatefulWidget {
  final String? openPrinterId;
  const PrintersManagementScreen({super.key, this.openPrinterId});

  /// Static helper to open the editor dialog for a single printer and return the updated printer on save
  static Future<Printer?> openPrinterEditor(
    BuildContext context,
    Printer printer,
  ) {
    return showDialog<Printer?>(
      context: context,
      builder: (ctx) => _PrinterFormDialog(
        printer: printer,
        onSave: (updatedPrinter) async {
          await DatabaseService.instance.savePrinter(updatedPrinter);
          Navigator.pop(ctx, updatedPrinter);
        },
      ),
    );
  }

  @override
  State<PrintersManagementScreen> createState() =>
      _PrintersManagementScreenState();
}

class _PrintersManagementScreenState extends State<PrintersManagementScreen> {
  List<Printer> printers = [];
  List<Category> _availableCategories = [];
  final PrinterService _printerService = PrinterService();
  bool _isLoading = true;
  bool _isInitialized = false;
  String _searchQuery = '';
  String? _selectedPrinterId;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization to avoid blocking UI during navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  Future<void> _initializeAsync() async {
    if (!mounted) return;

    // Load cached printers first (fast)
    await _loadPrinters();

    // Load categories for kitchen/bar assignment
    await _loadCategories();

    // Then initialize printer service in background (slow)
    try {
      await _initializePrinterService();
      _isInitialized = true;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenEdit());
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(
          context,
          'Failed to initialize printer service: $e',
        );
      }
    }
  }

  Future<void> _maybeOpenEdit() async {
    if (widget.openPrinterId == null) return;
    final savedPrinters = await DatabaseService.instance.getPrinters();
    Printer? target;
    try {
      target = savedPrinters.firstWhere((p) => p.id == widget.openPrinterId);
    } catch (e) {
      target = null;
    }
    if (target != null) {
      // Wait for the UI to update before opening dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => _PrinterFormDialog(
          printer: target,
          onSave: (printer) async {
            await DatabaseService.instance.savePrinter(printer);
            if (!mounted) return;
            Navigator.pop(ctx);
          },
        ),
      );
    }
  }

  Future<void> _initializePrinterService() async {
    try {
      debugPrint('🔧 Initializing printer service...');
      await _printerService.initialize();
      debugPrint('✅ Printer service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize printer service: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ToastHelper.showToast(
          context,
          'Failed to initialize printer service: ${e.toString()}',
        );
      }
      rethrow;
    }
  }

  Future<void> _printViaExternalServiceTest() async {
    final now = DateTime.now();
    final receipt = {
      'title': 'TEST PRINT',
      'content':
          'This is a test receipt from FlutterPOS.\n\nItems:\nSample Item x 1 RM 1.00\n\nSubtotal: RM 1.00\nTotal: RM 1.00',
      'timestamp': now.toString(),
    };
    final ok = await _printerService.printViaExternalService(
      receipt,
      paperSize: ThermalPaperSize.mm80,
    );
    if (!mounted) return;
    ToastHelper.showToast(
      context,
      ok
          ? 'Opened ESCPrint Service (or chooser) for external print'
          : 'Failed to open external print service',
    );
  }

  Future<void> _loadPrinters() async {
    try {
      // Only load saved printers from database - fast and no lag
      final savedPrinters = await DatabaseService.instance.getPrinters();
      if (!mounted) return;
      setState(() {
        printers = savedPrinters;
        _isLoading = false;
        final preferred = widget.openPrinterId ?? _selectedPrinterId;
        if (preferred != null &&
            printers.any((printer) => printer.id == preferred)) {
          _selectedPrinterId = preferred;
        } else if (printers.isNotEmpty) {
          _selectedPrinterId = printers.first.id;
        } else {
          _selectedPrinterId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(context, 'Error loading printers: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DatabaseService.instance.getCategories();
      if (!mounted) return;
      setState(() => _availableCategories = categories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _availableCategories = []);
    }
  }

  Future<bool> _isIMinDevice() async {
    try {
      // Check device model for iMin Swan 2
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

    // Default to non-iMin when detection fails
    return false;
  }

  Future<void> _discoverPrintersAsync() async {
    if (!mounted || !_isInitialized) return;

    try {
      debugPrint('🔍 Starting printer discovery...');

      // Detect iMin hardware and use very short timeout to prevent lag
      final isIMin = await _isIMinDevice();
      final timeoutDuration = isIMin
          ? const Duration(seconds: 2) // Reduced from 3 to 2 seconds
          : const Duration(seconds: 8); // Reduced from 10 to 8 seconds

      debugPrint(
        '📱 Device type: ${isIMin ? "iMin (2s timeout)" : "Other (8s timeout)"}',
      );

      // Show subtle indicator that discovery is running
      if (mounted) {
        ToastHelper.showToast(context, 'Discovering printers...');
      }

      // Add timeout to prevent hanging on iMin devices
      final discoveredPrinters = await _printerService.discoverPrinters().timeout(
        timeoutDuration,
        onTimeout: () {
          debugPrint(
            '⏱️ Printer discovery timed out after ${timeoutDuration.inSeconds} seconds',
          );
          if (mounted) {
            ToastHelper.showToast(
              context,
              'Printer discovery timed out. Some printers may not be detected.',
            );
          }
          return [];
        },
      );

      debugPrint('✅ Discovered ${discoveredPrinters.length} printers');

      if (!mounted) return;

      // Collect new printers to confirm
      final newPrinters = <Printer>[];
      final updatedPrinters = <Printer>[];

      for (final discovered in discoveredPrinters) {
        debugPrint(
          '  📍 Found: ${discovered.name} (${discovered.connectionType.name})',
        );

        final savedIndex = printers.indexWhere(
          (p) =>
              p.platformSpecificId == discovered.platformSpecificId ||
              p.id == discovered.id,
        );
        if (savedIndex == -1) {
          newPrinters.add(discovered);
        } else {
          // Only update if status actually changed to avoid unnecessary rebuilds
          final saved = printers[savedIndex];
          if (saved.status != discovered.status ||
              saved.hasPermission != discovered.hasPermission) {
            saved.status = discovered.status;
            saved.hasPermission = discovered.hasPermission;
            updatedPrinters.add(saved);
            debugPrint('    🔄 Updated printer: ${saved.name}');
          }
        }
      }

      // Update existing printers
      if (updatedPrinters.isNotEmpty) {
        setState(() {
          // Already updated in the loop above
        });
        // Persist updates asynchronously
        for (final updated in updatedPrinters) {
          unawaited(DatabaseService.instance.savePrinter(updated));
        }
      }

      // Confirm and add new printers
      for (final newPrinter in newPrinters) {
        final shouldAdd = await _confirmAddPrinter(newPrinter);
        if (shouldAdd && mounted) {
          try {
            await DatabaseService.instance.savePrinter(newPrinter);
            setState(() => printers.add(newPrinter));
            debugPrint('    ➕ Added new printer: ${newPrinter.name}');
            ToastHelper.showToast(context, 'Added printer: ${newPrinter.name}');
          } catch (e) {
            debugPrint('❌ Failed to save printer: $e');
            ToastHelper.showToast(context, 'Failed to save printer: $e');
          }
        } else {
          debugPrint('    ❌ Skipped adding printer: ${newPrinter.name}');
        }
      }

      // Show success message if printers found
      if (mounted && discoveredPrinters.isNotEmpty) {
        ToastHelper.showToast(
          context,
          'Discovery complete. ${newPrinters.length} new printer(s) found.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error discovering printers: $e');
      debugPrint('Stack trace: $stackTrace');

      // Show error to user for better debugging
      if (mounted) {
        ToastHelper.showToast(
          context,
          'Printer discovery failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _searchBluetoothPrinters() async {
    try {
      if (!mounted) return;

      setState(() => _isLoading = true);
      debugPrint('🔵 Starting Bluetooth printer search...');
      ToastHelper.showToast(context, 'Searching for Bluetooth printers...');

      // Discover only Bluetooth printers with timeout
      final bluetoothPrinters = await _printerService
          .discoverBluetoothPrinters()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('⏱️ Bluetooth discovery timed out');
              return [];
            },
          );

      debugPrint('✅ Found ${bluetoothPrinters.length} Bluetooth printers');

      if (!mounted) return;

      // Collect new printers to confirm
      final newBluetoothPrinters = bluetoothPrinters
          .where((printer) => !printers.any((p) => p.id == printer.id))
          .toList();

      // Confirm and add new printers
      for (final newPrinter in newBluetoothPrinters) {
        final shouldAdd = await _confirmAddPrinter(newPrinter);
        if (shouldAdd && mounted) {
          try {
            await DatabaseService.instance.savePrinter(newPrinter);
            setState(() => printers.add(newPrinter));
            debugPrint('  ➕ Added Bluetooth printer: ${newPrinter.name}');
            ToastHelper.showToast(
              context,
              'Added Bluetooth printer: ${newPrinter.name}',
            );
          } catch (e) {
            debugPrint('❌ Failed to save Bluetooth printer: $e');
            ToastHelper.showToast(
              context,
              'Failed to save Bluetooth printer: $e',
            );
          }
        } else {
          debugPrint(
            '  ❌ Skipped adding Bluetooth printer: ${newPrinter.name}',
          );
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(
        context,
        newBluetoothPrinters.isEmpty
            ? 'No new Bluetooth printers found'
            : 'Bluetooth search complete. ${newBluetoothPrinters.length} new printer(s) found.',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error searching Bluetooth printers: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(context, 'Error searching Bluetooth printers: $e');
    }
  }

  Future<void> _searchUsbPrinters() async {
    setState(() => _isLoading = true);
    try {
      if (!mounted) return;

      setState(() => _isLoading = true);
      debugPrint('🔌 Starting USB printer search...');
      ToastHelper.showToast(context, 'Searching for USB printers...');

      // Discover only USB printers with timeout
      final usbPrinters = await _printerService.discoverUsbPrinters().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ USB discovery timed out');
          return [];
        },
      );

      debugPrint('✅ Found ${usbPrinters.length} USB printers');

      if (!mounted) return;

      // Collect new printers to confirm
      final newUsbPrinters = usbPrinters
          .where((printer) => !printers.any((p) => p.id == printer.id))
          .toList();

      // Confirm and add new printers
      for (final newPrinter in newUsbPrinters) {
        final shouldAdd = await _confirmAddPrinter(newPrinter);
        if (shouldAdd && mounted) {
          try {
            await DatabaseService.instance.savePrinter(newPrinter);
            setState(() => printers.add(newPrinter));
            debugPrint('  ➕ Added USB printer: ${newPrinter.name}');
            ToastHelper.showToast(
              context,
              'Added USB printer: ${newPrinter.name}',
            );
          } catch (e) {
            debugPrint('❌ Failed to save USB printer: $e');
            ToastHelper.showToast(context, 'Failed to save USB printer: $e');
          }
        } else {
          debugPrint('  ❌ Skipped adding USB printer: ${newPrinter.name}');
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(
        context,
        newUsbPrinters.isEmpty
            ? 'No new USB printers found'
            : 'USB search complete. ${newUsbPrinters.length} new printer(s) found.',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error searching USB printers: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(context, 'Error searching USB printers: $e');
    }
  }

  Future<bool> _confirmAddPrinter(Printer printer) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add Printer'),
            content: Text(
              'Found printer: ${printer.name} (${printer.connectionType.name}). Add it to your printers?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _addPrinter() {
    showDialog(
      context: context,
      builder: (context) => _PrinterFormDialog(
        onSave: (printer) async {
          try {
            // Save to database
            await DatabaseService.instance.savePrinter(printer);
            if (!mounted) return;

            // Verify the printer was saved
            final savedPrinters = await DatabaseService.instance.getPrinters();
            final saved = savedPrinters.any((p) => p.id == printer.id);

            setState(() {
              printers.add(printer);
              _selectedPrinterId = printer.id;
            });
            if (mounted) {
              ToastHelper.showToast(
                context,
                saved
                    ? 'Printer saved successfully (ID: ${printer.id})'
                    : 'Printer saved but not found in database',
              );
            }
          } catch (e) {
            if (mounted) {
              ToastHelper.showToast(context, 'Failed to save printer: $e');
            }
          }
        },
      ),
    );
  }

  void _editPrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => _PrinterFormDialog(
        printer: printer,
        onSave: (updatedPrinter) async {
          // Save to database
          await DatabaseService.instance.savePrinter(updatedPrinter);
          if (!mounted) return;
          setState(() {
            final index = printers.indexWhere((p) => p.id == updatedPrinter.id);
            if (index != -1) printers[index] = updatedPrinter;
          });
          if (mounted) ToastHelper.showToast(context, 'Printer updated');
        },
      ),
    );
  }

  void _deletePrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Printer'),
        content: Text('Are you sure you want to delete "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete from database
              await DatabaseService.instance.deletePrinter(printer.id);
              if (!mounted) return;
              setState(() {
                printers.removeWhere((p) => p.id == printer.id);
                if (_selectedPrinterId == printer.id) {
                  _selectedPrinterId =
                      printers.isNotEmpty ? printers.first.id : null;
                }
              });
              if (!mounted) return;
              Navigator.pop(context);
              if (mounted) ToastHelper.showToast(context, 'Printer deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _testPrint(Printer printer) async {
    try {
      final success = await _printerService.testPrint(printer);
      if (!mounted) return;

      if (success) {
        // Update printer status to online and save to database
        printer.status = PrinterStatus.online;
        printer.lastPrintedAt = DateTime.now();
        if (!printer.hasPermission) {
          printer.hasPermission = true;
        }
        await DatabaseService.instance.savePrinter(printer);
        // Refresh the printer list to show updated status
        await _loadPrinters();
      } else {
        // Update printer status to error when test print fails
        printer.status = PrinterStatus.error;
        await DatabaseService.instance.savePrinter(printer);
        // Refresh the printer list to show updated status
        await _loadPrinters();
      }

      // Show snackbar after all async operations
      if (mounted) {
        ToastHelper.showToast(
          context,
          success
              ? 'Test print sent to ${printer.name}'
              : 'Failed to print test to ${printer.name}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error testing printer: $e');
    }
  }

  Future<void> _sampleReceiptPrint(Printer printer) async {
    try {
      // Pre-check connection details to avoid unnecessary fallback behavior
      String? invalidReason;
      switch (printer.connectionType) {
        case PrinterConnectionType.network:
          if (printer.ipAddress == null ||
              printer.ipAddress!.isEmpty ||
              printer.ipAddress == '192.168.1.') {
            invalidReason =
                'Network printer missing IP address or using default placeholder (e.g. 192.168.1.). Please edit the printer.';
          }
          break;
        case PrinterConnectionType.usb:
          if (printer.usbDeviceId == null || printer.usbDeviceId!.isEmpty) {
            invalidReason =
                'USB printer missing device id. Please grant USB permission and re-save the printer.';
          }
          break;
        case PrinterConnectionType.bluetooth:
          if (printer.bluetoothAddress == null ||
              printer.bluetoothAddress!.isEmpty) {
            invalidReason =
                'Bluetooth printer missing address. Please edit the printer and set the device address.';
          }
          break;
        default:
          break;
      }

      if (invalidReason != null) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invalid Printer Configuration'),
            content: Text(invalidReason ?? 'Invalid printer configuration'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editPrinter(printer);
                },
                child: const Text('Edit'),
              ),
            ],
          ),
        );
        return;
      }
      final now = DateTime.now();
      final receipt = {
        'businessName': 'ExtroPOS Test Store',
        'address': '123 Flutter Lane\nTestville',
        'orderNumber': '001',
        'dateTime': now.toIso8601String(),
        'items': [
          {
            'name': 'Sample Item A',
            'quantity': 1,
            'price': 5.00,
            'total': 5.00,
            'modifiers': [],
          },
          {
            'name': 'Sample Item B',
            'quantity': 2,
            'price': 3.50,
            'total': 7.00,
            'modifiers': [],
          },
        ],
        'subtotal': 12.00,
        'tax': 0.00,
        'serviceCharge': 0.00,
        'total': 12.00,
        'paymentMethod': 'Cash',
        'amountPaid': 12.00,
        'change': 0.00,
        'currency': 'RM',
      };

      final success = await _printerService.printReceipt(printer, receipt);
      if (!mounted) return;
      if (success) {
        ToastHelper.showToast(
          context,
          'Sample receipt sent to ${printer.name}',
        );
        // Mark printedAt and save
        printer.status = PrinterStatus.online;
        printer.lastPrintedAt = DateTime.now();
        if (!printer.hasPermission) {
          printer.hasPermission = true;
        }
        await DatabaseService.instance.savePrinter(printer);
        await _loadPrinters();
      } else {
        // If structured print failed, check whether a simple test print works
        final testOk = await _printerService.testPrint(printer);

        // Provide a more helpful error message when connection details are invalid
        String diag = '';
        // Check validation from PrinterService if we don't have an obvious clue
        final validationIssue = _printerService.validatePrinterConfig(printer);
        if (validationIssue != null && validationIssue.isNotEmpty) {
          diag = validationIssue;
        }
        switch (printer.connectionType) {
          case PrinterConnectionType.network:
            if (printer.ipAddress == null ||
                printer.ipAddress!.isEmpty ||
                printer.ipAddress == '192.168.1.') {
              diag =
                  'Printer appears to be a Network printer but IP/Port is missing or invalid. Please edit the printer and enter the correct IP & Port.';
            }
            break;
          case PrinterConnectionType.usb:
            if (printer.usbDeviceId == null || printer.usbDeviceId!.isEmpty) {
              diag =
                  'Printer appears to be a USB printer but device id/platform id is missing. Please re-add or edit the printer and grant USB permissions.';
            }
            break;
          case PrinterConnectionType.bluetooth:
            if (printer.bluetoothAddress == null ||
                printer.bluetoothAddress!.isEmpty) {
              diag =
                  'Printer appears to be a Bluetooth printer but the device address is missing. Please edit the printer and set the bluetooth address.';
            }
            break;
          default:
            diag =
                'Printer failed to print. Check recent logs and verify connection details.';
        }

        final pluginMsg = _printerService.getLastPluginMessage();
        final summary = pluginMsg != null && pluginMsg.isNotEmpty
            ? pluginMsg
            : (diag.isNotEmpty ? diag : 'Sample receipt failed');
        ToastHelper.showToast(
          context,
          'Sample receipt failed to ${printer.name}: $summary',
        );
        // Show a dialog containing recent plugin logs to assist with debugging
        final logs = _printerService.getRecentPrinterLogs(count: 50);
        if (!mounted) return;
        // Auto-run native debug print if enabled in settings and a simple test print succeeded
        if (AppSettings.instance.autoDebugPrintOnSampleFailure && testOk) {
          // Run debug force print (bypass validation) and show results
          ToastHelper.showToast(context, 'Auto-running native debug print...');
          final debugOkAuto = await _printerService.debugForcePrint(
            printer,
            receipt,
          );
          final dlAuto = _printerService.getRecentPrinterLogs(count: 50);
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctxAuto) => AlertDialog(
              title: Text(
                debugOkAuto
                    ? 'Auto Debug Print Succeeded'
                    : 'Auto Debug Print Failed',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: SelectableText(dlAuto.join('\n')),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctxAuto),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Recent Printer Logs'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  '${pluginMsg ?? ''}${pluginMsg != null && pluginMsg.isNotEmpty ? '\n\n' : ''}${logs.isEmpty ? 'No logs available' : logs.join('\n')}',
                ),
              ),
            ),
            actions: [
              if (diag.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Open the edit dialog for the printer
                    _editPrinter(printer);
                  },
                  child: const Text('Edit Printer Details'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  // Copy logs to clipboard
                  Navigator.pop(context);
                  final txt = logs.isEmpty
                      ? 'No logs available'
                      : logs.join('\n');
                  await Clipboard.setData(ClipboardData(text: txt));
                  if (mounted) {
                    ToastHelper.showToast(context, 'Logs copied to clipboard');
                  }
                },
                child: const Text('Copy Logs'),
              ),
              if (testOk)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Show dialog offering to run a debug native print
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Test Print Succeeded'),
                        content: const Text(
                          'Test print succeeded but sample structured receipt failed. Would you like to run a native debug print attempt (bypasses validation) for additional diagnostics?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Run Debug Print'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final debugOk = await _printerService.debugForcePrint(
                        printer,
                        receipt,
                      );
                      final dl = _printerService.getRecentPrinterLogs(
                        count: 50,
                      );
                      if (!mounted) return;
                      await showDialog<void>(
                        context: context,
                        builder: (ctx2) => AlertDialog(
                          title: Text(
                            debugOk
                                ? 'Debug Print Succeeded'
                                : 'Debug Print Failed',
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: SelectableText(dl.join('\n')),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx2),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Run Debug Print'),
                ),
            ],
          ),
        );
        printer.status = PrinterStatus.error;
        await DatabaseService.instance.savePrinter(printer);
        await _loadPrinters();
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error sending sample receipt: $e');
    }
  }

  Future<void> _debugForcePrint(Printer printer) async {
    try {
      final now = DateTime.now();
      final receipt = {
        'businessName': 'ExtroPOS Debug Store',
        'address': '123 Debug Road\nTestville',
        'orderNumber': 'DBG',
        'dateTime': now.toIso8601String(),
        'items': [
          {
            'name': 'Debug Item',
            'quantity': 1,
            'price': 1.00,
            'total': 1.00,
            'modifiers': [],
          },
        ],
        'subtotal': 1.00,
        'tax': 0.00,
        'serviceCharge': 0.00,
        'total': 1.00,
        'paymentMethod': 'Cash',
        'amountPaid': 1.00,
        'change': 0.00,
        'currency': 'RM',
      };

      // Call the debug force print API
      final success = await _printerService.debugForcePrint(printer, receipt);
      if (!mounted) return;
      if (success) {
        ToastHelper.showToast(
          context,
          'Debug force print succeeded (platform path)',
        );
      } else {
        ToastHelper.showToast(
          context,
          'Debug force print failed — check printer logs',
        );
        final logs = _printerService.getRecentPrinterLogs(count: 50);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Printer Logs'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(logs.join('\n')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error invoking debug force print: $e');
    }
  }

  Future<void> _grantUsbPermission(Printer printer) async {
    // Show a blocking progress dialog while we wait for the native permission flow.
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        // Suppress deprecation warning for WillPopScope until PopScope adoption across the app.
        // ignore: deprecated_member_use
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: const [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Requesting USB permission...')),
              ],
            ),
          ),
        ),
      );

      // Add timeout to prevent hanging
      final ok = await _printerService
          .requestUsbPermission(printer)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('USB permission request timed out');
              return false;
            },
          );

      if (mounted) Navigator.of(context).pop(); // close progress dialog

      if (!mounted) return;
      ToastHelper.showToast(
        context,
        ok
            ? 'USB permission granted for ${printer.name}'
            : 'USB permission not granted or timed out',
      );

      // Refresh printer status after permission change
      if (ok) {
        await _loadPrinters();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error requesting USB permission: $e');
    }
  }

  Future<void> _grantBluetoothPermission(Printer printer) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: const [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Requesting Bluetooth permission...')),
              ],
            ),
          ),
        ),
      );

      final ok = await _printerService.requestBluetoothPermission(printer);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      ToastHelper.showToast(
        context,
        ok
            ? 'Bluetooth permission granted for ${printer.name}'
            : 'Bluetooth permission not granted',
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ToastHelper.showToast(
        context,
        'Error requesting Bluetooth permission: $e',
      );
    }
  }

  void _toggleDefault(Printer printer) async {
    try {
      // Update local state first
      setState(() {
        for (var p in printers) {
          if (p.type == printer.type && p.id != printer.id) p.isDefault = false;
        }
        printer.isDefault = !printer.isDefault;
      });

      // Save the changes to database
      await DatabaseService.instance.savePrinter(printer);

      // Also save the other printers that had their default status changed
      for (var p in printers) {
        if (p.type == printer.type &&
            p.id != printer.id &&
            p.isDefault !=
                (await DatabaseService.instance.getPrinterById(
                  p.id,
                ))?.isDefault) {
          await DatabaseService.instance.savePrinter(p);
        }
      }

      if (mounted) {
        ToastHelper.showToast(
          context,
          printer.isDefault
              ? '${printer.name} set as default'
              : '${printer.name} removed as default',
        );
      }
    } catch (e) {
      // Revert the local state on error
      setState(() {
        for (var p in printers) {
          if (p.type == printer.type && p.id != printer.id) {
            p.isDefault = !p.isDefault;
          }
        }
        printer.isDefault = !printer.isDefault;
      });

      if (mounted) {
        ToastHelper.showToast(context, 'Failed to update default printer: $e');
      }
    }
  }

  Widget _buildPrinterCard(Printer printer) {
    return Card(
      key: ValueKey(printer.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: printer.status == PrinterStatus.online
                ? Colors.green.withAlpha(26)
                : printer.status == PrinterStatus.offline
                ? Colors.grey.withAlpha(26)
                : Colors.red.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.print,
            color: printer.status == PrinterStatus.online
                ? Colors.green
                : printer.status == PrinterStatus.offline
                ? Colors.grey
                : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                printer.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (printer.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(printer.typeDisplayName),
            if (printer.connectionType == PrinterConnectionType.network)
              Text('${printer.ipAddress}:${printer.port}'),
            if (printer.modelName != null) Text(printer.modelName!),
            Row(
              children: [
                Text(
                  'Status: ${printer.statusDisplayName}',
                  style: TextStyle(
                    color: printer.status == PrinterStatus.online
                        ? Colors.green
                        : printer.status == PrinterStatus.offline
                        ? Colors.grey
                        : Colors.red,
                    fontSize: 12,
                  ),
                ),
                if (printer.connectionType == PrinterConnectionType.usb ||
                    printer.connectionType ==
                        PrinterConnectionType.bluetooth) ...[
                  const SizedBox(width: 8),
                  Text(
                    printer.hasPermission
                        ? '✓ Permission granted'
                        : '⚠ No permission',
                    style: TextStyle(
                      color: printer.hasPermission
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editPrinter(printer);
                break;
              case 'test':
                _testPrint(printer);
                break;
              case 'grant':
                _grantUsbPermission(printer);
                break;
              case 'grant_bt':
                _grantBluetoothPermission(printer);
                break;
              case 'sample':
                _sampleReceiptPrint(printer);
                break;
              case 'default':
                _toggleDefault(printer);
                break;
              case 'delete':
                _deletePrinter(printer);
                break;
              case 'force_debug':
                _debugForcePrint(printer);
                break;
            }
          },
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'test',
              child: Row(
                children: [
                  Icon(Icons.print, size: 20),
                  SizedBox(width: 8),
                  Text('Test Print'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sample',
              child: Row(
                children: [
                  Icon(Icons.receipt_long, size: 20),
                  SizedBox(width: 8),
                  Text('Sample Receipt'),
                ],
              ),
            ),
            if (printer.connectionType == PrinterConnectionType.usb)
              const PopupMenuItem(
                value: 'grant',
                child: Row(
                  children: [
                    Icon(Icons.usb, size: 20),
                    SizedBox(width: 8),
                    Text('Grant USB Permission'),
                  ],
                ),
              ),
            if (printer.connectionType == PrinterConnectionType.bluetooth)
              const PopupMenuItem(
                value: 'grant_bt',
                child: Row(
                  children: [
                    Icon(Icons.bluetooth, size: 20),
                    SizedBox(width: 8),
                    Text('Grant Bluetooth Permission'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'default',
              child: Row(
                children: [
                  Icon(Icons.star, size: 20),
                  SizedBox(width: 8),
                  Text('Toggle Default'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            if (kDebugMode) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'force_debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 20, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Force Debug Print',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading printers...'),
                ],
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLeftPanel(isNarrow: true),
                            Expanded(child: _buildRightPanel()),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLeftPanel(isNarrow: false),
                          Expanded(child: _buildRightPanel()),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Printer? get _selectedPrinter {
    if (_selectedPrinterId == null) {
      return printers.isNotEmpty ? printers.first : null;
    }
    try {
      return printers.firstWhere((p) => p.id == _selectedPrinterId);
    } catch (_) {
      return printers.isNotEmpty ? printers.first : null;
    }
  }

  Future<void> _handleTestPrint() async {
    final printer = _selectedPrinter;
    if (printer == null || _isTesting) return;
    setState(() => _isTesting = true);
    await _sampleReceiptPrint(printer);
    if (mounted) setState(() => _isTesting = false);
  }

  void _updateSelectedPrinter(Printer updated) {
    setState(() {
      final index = printers.indexWhere((p) => p.id == updated.id);
      if (index == -1) return;
      printers[index] = updated;
      _selectedPrinterId = updated.id;
    });
  }

  void _updatePrinterField({
    String? name,
    PrinterConnectionType? connectionType,
    String? address,
    int? port,
    ThermalPaperSize? paperSize,
    PrinterType? type,
    List<String>? categories,
  }) {
    final printer = _selectedPrinter;
    if (printer == null) return;

    String? ipAddress = printer.ipAddress;
    String? usbDeviceId = printer.usbDeviceId;
    String? bluetoothAddress = printer.bluetoothAddress;
    String? platformSpecificId = printer.platformSpecificId;

    final nextConnection = connectionType ?? printer.connectionType;
    if (address != null) {
      switch (nextConnection) {
        case PrinterConnectionType.network:
          ipAddress = address;
          break;
        case PrinterConnectionType.usb:
          usbDeviceId = address;
          break;
        case PrinterConnectionType.bluetooth:
          bluetoothAddress = address;
          break;
        case PrinterConnectionType.posmac:
          platformSpecificId = address;
          break;
      }
    }

    final updated = printer.copyWith(
      name: name,
      connectionType: nextConnection,
      ipAddress: ipAddress,
      usbDeviceId: usbDeviceId,
      bluetoothAddress: bluetoothAddress,
      platformSpecificId: platformSpecificId,
      port: port,
      paperSize: paperSize,
      type: type,
      categories: categories,
    );

    _updateSelectedPrinter(updated);
  }

  String _connectionAddress(Printer printer) {
    switch (printer.connectionType) {
      case PrinterConnectionType.network:
        return printer.ipAddress ?? '';
      case PrinterConnectionType.usb:
        return printer.usbDeviceId ?? '';
      case PrinterConnectionType.bluetooth:
        return printer.bluetoothAddress ?? '';
      case PrinterConnectionType.posmac:
        return printer.platformSpecificId ?? '';
    }
  }

  IconData _connectionIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return Icons.wifi;
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.usb:
        return Icons.usb;
      case PrinterConnectionType.posmac:
        return Icons.print;
    }
  }

  Color _statusBadgeColor(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.online:
        return const Color(0xFFD1FAE5);
      case PrinterStatus.offline:
        return const Color(0xFFFFE4E6);
      case PrinterStatus.error:
        return const Color(0xFFFFE4E6);
    }
  }

  Color _statusTextColor(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.online:
        return const Color(0xFF047857);
      case PrinterStatus.offline:
        return const Color(0xFFBE123C);
      case PrinterStatus.error:
        return const Color(0xFFBE123C);
    }
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Printer Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Configure receipt and kitchen printers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Search Bluetooth Printers',
                icon: const Icon(Icons.bluetooth_searching),
                onPressed: _isLoading ? null : _searchBluetoothPrinters,
              ),
              IconButton(
                tooltip: 'Search USB Printers',
                icon: const Icon(Icons.usb),
                onPressed: _isLoading ? null : _searchUsbPrinters,
              ),
              IconButton(
                tooltip: 'Discover Printers',
                icon: const Icon(Icons.search),
                onPressed: _isLoading ? null : _discoverPrintersAsync,
              ),
              IconButton(
                tooltip: 'Refresh All Printers',
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _loadPrinters,
              ),
              IconButton(
                tooltip: 'Print via ESCPrint Service',
                icon: const Icon(Icons.outgoing_mail),
                onPressed: _isLoading ? null : _printViaExternalServiceTest,
              ),
              IconButton(
                tooltip: 'Open debug console',
                icon: const Icon(Icons.bug_report),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrinterDebugConsole(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addPrinter,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Printer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLeftPanel({required bool isNarrow}) {
    final filteredPrinters = printers.where((printer) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return printer.name.toLowerCase().contains(query) ||
          printer.connectionTypeDisplayName.toLowerCase().contains(query);
    }).toList();

    return Container(
      width: isNarrow ? double.infinity : 400,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: isNarrow
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade200),
          bottom: isNarrow
              ? BorderSide(color: Colors.grey.shade200)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search printers...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4F46E5), width: 2),
                ),
              ),
            ),
          ),
          if (filteredPrinters.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.print_disabled,
                      size: 56,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('No printers configured'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addPrinter,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Printer'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                itemCount: filteredPrinters.length,
                itemBuilder: (context, index) {
                  final printer = filteredPrinters[index];
                  final isSelected = _selectedPrinterId == printer.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedPrinterId = printer.id),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEEF2FF)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : Colors.grey.shade100,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF4F46E5)
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Icon(
                                    Icons.print,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        printer.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? const Color(0xFF312E81)
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            _connectionIcon(
                                              printer.connectionType,
                                            ),
                                            size: 12,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            printer.connectionType
                                                .name
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF94A3B8),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (printer.type == PrinterType.receipt)
                                      _buildRoleDot(Colors.blue),
                                    if (printer.type == PrinterType.kitchen)
                                      _buildRoleDot(Colors.orange),
                                    if (printer.type == PrinterType.bar)
                                      _buildRoleDot(Colors.purple),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBadgeColor(printer.status),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        printer.status == PrinterStatus.online
                                            ? Icons.check_circle
                                            : Icons.error_outline,
                                        size: 12,
                                        color:
                                            _statusTextColor(printer.status),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        printer.statusDisplayName
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: _statusTextColor(printer.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildRoleDot(Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildRightPanel() {
    final selectedPrinter = _selectedPrinter;
    if (selectedPrinter == null) {
      return const Center(child: Text('Select a printer to configure.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPrinter.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Device ID: ${selectedPrinter.id.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: (_isTesting ||
                            selectedPrinter.status == PrinterStatus.offline)
                        ? null
                        : _handleTestPrint,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print, size: 18),
                    label: Text(_isTesting ? 'Printing...' : 'Test Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Connection Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRINTER NAME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: ValueKey('${selectedPrinter.id}_name'),
                                initialValue: selectedPrinter.name,
                                onChanged: (value) =>
                                    _updatePrinterField(name: value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                decoration: _inputDecoration(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PAPER SIZE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildToggleBtn(
                                        '80mm',
                                        '80mm',
                                        selectedPrinter.paperSize !=
                                            ThermalPaperSize.mm58,
                                        (value) => _updatePrinterField(
                                          paperSize: ThermalPaperSize.mm80,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildToggleBtn(
                                        '58mm',
                                        '58mm',
                                        selectedPrinter.paperSize ==
                                            ThermalPaperSize.mm58,
                                        (value) => _updatePrinterField(
                                          paperSize: ThermalPaperSize.mm58,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'CONNECTION TYPE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'network',
                            'Network / LAN',
                            Icons.wifi,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.network,
                            () => _updatePrinterField(
                              connectionType: PrinterConnectionType.network,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'bluetooth',
                            'Bluetooth',
                            Icons.bluetooth,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.bluetooth,
                            () => _updatePrinterField(
                              connectionType:
                                  PrinterConnectionType.bluetooth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'usb',
                            'USB Direct',
                            Icons.usb,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.usb,
                            () => _updatePrinterField(
                              connectionType: PrinterConnectionType.usb,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'posmac',
                            'POSMAC',
                            Icons.print,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.posmac,
                            () => _updatePrinterField(
                              connectionType: PrinterConnectionType.posmac,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      selectedPrinter.connectionType ==
                              PrinterConnectionType.network
                          ? 'IP ADDRESS'
                          : selectedPrinter.connectionType ==
                                  PrinterConnectionType.bluetooth
                              ? 'MAC ADDRESS'
                              : selectedPrinter.connectionType ==
                                      PrinterConnectionType.posmac
                                  ? 'DEVICE ID'
                                  : 'USB PORT',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey('${selectedPrinter.id}_addr'),
                      initialValue: _connectionAddress(selectedPrinter),
                      onChanged: (value) =>
                          _updatePrinterField(address: value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                      decoration: _inputDecoration(),
                    ),
                    if (selectedPrinter.connectionType ==
                        PrinterConnectionType.network) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'PORT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey('${selectedPrinter.id}_port'),
                        initialValue:
                            (selectedPrinter.port ?? 9100).toString(),
                        onChanged: (value) => _updatePrinterField(
                          port: int.tryParse(value) ?? 9100,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                        decoration: _inputDecoration(),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Print Assignments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildJobToggle(
                      title: 'Customer Receipts',
                      description:
                          'Print final bills and customer receipts upon payment.',
                      icon: Icons.receipt_long,
                      isActive: selectedPrinter.type == PrinterType.receipt,
                      onToggle: () => _updatePrinterField(
                        type: PrinterType.receipt,
                        categories: const [],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildJobToggle(
                      title: 'Kitchen Order Tickets (KOT)',
                      description:
                          'Send food and beverage orders directly to the kitchen.',
                      icon: Icons.restaurant_menu,
                      isActive: selectedPrinter.type == PrinterType.kitchen,
                      onToggle: () => _updatePrinterField(
                        type: PrinterType.kitchen,
                      ),
                      expandedContent:
                          selectedPrinter.type == PrinterType.kitchen
                              ? _buildKitchenCategories(selectedPrinter)
                              : null,
                    ),
                    const SizedBox(height: 16),
                    _buildJobToggle(
                      title: 'Bar Tickets',
                      description:
                          'Print beverage orders to the bar station printer.',
                      icon: Icons.local_bar,
                      isActive: selectedPrinter.type == PrinterType.bar,
                      onToggle: () => _updatePrinterField(
                        type: PrinterType.bar,
                      ),
                      expandedContent: selectedPrinter.type == PrinterType.bar
                          ? _buildKitchenCategories(selectedPrinter)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _deletePrinter(selectedPrinter),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove Printer'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF43F5E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await DatabaseService.instance
                          .savePrinter(selectedPrinter);
                      if (!mounted) return;
                      ToastHelper.showToast(
                        context,
                        'Configuration saved for ${selectedPrinter.name}',
                      );
                      await _loadPrinters();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Configuration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
    );
  }

  Widget _buildToggleBtn(
    String id,
    String label,
    bool isActive,
    Function(String) onTap,
  ) {
    return InkWell(
      onTap: () => onTap(id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? const Color(0xFF4F46E5)
                  : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelectBtn(
    String id,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF2FF) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF4F46E5) : Colors.grey.shade100,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color:
                  isActive ? const Color(0xFF4F46E5) : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isActive
                    ? const Color(0xFF4F46E5)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobToggle({
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
    required VoidCallback onToggle,
    Widget? expandedContent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEEF2FF).withOpacity(0.5) : Colors.white,
        border: Border.all(
          color: isActive ? const Color(0xFF4F46E5) : Colors.grey.shade100,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE0E7FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isActive
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isActive ? const Color(0xFF4F46E5) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment:
                          isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expandedContent != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: expandedContent,
            )
        ],
      ),
    );
  }

  Widget _buildKitchenCategories(Printer printer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: const Color(0xFFE0E7FF).withOpacity(0.6),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        const Text(
          'ASSIGNED CATEGORIES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF818CF8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_availableCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No categories found. Create categories in Settings.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCategories.map<Widget>((cat) {
              final isActive = printer.categories.contains(cat.id);
              return InkWell(
                onTap: () {
                  final nextCategories = List<String>.from(printer.categories);
                  if (isActive) {
                    nextCategories.remove(cat.id);
                  } else {
                    nextCategories.add(cat.id);
                  }
                  _updatePrinterField(categories: nextCategories);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF4F46E5) : Colors.white,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (_availableCategories.isNotEmpty && printer.categories.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              'Select at least one category to print.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF43F5E),
              ),
            ),
          )
      ],
    );
  }
}

class _PrinterFormDialog extends StatefulWidget {
  final Printer? printer;
  final Function(Printer) onSave;

  const _PrinterFormDialog({this.printer, required this.onSave});

  @override
  State<_PrinterFormDialog> createState() => _PrinterFormDialogState();
}

class _PrinterFormDialogState extends State<_PrinterFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _usbDeviceIdController;
  late TextEditingController _bluetoothAddressController;
  late TextEditingController _modelController;
  late PrinterType _selectedType;
  late PrinterConnectionType _selectedConnectionType;
  ThermalPaperSize? _selectedPaperSize;
  final PrinterService _printerService = PrinterService();
  List<String> _selectedCategories = [];
  List<Map<String, dynamic>> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.printer?.name ?? '');
    _ipController = TextEditingController(
      text: widget.printer?.ipAddress ?? '192.168.1.',
    );
    _portController = TextEditingController(
      text: widget.printer?.port?.toString() ?? '9100',
    );
    _usbDeviceIdController = TextEditingController(
      text: widget.printer?.usbDeviceId ?? '',
    );
    _bluetoothAddressController = TextEditingController(
      text: widget.printer?.bluetoothAddress ?? '',
    );
    _modelController = TextEditingController(
      text: widget.printer?.modelName ?? '',
    );
    _selectedType = widget.printer?.type ?? PrinterType.receipt;
    _selectedConnectionType =
        widget.printer?.connectionType ?? PrinterConnectionType.network;
    _selectedPaperSize = widget.printer?.paperSize ?? ThermalPaperSize.mm80;
    _selectedCategories = List<String>.from(widget.printer?.categories ?? []);
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _usbDeviceIdController.dispose();
    _bluetoothAddressController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DatabaseService.instance.getCategories();
      if (mounted) {
        setState(() {
          _availableCategories = categories
              .map((c) => {'id': c.id, 'name': c.name})
              .toList();
        });
      }
    } catch (e) {
      // Ignore errors loading categories
    }
  }

  Future<void> _scanUsbDevices() async {
    try {
      // Enable printer logging to see what's happening
      await _printerService.setPrinterLogEnabled(true);

      final printers = await _printerService.discoverPrinters();
      final usbPrinters = printers
          .where((p) => p.connectionType == PrinterConnectionType.usb)
          .toList();

      if (!mounted) return;

      if (usbPrinters.isEmpty) {
        ToastHelper.showToast(
          context,
          'No USB printers found. Check Printer Debug Console for details.',
        );
        return;
      }

      // Show dialog to select from found USB devices
      final selected = await showDialog<Printer>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select USB Printer'),
          content: ConstrainedDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: usbPrinters.length,
                  itemBuilder: (context, index) {
                    final printer = usbPrinters[index];
                    return ListTile(
                      title: Text(printer.name),
                      subtitle: Text(
                        'Device ID: ${printer.usbDeviceId}\nModel: ${printer.modelName ?? 'Unknown'}',
                      ),
                      onTap: () => Navigator.pop(context, printer),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          _usbDeviceIdController.text = selected.usbDeviceId ?? '';
          _nameController.text = selected.name;
          if (selected.modelName != null) {
            _modelController.text = selected.modelName!;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error scanning USB devices: $e');
    }
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ToastHelper.showToast(context, 'Please enter a printer name');
      return;
    }

    // Validate connection-specific fields
    switch (_selectedConnectionType) {
      case PrinterConnectionType.network:
        if (_ipController.text.isEmpty) {
          ToastHelper.showToast(context, 'Please enter an IP address');
          return;
        }
        break;
      case PrinterConnectionType.usb:
        if (_usbDeviceIdController.text.isEmpty) {
          ToastHelper.showToast(context, 'Please enter a USB device ID');
          return;
        }
        break;
      case PrinterConnectionType.bluetooth:
        if (_bluetoothAddressController.text.isEmpty) {
          ToastHelper.showToast(context, 'Please enter a Bluetooth address');
          return;
        }
        break;
      case PrinterConnectionType.posmac:
        // POSMAC doesn't require additional validation for now
        break;
    }

    final Printer printer;
    switch (_selectedConnectionType) {
      case PrinterConnectionType.network:
        printer = Printer.network(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          ipAddress: _ipController.text,
          port: int.tryParse(_portController.text) ?? 9100,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
      case PrinterConnectionType.usb:
        printer = Printer.usb(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          usbDeviceId: _usbDeviceIdController.text,
          platformSpecificId: widget.printer?.platformSpecificId,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
      case PrinterConnectionType.bluetooth:
        printer = Printer.bluetooth(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          bluetoothAddress: _bluetoothAddressController.text,
          platformSpecificId: widget.printer?.platformSpecificId,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
      case PrinterConnectionType.posmac:
        printer = Printer.posmac(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          platformSpecificId: widget.printer?.platformSpecificId ?? '',
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
    }

    widget.onSave(printer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.printer == null ? 'Add Printer' : 'Edit Printer'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrinterType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Printer Type *',
                  border: OutlineInputBorder(),
                ),
                items: PrinterType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              // Show category selection for Kitchen and Bar printers
              if (_selectedType == PrinterType.kitchen ||
                  _selectedType == PrinterType.bar) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Categories to Print',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select which product categories should print to this ${_selectedType.name} printer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_availableCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No categories found. Create categories in Settings.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((cat) {
                            final isSelected = _selectedCategories.contains(
                              cat['id'],
                            );
                            return FilterChip(
                              label: Text(cat['name']),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(cat['id']);
                                  } else {
                                    _selectedCategories.remove(cat['id']);
                                  }
                                });
                              },
                              selectedColor: const Color(
                                0xFF2563EB,
                              ).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF2563EB),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<PrinterConnectionType>(
                initialValue: _selectedConnectionType,
                decoration: const InputDecoration(
                  labelText: 'Connection Type *',
                  border: OutlineInputBorder(),
                ),
                items: PrinterConnectionType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedConnectionType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Connection-specific fields
              if (_selectedConnectionType == PrinterConnectionType.network) ...[
                ResponsiveRow(
                  breakpoint: 560,
                  rowChildren: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'IP Address *',
                          border: OutlineInputBorder(),
                          hintText: '192.168.1.100',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(),
                          hintText: '9100',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                  columnChildren: [
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP Address *',
                        border: OutlineInputBorder(),
                        hintText: '192.168.1.100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                        hintText: '9100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ] else if (_selectedConnectionType ==
                  PrinterConnectionType.usb) ...[
                ResponsiveRow(
                  breakpoint: 520,
                  rowChildren: [
                    Expanded(
                      child: TextField(
                        controller: _usbDeviceIdController,
                        decoration: const InputDecoration(
                          labelText: 'USB Device ID *',
                          border: OutlineInputBorder(),
                          hintText: 'VID:PID or device path',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _scanUsbDevices,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                  columnChildren: [
                    TextField(
                      controller: _usbDeviceIdController,
                      decoration: const InputDecoration(
                        labelText: 'USB Device ID *',
                        border: OutlineInputBorder(),
                        hintText: 'VID:PID or device path',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _scanUsbDevices,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedConnectionType ==
                  PrinterConnectionType.bluetooth) ...[
                TextField(
                  controller: _bluetoothAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Bluetooth Address *',
                    border: OutlineInputBorder(),
                    hintText: 'AA:BB:CC:DD:EE:FF',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model Name',
                  border: OutlineInputBorder(),
                  hintText: 'Epson TM-T88VI',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ThermalPaperSize>(
                initialValue: _selectedPaperSize,
                decoration: const InputDecoration(
                  labelText: 'Paper Size',
                  border: OutlineInputBorder(),
                ),
                items: ThermalPaperSize.values
                    .map(
                      (ps) => DropdownMenuItem(
                        value: ps,
                        child: Text(
                          ps == ThermalPaperSize.mm58 ? '58 mm' : '80 mm',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaperSize = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
