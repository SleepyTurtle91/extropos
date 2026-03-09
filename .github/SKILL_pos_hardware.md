# POS Hardware & Device Integration Expertise

**Skill Domain**: Integrate printers, card readers, barcode scanners, and other POS hardware devices

**When to Invoke**: Printer integration, receipt printing, barcode scanning, payment device integration, thermal printer setup

---

## Core POS Hardware Areas

### 1. Thermal Printer Integration

**Supported Printers**: 
- 58mm thermal (receipt width: 48-56mm)
- 80mm thermal (receipt width: 75-79mm)

**Common Models**:
- Zebra: M4203, M4204, M4206
- Epson: TM-U220, TM-T82, TM-T88
- Sunmi: T2, T3
- Custom ESC/POS compatible

**Service Pattern**:

```dart
// lib/services/thermal_printer_service.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class ThermalPrinterService {
  static final instance = ThermalPrinterService._();
  
  late BlueThermalPrinter _bluetooth;
  bool _isConnected = false;
  
  ThermalPrinterService._() {
    _bluetooth = BlueThermalPrinter.instance;
  }
  
  // Printer Discovery
  Future<List<BluetoothDevice>> discoverPrinters() async {
    try {
      final devices = await _bluetooth.pairedDevices;
      return devices.toList();
    } catch (e) {
      throw PrinterException('Failed to discover printers: $e');
    }
  }
  
  // Connect to Printer
  Future<void> connectPrinter(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      throw PrinterException('Failed to connect: $e');
    }
  }
  
  // Print Receipt
  Future<void> printReceipt(Receipt receipt) async {
    if (!_isConnected) {
      throw PrinterException('Printer not connected');
    }
    
    try {
      // Set paper width (58mm or 80mm)
      await _bluetooth.printNewLine();
      
      // Header
      _bluetooth.printText(
        receipt.businessName,
        align: 1, // Center
        size: 1,
      );
      
      _bluetooth.printText(
        receipt.businessAddress,
        align: 1,
        size: 0,
      );
      
      _bluetooth.printDashedLine();
      
      // Items
      for (final item in receipt.items) {
        final total = (item.quantity * item.price).toStringAsFixed(2);
        _bluetooth.printText(
          '${item.product.name} x${item.quantity}',
          align: 0, // Left
        );
        _bluetooth.printText(
          '  ${receipt.currencySymbol}$total',
          align: 2, // Right
        );
      }
      
      _bluetooth.printDashedLine();
      
      // Totals
      _bluetooth.printText(
        'Subtotal: ${receipt.currencySymbol}${receipt.subtotal.toStringAsFixed(2)}',
        align: 2,
      );
      
      if (receipt.tax > 0) {
        _bluetooth.printText(
          'Tax: ${receipt.currencySymbol}${receipt.tax.toStringAsFixed(2)}',
          align: 2,
        );
      }
      
      _bluetooth.printText(
        'TOTAL: ${receipt.currencySymbol}${receipt.total.toStringAsFixed(2)}',
        align: 2,
        size: 1,
      );
      
      _bluetooth.printText(
        'Payment: ${receipt.payment.method.toString()}',
        align: 0,
      );
      
      if (receipt.change > 0) {
        _bluetooth.printText(
          'Change: ${receipt.currencySymbol}${receipt.change.toStringAsFixed(2)}',
          align: 2,
        );
      }
      
      // Footer
      _bluetooth.printNewLine();
      _bluetooth.printText(
        'Thank you!',
        align: 1,
        size: 1,
      );
      
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      
      // Cut paper
      await _bluetooth.cut();
      
    } catch (e) {
      throw PrinterException('Print failed: $e');
    }
  }
  
  // Disconnect
  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _isConnected = false;
  }
  
  bool get isConnected => _isConnected;
}
```

**Printer Dependencies**:
```yaml
# pubspec.yaml (Android)
dependencies:
  blue_thermal_printer: ^1.2.0
  # OR for USB printers
  usb_serial: ^0.2.3
```

**Permission Setup**:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

### 2. Receipt Formatting & Templates

**Service Pattern**:

