import 'dart:async';

import 'package:extropos/models/business_info_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_io/io.dart' show Platform;

class ThermalPrinterIntegrationScreen extends StatelessWidget {
  const ThermalPrinterIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Printer Integration'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Thermal'),
              Tab(text: 'PDF'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ThermalPrinterTab(),
            _StandardPdfPrinterTab(),
          ],
        ),
      ),
    );
  }
}

class _ThermalPrinterTab extends StatefulWidget {
  const _ThermalPrinterTab();

  @override
  State<_ThermalPrinterTab> createState() => _ThermalPrinterTabState();
}

class _ThermalPrinterTabState extends State<_ThermalPrinterTab> {
  final PrinterManager _printerManager = PrinterManager.instance;
  final List<PrinterDevice> _devices = [];
  PrinterDevice? _selectedPrinter;
  PrinterType _currentPrinterType = PrinterType.bluetooth;
  StreamSubscription<PrinterDevice>? _subscription;
  bool _isScanning = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _scanPrinters();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  bool get _supportedPlatform => !kIsWeb && Platform.isAndroid;

  void _scanPrinters() {
    if (!_supportedPlatform) return;

    setState(() {
      _devices.clear();
      _selectedPrinter = null;
      _isScanning = true;
      _status = 'Scanning...';
    });

    _subscription?.cancel();
    _subscription = _printerManager
        .discovery(type: _currentPrinterType, isBle: false)
        .listen((device) {
      if (_devices.any((d) => d.address == device.address)) return;
      setState(() {
        _devices.add(device);
      });
    }, onError: (e) {
      setState(() => _status = 'Scan failed: $e');
    }, onDone: () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _status = null;
        });
      }
    });
  }

  void _stopScan() {
    _subscription?.cancel();
    _subscription = null;
    if (mounted) {
      setState(() {
        _isScanning = false;
        _status = null;
      });
    }
  }

  Future<List<int>> _generateReceiptBytes() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final businessInfo = BusinessInfo.instance;

    final bytes = <int>[];
    bytes.addAll(
      generator.text(
        businessInfo.businessName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        businessInfo.address,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(1));

    bytes.addAll(
      generator.row(
        [
          PosColumn(text: 'Item 1', width: 8),
          PosColumn(
            text: '${businessInfo.currencySymbol}15.00',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ],
      ),
    );
    bytes.addAll(
      generator.row(
        [
          PosColumn(text: 'Item 2', width: 8),
          PosColumn(
            text: '${businessInfo.currencySymbol}5.00',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ],
      ),
    );

    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.row(
        [
          PosColumn(
            text: 'TOTAL',
            width: 8,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: '${businessInfo.currencySymbol}20.00',
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ],
      ),
    );

    bytes.addAll(generator.feed(2));
    bytes.addAll(
      generator.text(
        'Thank you!',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return bytes;
  }

  Future<void> _printTicket() async {
    if (!_supportedPlatform) return;
    if (_selectedPrinter == null) return;

    try {
      if (_currentPrinterType == PrinterType.bluetooth) {
        await _printerManager.connect(
          type: PrinterType.bluetooth,
          model: BluetoothPrinterInput(
            name: _selectedPrinter!.name,
            address: _selectedPrinter!.address!,
            isBle: false,
          ),
        );
      } else if (_currentPrinterType == PrinterType.usb) {
        await _printerManager.connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
            name: _selectedPrinter!.name,
          ),
        );
      }

      final bytes = await _generateReceiptBytes();
      _printerManager.send(type: _currentPrinterType, bytes: bytes);

      await Future.delayed(const Duration(seconds: 2));
      await _printerManager.disconnect(type: _currentPrinterType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print job sent successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printing failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportedPlatform) {
      return const Center(
        child: Text('Thermal printing is supported on Android devices only.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Connection Type:'),
              const SizedBox(width: 12),
              DropdownButton<PrinterType>(
                value: _currentPrinterType,
                items: const [
                  DropdownMenuItem(
                    value: PrinterType.bluetooth,
                    child: Text('Bluetooth'),
                  ),
                  DropdownMenuItem(
                    value: PrinterType.usb,
                    child: Text('USB (OTG)'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _currentPrinterType = value);
                  _scanPrinters();
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: _isScanning ? _stopScan : _scanPrinters,
                child: Text(_isScanning ? 'Stop' : 'Scan'),
              ),
            ],
          ),
        ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(_status!, style: const TextStyle(color: Colors.grey)),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _devices.isEmpty
              ? const Center(
                  child: Text('No devices found. Enable Bluetooth or USB OTG.'),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isSelected =
                        _selectedPrinter?.address == device.address;
                    return ListTile(
                      leading: Icon(
                        _currentPrinterType == PrinterType.usb
                            ? Icons.usb
                            : Icons.bluetooth,
                      ),
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.address ?? ''),
                      onTap: () => setState(() => _selectedPrinter = device),
                      trailing:
                          isSelected ? const Icon(Icons.check) : const SizedBox(),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _selectedPrinter == null ? null : _printTicket,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Print Test Receipt'),
          ),
        ),
      ],
    );
  }
}

class _StandardPdfPrinterTab extends StatelessWidget {
  const _StandardPdfPrinterTab();

  Future<pw.Document> _generatePdf() async {
    final businessInfo = BusinessInfo.instance;
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice #12345',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Date: ${now.toLocal()}'),
              pw.SizedBox(height: 24),
              pw.TableHelper.fromTextArray(
                data: <List<String>>[
                  <String>['Item', 'Qty', 'Price', 'Total'],
                  <String>[
                    'Flutter Consulting',
                    '10',
                    '${businessInfo.currencySymbol}100.00',
                    '${businessInfo.currencySymbol}1000.00',
                  ],
                  <String>[
                    'App UI Design',
                    '5',
                    '${businessInfo.currencySymbol}50.00',
                    '${businessInfo.currencySymbol}250.00',
                  ],
                ],
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Grand Total: ${businessInfo.currencySymbol}1250.00',
                  style: const pw.TextStyle(fontSize: 18),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _printDocument() async {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Invoice_12345',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.print),
        label: const Text('Print A4 Invoice'),
        onPressed: _printDocument,
      ),
    );
  }
}
