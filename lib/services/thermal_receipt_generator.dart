import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:universal_io/io.dart';

/// Paper size enumeration for thermal printers
enum PaperSize { mm58, mm80 }

/// Thermal receipt generator for 58mm and 80mm ESC/POS printers
class ThermalReceiptGenerator {
  static const int _mm80MaxChars = 42;
  static const int _mm58MaxChars = 32;

  /// Generate receipt data for thermal printers
  /// Optional logoPath parameter allows custom logo, otherwise uses BusinessInfo.instance.logo
  static List<int> generateReceipt({
    required PaperSize paperSize,
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
    int? orderNumber,
    String? logoPath,
    bool showLogo = true,
  }) {
    final commands = <int>[];
    final maxChars = paperSize == PaperSize.mm80
        ? _mm80MaxChars
        : _mm58MaxChars;

    // Initialize printer
    commands.addAll(_initializePrinter());

    // Add logo if enabled and available
    if (showLogo) {
      final logo = logoPath ?? BusinessInfo.instance.logo;
      if (logo != null && logo.isNotEmpty) {
        commands.addAll(_addLogo(logo, maxChars));
      }
    }

    // Business header
    commands.addAll(_addBusinessHeader(maxChars, orderNumber));

    // Items section with divider (matching PDF structure)
    commands.addAll(_addDivider(maxChars));
    commands.addAll(_addItems(items, paperSize));
    commands.addAll(_addDivider(maxChars));

    // Totals section
    commands.addAll(
      _addTotalsSection(subtotal, tax, serviceCharge, total, maxChars),
    );

    // Payment information with divider
    commands.addAll(_addDivider(maxChars));
    commands.addAll(
      _addPaymentInfo(paymentMethod, amountPaid, change, maxChars),
    );

    // Footer
    commands.addAll(_addFooter());

    // Cut paper
    commands.addAll(_cutPaper());

    return commands;
  }

  static List<int> _initializePrinter() {
    return [
      0x1B, 0x40, // Initialize printer
      0x1B, 0x61, 0x01, // Center alignment
    ];
  }

  /// Add logo to receipt
  /// Converts image to monochrome bitmap and sends as ESC/POS raster image
  static List<int> _addLogo(String logoPath, int maxChars) {
    final commands = <int>[];

    try {
      // Check if logo file exists
      final logoFile = File(logoPath);
      if (!logoFile.existsSync()) {
        debugPrint('Logo file not found: $logoPath');
        return commands; // Return empty if file doesn't exist
      }

      // Load and process image
      final bytes = logoFile.readAsBytesSync();
      final image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint('Failed to decode logo image');
        return commands;
      }

      // Resize to fit receipt width (384 pixels for 80mm, 256 for 58mm)
      final targetWidth = maxChars == _mm80MaxChars ? 384 : 256;
      final resized = img.copyResize(
        image,
        width: targetWidth,
        interpolation: img.Interpolation.linear,
      );

      // Convert to monochrome using threshold
      final monochrome = img.grayscale(resized);

      // Convert to ESC/POS raster image commands
      commands.addAll([0x1B, 0x61, 0x01]); // Center alignment
      commands.addAll(_convertToRasterImage(monochrome));
      commands.addAll([0x0A, 0x0A]); // Double line feed after logo
    } catch (e) {
      // If logo loading fails, continue without it
      debugPrint('Failed to add logo: $e');
    }

