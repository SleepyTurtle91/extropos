import 'dart:async';

import 'package:collection/collection.dart';
import 'package:extropos/dialogs/printer_form_dialog.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_business_logic_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'printers_management_screen_dialogs.dart';
part 'printers_management_screen_discovery.dart';
part 'printers_management_screen_operations.dart';
part 'printers_management_screen_print.dart';
part 'printers_management_screen_ui.dart';
part 'printers_management_screen_widgets.dart';

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
      builder: (ctx) => PrinterFormDialog(
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
  late PrinterBusinessLogicService _printerLogic;
  bool _isLoading = true;
  bool _isInitialized = false;
  final String _searchQuery = '';
  String? _selectedPrinterId;
  bool _isTesting = false;
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    _printerLogic = PrinterBusinessLogicService(PrinterService());
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
      await _printerLogic.initializePrinterService();
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
        builder: (ctx) => PrinterFormDialog(
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



  Future<void> _printViaExternalServiceTest() async {
    final now = DateTime.now();
    final receipt = {
      'title': 'TEST PRINT',
      'content':
          'This is a test receipt from FlutterPOS.\n\nItems:\nSample Item x 1 RM 1.00\n\nSubtotal: RM 1.00\nTotal: RM 1.00',
      'timestamp': now.toString(),
    };
    try {
      final ok = await _printerLogic.printViaExternalService(
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
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error: $e');
      }
    }
  }

  Future<void> _loadPrinters() async {
    try {
      final savedPrinters = await PrinterBusinessLogicService.loadPrinters();
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
      final categories = await PrinterBusinessLogicService.loadCategories();
      if (!mounted) return;
      setState(() => _availableCategories = categories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _availableCategories = []);
    }
  }

  Future<bool> _isIMinDevice() async {
    return await PrinterBusinessLogicService.isIMinDevice();
  }



  Future<void> _testPrint(Printer printer) async {
    try {
      final success = await _printerLogic.testPrint(printer);
      if (!mounted) return;
      await _loadPrinters();
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



  Future<void> _grantUsbPermission(Printer printer) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        // ignore: deprecated_member_use
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: Row(
              children: [
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

      final ok = await _printerLogic.requestUsbPermission(printer);
      if (mounted) Navigator.of(context).pop();
      
      if (!mounted) return;
      ToastHelper.showToast(
        context,
        ok
            ? 'USB permission granted for ${printer.name}'
            : 'USB permission not granted or timed out',
      );

      if (ok) await _loadPrinters();
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
          child: const AlertDialog(
            content: Row(
              children: [
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

      final ok = await _printerLogic.requestBluetoothPermission(printer);
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
      final updated = await PrinterBusinessLogicService.toggleDefault(
        printer,
        printers,
      );
      if (updated != null) {
        setState(() {
          final index = printers.indexWhere((p) => p.id == updated.id);
          if (index != -1) printers[index] = updated;
        });
        if (mounted) {
          ToastHelper.showToast(
            context,
            updated.isDefault
                ? '${updated.name} set as default'
                : '${updated.name} removed as default',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to update default printer: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) => throw UnimplementedError('Use PrintersManagementScreenUI extension');

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
}