```dart
// lib/services/receipt_formatter_service.dart
class ReceiptFormatterService {
  static const int WIDTH_58MM = 32; // Character width for 58mm
  static const int WIDTH_80MM = 48; // Character width for 80mm
  
  static String formatReceipt(Receipt receipt, int width) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln(_centerText(receipt.businessName, width));
    buffer.writeln(_centerText(receipt.businessAddress, width));
    buffer.writeln(_repeatChar('-', width));
    buffer.writeln();
    
    // Date/Time
    buffer.writeln(_rightAlignText(
      DateFormat('yyyy-MM-dd HH:mm').format(receipt.timestamp),
      width,
    ));
    buffer.writeln(_rightAlignText(
      'Receipt #${receipt.receiptNumber}',
      width,
    ));
    buffer.writeln();
    
    // Items header
    buffer.writeln(_formatItemHeader(width));
    buffer.writeln(_repeatChar('-', width));
    
    // Items
    for (final item in receipt.items) {
      buffer.writeln(_formatItem(item, receipt.currencySymbol, width));
    }
    
    buffer.writeln(_repeatChar('-', width));
    
    // Totals
    buffer.writeln(_formatTotal('Subtotal', receipt.subtotal, 
      receipt.currencySymbol, width));
    
    if (receipt.tax > 0) {
      buffer.writeln(_formatTotal('Tax (${(receipt.taxRate * 100).toStringAsFixed(0)}%)', 
        receipt.tax, receipt.currencySymbol, width));
    }
    
    if (receipt.serviceCharge > 0) {
      buffer.writeln(_formatTotal('Service', receipt.serviceCharge, 
        receipt.currencySymbol, width));
    }
    
    buffer.writeln(_repeatChar('=', width));
    buffer.writeln(_formatTotal('TOTAL', receipt.total, 
      receipt.currencySymbol, width, isFinal: true));
    buffer.writeln();
    
    // Payment info
    buffer.writeln(_leftAlignText('Payment Method:', width));
    buffer.writeln(_rightAlignText(receipt.payment.method.toString(), width));
    
    if (receipt.change > 0) {
      buffer.writeln(_formatTotal('Change', receipt.change, 
        receipt.currencySymbol, width));
    }
    
    buffer.writeln();
    buffer.writeln(_repeatChar('-', width));
    buffer.writeln(_centerText('THANK YOU FOR YOUR PURCHASE', width));
    buffer.writeln(_centerText(DateFormat('yyyy-MM-dd').format(DateTime.now()), width));
    
    return buffer.toString();
  }
  
  static String _centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text + ' ' * (width - text.length - padding);
  }
  
  static String _rightAlignText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return ' ' * (width - text.length) + text;
  }
  
  static String _leftAlignText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text + ' ' * (width - text.length);
  }
  
  static String _formatItem(CartItem item, String currency, int width) {
    final name = item.product.name;
    final qtyPrice = '${item.quantity}x ${currency}${item.price.toStringAsFixed(2)}';
    final total = (item.quantity * item.price).toStringAsFixed(2);
    
    final line1 = _leftAlignText(name, width);
    final totalText = '$currency$total';
    final line2 = _leftAlignText(
      '  ${item.quantity}x ${currency}${item.price.toStringAsFixed(2)}',
      width - totalText.length,
    ) + _rightAlignText(totalText, totalText.length);
    
    return '$line1\n$line2';
  }
  
  static String _formatItemHeader(int width) {
    return _leftAlignText('Item', width ~/ 2) + 
           _rightAlignText('Qty x Price', width ~/ 4) +
           _rightAlignText('Total', width ~/ 4);
  }
  
  static String _formatTotal(
    String label, 
    double amount, 
    String currency, 
    int width, {
    bool isFinal = false,
  }) {
    final amountText = '$currency${amount.toStringAsFixed(2)}';
    final labelText = isFinal ? label.toUpperCase() : label;
    
    if (isFinal) {
      final padding = width - labelText.length - amountText.length - 2;
      return '$labelText ${' ' * padding} $amountText';
    }
    
    return _leftAlignText(labelText, width - amountText.length) + 
           _rightAlignText(amountText, amountText.length);
  }
  
  static String _repeatChar(String char, int count) {
    return char * count;
  }
}
```

