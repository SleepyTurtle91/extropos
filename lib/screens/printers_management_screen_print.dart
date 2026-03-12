part of 'printers_management_screen.dart';

// Printer test and debug print operations
extension _PrintersPrintOperations on _PrintersManagementScreenState {
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
}