    return commands;
  }

  /// Convert image to ESC/POS raster bitmap commands
  /// Uses GS v 0 command for raster image printing
  static List<int> _convertToRasterImage(img.Image image) {
    final commands = <int>[];

    // Image dimensions
    final width = image.width;
    final height = image.height;

    // Calculate bytes per line (width must be multiple of 8)
    final bytesPerLine = (width + 7) ~/ 8;

    // GS v 0: Print raster bitmap
    // Format: GS v 0 m xL xH yL yH d1...dk
    commands.addAll([
      0x1D, 0x76, 0x30, // GS v 0
      0x00, // m = 0 (normal mode, 1 dot = 1 dot)
      bytesPerLine & 0xFF, // xL (width in bytes, low byte)
      (bytesPerLine >> 8) & 0xFF, // xH (width in bytes, high byte)
      height & 0xFF, // yL (height in dots, low byte)
      (height >> 8) & 0xFF, // yH (height in dots, high byte)
    ]);

    // Convert image to bitmap data
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < bytesPerLine; x++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final px = x * 8 + bit;
          if (px < width) {
            final pixel = image.getPixel(px, y);
            // Get luminance (0-255), threshold at 128
            final luminance = img.getLuminance(pixel);
            // 1 = white (no print), 0 = black (print)
            if (luminance < 128) {
              byte |= (1 << (7 - bit));
            }
          }
        }
        commands.add(byte);
      }
    }

    return commands;
  }

  static List<int> _addBusinessHeader(int maxChars, int? orderNumber) {
    final commands = <int>[];
    final info = BusinessInfo.instance;

    // Business name (centered, bold) - wrap for small paper
    commands.addAll([0x1B, 0x45, 0x01]); // Bold on
    for (final line in _wrapText(info.businessName, maxChars)) {
      commands.addAll(_encodeText(line, maxChars));
      commands.addAll([0x0A]);
    }
    commands.addAll([0x1B, 0x45, 0x00]); // Bold off

    // Address - wrap to avoid trailing cut on narrow rolls
    for (final line in _wrapText(info.fullAddress, maxChars)) {
      commands.addAll(_encodeText(line, maxChars));
      commands.addAll([0x0A]);
    }

    // Tax number if available - matching PDF
    if (info.taxNumber != null && info.taxNumber!.isNotEmpty) {
      for (final line in _wrapText('Tax No: ${info.taxNumber}', maxChars)) {
        commands.addAll(_encodeText(line, maxChars));
        commands.addAll([0x0A]);
      }
    }

    // Spacing before order number (matching PDF SizedBox height: 6)
    commands.addAll([0x0A]);

    // Order number (bold, matching PDF)
    commands.addAll([0x1B, 0x45, 0x01]); // Bold on
    final orderText = orderNumber != null
        ? 'Order #${orderNumber.toString().padLeft(3, '0')}'
        : 'Order';
    commands.addAll(_encodeText(orderText, maxChars));
    commands.addAll([0x1B, 0x45, 0x00]); // Bold off
    commands.addAll([0x0A]);

    // Date (smaller, matching PDF fontSize: 8)
    final now = DateTime.now();
    final dateText = now.toIso8601String();
    commands.addAll(_encodeText(dateText, maxChars));
    commands.addAll([0x0A]);

    // Spacing before divider (matching PDF SizedBox height: 8)
    commands.addAll([0x0A]);

    return commands;
  }

  static List<int> _addDivider(int maxChars) {
    final commands = <int>[];
    final divider = ''.padRight(maxChars, '-');
    commands.addAll(_encodeText(divider, maxChars));
    commands.addAll([0x0A]);
    return commands;
  }

  static List<int> _addItems(List<CartItem> items, PaperSize paperSize) {
    final commands = <int>[];
    for (final item in items) {
      commands.addAll(_addItemLine(item, paperSize));
    }
    return commands;
  }

  static List<int> _addItemLine(CartItem item, PaperSize paperSize) {
    final commands = <int>[];
    final maxChars = paperSize == PaperSize.mm80
        ? _mm80MaxChars
        : _mm58MaxChars;
    final currency = BusinessInfo.instance.currencySymbol;

    commands.addAll([0x1B, 0x61, 0x00]); // Left alignment

    // Format: "Product Name xQuantity" on left, price on right (matching PDF template)
    final itemText = '${item.product.name} x${item.quantity}';
    final priceText = '$currency ${item.totalPrice.toStringAsFixed(2)}';

    // Calculate padding needed
    final totalLength = itemText.length + priceText.length;
    final spacesNeeded = maxChars - totalLength;

    final line =
        itemText + ''.padLeft(spacesNeeded > 0 ? spacesNeeded : 1) + priceText;
    final finalLine = line.length > maxChars
        ? line.substring(0, maxChars)
        : line;

    commands.addAll(_encodeText(finalLine, maxChars));
    commands.addAll([0x0A]);

    // Add modifiers if any (matching PDF template)
    if (item.modifiers.isNotEmpty) {
      final modsText = item.modifiers
          .map(
            (m) => m.priceAdjustment == 0
                ? m.name
                : '${m.name} (${m.getPriceAdjustmentDisplay()})',
          )
          .join(', ');
      commands.addAll(_encodeText(modsText, maxChars));
      commands.addAll([0x0A]);
    }

    return commands;
  }

  static List<int> _addTotalsSection(
    double subtotal,
    double tax,
    double serviceCharge,
    double total,
    int maxChars,
  ) {
    final commands = <int>[];
    final info = BusinessInfo.instance;
    final currency = info.currencySymbol;

    commands.addAll([0x0A]); // Line feed
    commands.addAll([0x1B, 0x61, 0x00]); // Left alignment

    // Subtotal (matching PDF template)
    final subtotalText = 'Subtotal';
    final subtotalAmount = '$currency ${subtotal.toStringAsFixed(2)}';
    final subtotalLine =
        subtotalText +
        ''.padLeft(maxChars - subtotalText.length - subtotalAmount.length) +
        subtotalAmount;
    commands.addAll(_encodeText(subtotalLine, maxChars));
    commands.addAll([0x0A]);

    // Tax (matching PDF template)
    if (tax > 0) {
      final taxText = 'Tax';
      final taxAmount = '$currency ${tax.toStringAsFixed(2)}';
      final taxLine =
          taxText +
          ''.padLeft(maxChars - taxText.length - taxAmount.length) +
          taxAmount;
      commands.addAll(_encodeText(taxLine, maxChars));
      commands.addAll([0x0A]);
    }

    // Service charge (matching PDF template)
    if (serviceCharge > 0) {
      final serviceText = 'Service';
      final serviceAmount = '$currency ${serviceCharge.toStringAsFixed(2)}';
      final serviceLine =
          serviceText +
          ''.padLeft(maxChars - serviceText.length - serviceAmount.length) +
          serviceAmount;
      commands.addAll(_encodeText(serviceLine, maxChars));
      commands.addAll([0x0A]);
    }

    commands.addAll([
      0x0A,
    ]); // Extra line feed before total (matching PDF SizedBox height: 4)

    // Total (bold, matching PDF template)
    commands.addAll([0x1B, 0x45, 0x01]); // Bold on
    final totalText = 'Total';
    final totalAmount = '$currency ${total.toStringAsFixed(2)}';
    final totalLine =
        totalText +
        ''.padLeft(maxChars - totalText.length - totalAmount.length) +
        totalAmount;
    commands.addAll(_encodeText(totalLine, maxChars));
    commands.addAll([0x1B, 0x45, 0x00]); // Bold off
    commands.addAll([0x0A, 0x0A]); // Double line feed

    return commands;
  }

  static List<int> _addPaymentInfo(
    PaymentMethod paymentMethod,
    double amountPaid,
    double change,
    int maxChars,
  ) {
    final commands = <int>[];
    final currency = BusinessInfo.instance.currencySymbol;

    commands.addAll([0x1B, 0x61, 0x00]); // Left alignment

    final paymentText = 'Payment: ${paymentMethod.name}';
    commands.addAll(_encodeText(paymentText, maxChars));
    commands.addAll([0x0A]);

    final paidText = 'Paid: $currency ${amountPaid.toStringAsFixed(2)}';
    commands.addAll(_encodeText(paidText, maxChars));
    commands.addAll([0x0A]);

    if (change > 0) {
      final changeText = 'Change: $currency ${change.toStringAsFixed(2)}';
      commands.addAll(_encodeText(changeText, maxChars));
      commands.addAll([0x0A]);
    }

    commands.addAll([0x0A]); // Line feed

    return commands;
  }

  static List<int> _addFooter() {
    final commands = <int>[];

    // Spacing before "Thank you!" (matching PDF SizedBox height: 12)
    commands.addAll([0x0A, 0x0A, 0x0A]); // Triple line feed for spacing

    commands.addAll([0x1B, 0x61, 0x01]); // Center alignment
    commands.addAll(_encodeText('Thank you!', 32));
    commands.addAll([0x0A, 0x0A]); // Double line feed after

    return commands;
  }

  static List<int> _cutPaper() {
    return [
      0x1D, 0x56, 0x42, 0x00, // Full cut
    ];
  }

  static List<int> _encodeText(String text, int maxWidth) {
    // Truncate if too long
    final truncated = text.length > maxWidth
        ? text.substring(0, maxWidth)
        : text;
    return truncated.codeUnits;
  }

  static List<String> _wrapText(String text, int maxWidth) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [''];

    final lines = <String>[];
    var current = '';

    for (final word in words) {
      if (current.isEmpty) {
        if (word.length <= maxWidth) {
          current = word;
        } else {
          lines.addAll(_splitLongWord(word, maxWidth));
          current = '';
        }
      } else {
        final candidate = '$current $word';
        if (candidate.length <= maxWidth) {
          current = candidate;
        } else {
          lines.add(current);
          if (word.length <= maxWidth) {
            current = word;
          } else {
            lines.addAll(_splitLongWord(word, maxWidth));
            current = '';
          }
        }
      }
    }

    if (current.isNotEmpty) {
      lines.add(current);
    }

    return lines;
  }

  static List<String> _splitLongWord(String word, int maxWidth) {
    final chunks = <String>[];
    for (var i = 0; i < word.length; i += maxWidth) {
      chunks.add(word.substring(i, i + maxWidth > word.length ? word.length : i + maxWidth));
    }
    return chunks;
  }
}