### 3. Barcode Scanner Integration

**Service Pattern**:

```dart
// lib/services/barcode_scanner_service.dart
class BarcodeScannerService {
  static final instance = BarcodeScannerService._();
  
  final _scanController = StreamController<String>();
  Stream<String> get onBarcodeScanned => _scanController.stream;
  
  BarcodeScannerService._() {
    _initializeScanner();
  }
  
  Future<void> _initializeScanner() async {
    // Initialize scanner hardware
    // Different implementation for Windows/Android
  }
  
  // Scan single barcode
  Future<String?> scan() async {
    try {
      final result = await _performScan();
      return result;
    } catch (e) {
      throw ScannerException('Scan failed: $e');
    }
  }
  
  // Listen for continuous scans
  void startContinuousScanning() {
    // Enable keyboard emulation for scanner input
  }
  
  void stopContinuousScanning() {
    // Stop listening
  }
  
  Future<String?> _performScan() async {
    // Platform-specific scan implementation
    return null;
  }
  
  void dispose() {
    _scanController.close();
  }
}
```

**Usage in POS Screen**:

```dart
class RetailPOSScreen extends StatefulWidget {
  @override
  State<RetailPOSScreen> createState() => _RetailPOSScreenState();
}

class _RetailPOSScreenState extends State<RetailPOSScreen> {
  late StreamSubscription _barcodeSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeBarcode();
  }
  
  void _initializeBarcode() {
    final scanner = BarcodeScannerService.instance;
    
    _barcodeSubscription = scanner.onBarcodeScanned.listen((barcode) {
      _handleBarcodeScanned(barcode);
    });
  }
  
  void _handleBarcodeScanned(String barcode) {
    // Find product by barcode
    final product = _products.firstWhereOrNull((p) => p.barcode == barcode);
    
    if (product != null) {
      // Add to cart
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
      
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added: ${product.name}')),
      );
    } else {
      // Product not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found: $barcode'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _barcodeSubscription.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // ... screen UI
  }
}
```

### 4. Payment Terminal Integration (Card Reader)

**Example: mPOS Card Reader**

```dart
// lib/services/payment_terminal_service.dart
import 'package:stripe_terminal/stripe_terminal.dart';

class PaymentTerminalService {
  static final instance = PaymentTerminalService._();
  
  late StripeTerminal _terminal;
  
  PaymentTerminalService._() {
    _initializeTerminal();
  }
  
  Future<void> _initializeTerminal() async {
    _terminal = StripeTerminal.instance;
    
    // Initialize with API key
    await _terminal.initialize();
  }
  
  // Discover readers
  Future<List<Reader>> discoverReaders() async {
    try {
      final readers = await _terminal.discoverReaders(
        isSimulated: false,
      );
      return readers;
    } catch (e) {
      throw PaymentException('Discovery failed: $e');
    }
  }
  
  // Connect to reader
  Future<void> connectReader(Reader reader) async {
    try {
      await _terminal.connectReader(reader);
    } catch (e) {
      throw PaymentException('Connection failed: $e');
    }
  }
  
  // Process card payment
  Future<PaymentResult> processCardPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      // Create payment intent
      final intent = await _terminal.createPaymentIntent(
        amount: (amount * 100).toInt(), // Convert to cents
        currency: currency,
      );
      
      // Collect payment
      final payment = await _terminal.collectPaymentMethod(intent);
      
      // Process payment
      final result = await _terminal.processPayment(payment);
      
      return PaymentResult(
        success: result.status == PaymentStatus.succeeded,
        method: PaymentMethod.card,
        amount: amount,
        transactionId: result.id,
      );
    } catch (e) {
      throw PaymentException('Payment failed: $e');
    }
  }
  
  void dispose() {
    _terminal.dispose();
  }
}
```

### 5. Hardware Error Handling

**Pattern**:

```dart
// lib/services/hardware_error_handler.dart
class HardwareErrorHandler {
  static void handlePrinterError(PrinterException error) {
    // Log error
    print('PRINTER ERROR: ${error.message}');
    
    // Categorize error
    if (error.message.contains('not connected')) {
      // Show reconnection dialog
      _showReconnectDialog();
    } else if (error.message.contains('paper')) {
      // Show "add paper" dialog
      _showAddPaperDialog();
    } else if (error.message.contains('offline')) {
      // Show offline message
      _showOfflineMessage();
    }
  }
  
  static void handleScannerError(ScannerException error) {
    print('SCANNER ERROR: ${error.message}');
    
    if (error.message.contains('timeout')) {
      // Retry scan
      _retryScan();
    }
  }
  
  static void handlePaymentError(PaymentException error) {
    print('PAYMENT ERROR: ${error.message}');
    
    // Log for audit trail
    _logPaymentError(error);
    
    // Show user-friendly message
    if (error.message.contains('declined')) {
      _showCardDeclinedMessage();
    } else if (error.message.contains('timeout')) {
      _showTimeoutMessage();
    } else {
      _showGenericErrorMessage(error);
    }
  }
}
```

### 6. Testing Hardware Integration

```dart
// test/services/thermal_printer_service_test.dart
void main() {
  group('ThermalPrinterService', () {
    late ThermalPrinterService service;
    late MockBlueThermalPrinter mockPrinter;
    
    setUp(() {
      mockPrinter = MockBlueThermalPrinter();
      service = ThermalPrinterService.withDependency(mockPrinter);
    });
    
    test('connects to printer successfully', () async {
      final device = BluetoothDevice(name: 'Printer', address: '00:00:00:00');
      
      when(mockPrinter.connect(device)).thenAnswer((_) async {});
      
      await service.connectPrinter(device);
      
      expect(service.isConnected, isTrue);
      verify(mockPrinter.connect(device)).called(1);
    });
    
    test('prints receipt without errors', () async {
      final receipt = Receipt(
        businessName: 'Test Shop',
        items: [
          CartItem(product: Product(name: 'Coffee', price: 5.50), quantity: 1),
        ],
        subtotal: 5.50,
        tax: 0.33,
        total: 5.83,
      );
      
      when(mockPrinter.printText(any)).thenAnswer((_) async {});
      when(mockPrinter.cut()).thenAnswer((_) async {});
      
      await service.printReceipt(receipt);
      
      verify(mockPrinter.printText(any)).called(greaterThan(5));
      verify(mockPrinter.cut()).called(1);
    });
    
    test('throws exception when not connected', () async {
      service.disconnect();
      
      expect(
        () => service.printReceipt(receipt),
        throwsA(isA<PrinterException>()),
      );
    });
  });
}
```

### 7. Device Permissions (Android)

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest ...>
  <!-- Bluetooth -->
  <uses-permission android:name="android.permission.BLUETOOTH" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
  
  <!-- USB -->
  <uses-permission android:name="android.permission.USB_PERMISSION" />
  
  <!-- Camera (for barcode) -->
  <uses-permission android:name="android.permission.CAMERA" />
  
  <application ...>
    <!-- USB intent filter -->
    <intent-filter>
      <action android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" />
    </intent-filter>
  </application>
</manifest>
```

---

## Quick Reference: When This Skill Applies

✅ **Invoke This Skill For**:
- Thermal printer integration
- Receipt printing and formatting
- Barcode scanner setup
- Payment terminal integration
- Hardware device discovery
- Hardware error handling
- Bluetooth device connection
- USB device communication
- Printer permissions setup
- Hardware-specific testing

❌ **Don't Use For**:
- General POS logic (use Business Logic skill)
- UI/Layout (use UI Design skill)
- Architecture decisions (use Architecture skill)

---

## Integration with Your Project

**Existing Hardware Services**:
- `lib/services/thermal_printer_service.dart` - 58mm/80mm printers
- `lib/services/barcode_scanner_service.dart` - Barcode scanning
- `lib/services/receipt_formatter_service.dart` - Receipt formatting

**Supported Platforms**:
- Android tablets (primary for hardware)
- Windows desktop (printer via Windows Print Spooler)

**Tested Printers**:
- Xprinter XP-58
- Sunmi T2
- Epson TM-T88

**Receipt Width Standards**:
- 58mm: 32 characters
- 80mm: 48 characters

