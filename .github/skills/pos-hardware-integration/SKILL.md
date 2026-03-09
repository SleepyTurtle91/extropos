---
name: pos-hardware-integration
description: Integrate POS hardware devices including thermal printers (58mm/80mm), barcode scanners, and payment terminals. Handle device discovery, connection, receipt printing, and graceful error recovery.
license: Proprietary
compatibility: Flutter 3.0+, Dart 3.0+. Requires blue_thermal_printer, barcode_scan, or stripe_terminal packages. Android Bluetooth/USB permissions.
metadata:
  author: FlutterPOS
  version: "1.0"
  domain: flutter-dart
  focus: hardware
---

# POS Hardware & Device Integration

**When to use this skill**: Printer integration, receipt printing, barcode scanning, payment device setup, hardware error handling, device discovery.

## Thermal Printer Integration

Service pattern for 58mm and 80mm printers:

```dart
class ThermalPrinterService {
  static final instance = ThermalPrinterService._();
  
  late BlueThermalPrinter _printer;
  bool _isConnected = false;
  
  // Discover available printers
  Future<List<BluetoothDevice>> discoverPrinters() async {
    try {
      final devices = await _printer.pairedDevices;
      return devices.toList();
    } catch (e) {
      throw PrinterException('Discovery failed: $e');
    }
  }
  
  // Connect to printer
  Future<void> connectPrinter(BluetoothDevice device) async {
    try {
      await _printer.connect(device);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      throw PrinterException('Connection failed: $e');
    }
  }
  
  // Print receipt
  Future<void> printReceipt(Receipt receipt) async {
    if (!_isConnected) {
      throw PrinterException('Printer not connected');
    }
    
    try {
      _printer.printNewLine();
      _printer.printText(receipt.businessName, align: 1, size: 1);
      _printer.printDashedLine();
      
      for (final item in receipt.items) {
        _printer.printText('${item.product.name} x${item.quantity}');
      }
      
      _printer.printDashedLine();
      _printer.printText(
        'TOTAL: RM${receipt.total.toStringAsFixed(2)}',
        align: 2,
        size: 1,
      );
      
      _printer.printNewLine();
      await _printer.cut();
      
    } catch (e) {
      throw PrinterException('Print failed: $e');
    }
  }
  
  Future<void> disconnect() async {
    await _printer.disconnect();
    _isConnected = false;
  }
  
  bool get isConnected => _isConnected;
}
```

## Receipt Formatting

Format receipts for 58mm (32 chars) or 80mm (48 chars):

```dart
class ReceiptFormatterService {
  static const int WIDTH_58MM = 32;
  static const int WIDTH_80MM = 48;
  
  static String formatReceipt(Receipt receipt, int width) {
    final buffer = StringBuffer();
    
    buffer.writeln(_centerText(receipt.businessName, width));
    buffer.writeln(_repeatChar('-', width));
    
    for (final item in receipt.items) {
      buffer.writeln(_formatItem(item, receipt.currencySymbol, width));
    }
    
    buffer.writeln(_repeatChar('=', width));
    buffer.writeln(_formatTotal(
      'TOTAL',
      receipt.total,
      receipt.currencySymbol,
      width,
      isFinal: true,
    ));
    
    return buffer.toString();
  }
  
  static String _centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text + ' ' * (width - text.length - padding);
  }
  
  static String _repeatChar(String char, int count) {
    return char * count;
  }
}
```

## Barcode Scanner Integration

Continuous scanning pattern:

```dart
class BarcodeScannerService {
  static final instance = BarcodeScannerService._();
  
  final _scanController = StreamController<String>();
  Stream<String> get onBarcodeScanned => _scanController.stream;
  
  void startContinuousScanning() {
    // Enable keyboard emulation for scanner input
    // Or hook into scanner hardware directly
  }
  
  void stopContinuousScanning() {
    // Stop listening
  }
  
  void dispose() {
    _scanController.close();
  }
}

// Usage in POS screen
@override
void initState() {
  super.initState();
  _barcodeSubscription = BarcodeScannerService.instance.onBarcodeScanned
    .listen(_handleBarcodeScanned);
}

void _handleBarcodeScanned(String barcode) {
  final product = _products.firstWhereOrNull((p) => p.barcode == barcode);
  
  if (product != null) {
    setState(() {
      final existing = _cartItems.firstWhereOrNull(
        (item) => item.product.id == product.id,
      );
      
      if (existing != null) {
        existing.quantity++;
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }
}

@override
void dispose() {
  _barcodeSubscription.cancel();
  super.dispose();
}
```

## Payment Terminal Integration

Example with Stripe Terminal:

```dart
class PaymentTerminalService {
  static final instance = PaymentTerminalService._();
  
  late StripeTerminal _terminal;
  
  Future<void> initialize() async {
    _terminal = StripeTerminal.instance;
    await _terminal.initialize();
  }
  
  Future<List<Reader>> discoverReaders() async {
    try {
      return await _terminal.discoverReaders(isSimulated: false);
    } catch (e) {
      throw PaymentException('Discovery failed: $e');
    }
  }
  
  Future<PaymentResult> processCardPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      final intent = await _terminal.createPaymentIntent(
        amount: (amount * 100).toInt(),
        currency: currency,
      );
      
      final payment = await _terminal.collectPaymentMethod(intent);
      final result = await _terminal.processPayment(payment);
      
      return PaymentResult(
        success: true,
        method: PaymentMethod.card,
        amount: amount,
        transactionId: result.id,
      );
    } catch (e) {
      throw PaymentException('Payment failed: $e');
    }
  }
}
```

## Hardware Error Handling

```dart
class HardwareErrorHandler {
  static void handlePrinterError(PrinterException error) {
    print('PRINTER ERROR: ${error.message}');
    
    if (error.message.contains('not connected')) {
      _showReconnectDialog();
    } else if (error.message.contains('paper')) {
      _showAddPaperDialog();
    } else if (error.message.contains('offline')) {
      _showOfflineMessage();
    }
  }
  
  static void handlePaymentError(PaymentException error) {
    print('PAYMENT ERROR: ${error.message}');
    _logPaymentError(error);
    
    if (error.message.contains('declined')) {
      _showCardDeclinedMessage();
    } else if (error.message.contains('timeout')) {
      _showTimeoutMessage();
    }
  }
}
```

## Android Permissions

Required in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
```

## Testing Hardware Integration

```dart
testWidgets('connects to printer successfully', (tester) async {
  final device = BluetoothDevice(name: 'Printer', address: '00:00:00:00');
  final service = ThermalPrinterService();
  
  when(mockPrinter.connect(device)).thenAnswer((_) async {});
  
  await service.connectPrinter(device);
  
  expect(service.isConnected, isTrue);
});

test('throws exception when not connected', () {
  expect(
    () => service.printReceipt(receipt),
    throwsA(isA<PrinterException>()),
  );
});
```

## Supported Hardware

**Thermal Printers**:
- Xprinter XP-58
- Sunmi T2/T3
- Epson TM-T88
- Any ESC/POS compatible

**Barcode Scanners**:
- USB HID (keyboard emulation)
- Bluetooth LE scanners

**Payment Terminals**:
- Stripe Terminal
- Square Reader
- Any mPOS device

---

See [references/PRINTER_SETUP.md](references/PRINTER_SETUP.md) for setup guides.

See [references/DEVICE_TROUBLESHOOTING.md](references/DEVICE_TROUBLESHOOTING.md) for common issues.
