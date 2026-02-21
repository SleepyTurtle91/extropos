import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/screens/printer_debug_console.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/dialog_helpers.dart';
import 'package:extropos/widgets/responsive_row.dart';
import 'package:flutter/foundation.dart';
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
  final PrinterService _printerService = PrinterService();
  bool _isLoading = true;
  bool _isInitialized = false;

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(context, 'Error loading printers: $e');
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

            setState(() => printers.add(printer));
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
              setState(() => printers.removeWhere((p) => p.id == printer.id));
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
      appBar: AppBar(
        title: const Text('Printers Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
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
                MaterialPageRoute(builder: (_) => const PrinterDebugConsole()),
              );
            },
          ),
        ],
      ),
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
          : printers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.print_disabled,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No printers configured'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addPrinter,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Printer'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              key: const PageStorageKey('printers_list'),
              padding: const EdgeInsets.all(16),
              itemCount: printers.length,
              itemBuilder: (context, index) {
                final printer = printers[index];
                return _buildPrinterCard(printer);
              },
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addPrinter,
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.add),
              label: const Text('Add Printer'),
            ),
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
