import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:flutter/foundation.dart';

/// Receipt type for dual receipt functionality
enum ReceiptType {
  customer,  // Simplified receipt for customer
  merchant,  // Detailed receipt for merchant records
}

/// Generates a thermal printer receipt as formatted text
/// Exactly replicates the "RAGA PVT LTD" receipt layout
String generateReceiptText({
  required Map<String, dynamic> data,
  required int charWidth,
}) {
  final buffer = StringBuffer();

  // Helper functions for alignment
  String center(String text) =>
      text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);
  String right(String text) => text.padLeft(charWidth);

  // 1. Header (Centered)
  buffer.writeln(center(data['store_name']));
  for (String line in data['address']) {
    buffer.writeln(center(line));
  }
  buffer.writeln();
  buffer.writeln(center(data['title']));
  buffer.writeln();

  // 2. Metadata (Left-Aligned)
  buffer.writeln(left('Date : ${data['date']}, ${data['time']}'));
  buffer.writeln(left(data['customer']));
  buffer.writeln();
  buffer.writeln(left('Bill No: ${data['bill_no']}'));
  buffer.writeln(left('Payment Mode: ${data['payment_mode']}'));
  buffer.writeln(left('DR Ref : ${data['dr_ref']}'));

  // 3. Item Table
  // Calculate column widths (total should equal charWidth)
  final itemWidth = (charWidth * 0.5).floor(); // 50% for item name
  final qtyWidth = (charWidth * 0.25).floor(); // 25% for quantity
  final amtWidth = charWidth - itemWidth - qtyWidth; // Remaining for amount

  // Header
  final itemHeader = 'Item'.padRight(itemWidth);
  final qtyHeader = 'Qty'.padLeft(qtyWidth);
  final amtHeader = 'Amt'.padLeft(amtWidth);
  buffer.writeln('$itemHeader$qtyHeader$amtHeader');

  // Separator
  buffer.writeln('.' * charWidth);

  // Item rows
  for (Map<String, dynamic> item in data['items']) {
    final itemName = item['name'].toString().padRight(itemWidth);
    final qty = item['qty'].toString().padLeft(qtyWidth);
    final amt = item['amt'].toStringAsFixed(2).padLeft(amtWidth);
    buffer.writeln('$itemName$qty$amt');
  }

  // Separator
  buffer.writeln('-' * charWidth);

  // 4. Summary
  // Sub Total (3 columns like items)
  final subTotalLabel = 'Sub Total'.padRight(itemWidth);
  final subTotalQty = data['sub_total_qty'].toString().padLeft(qtyWidth);
  final subTotalAmt = data['sub_total_amt']
      .toStringAsFixed(2)
      .padLeft(amtWidth);
  buffer.writeln('$subTotalLabel$subTotalQty$subTotalAmt');

  // Discount (2 columns)
  final discountLabel = '(-) Discount'.padRight(charWidth - amtWidth);
  final discountAmt = data['discount'].toStringAsFixed(2).padLeft(amtWidth);
  buffer.writeln('$discountLabel$discountAmt');

  // Taxes (2 columns each)
  for (Map<String, dynamic> tax in data['taxes']) {
    final taxLabel = tax['name'].toString().padRight(charWidth - amtWidth);
    final taxAmt = tax['amt'].toStringAsFixed(2).padLeft(amtWidth);
    buffer.writeln('$taxLabel$taxAmt');
  }

  // 5. Total
  buffer.writeln('=' * charWidth);
  final totalLabel = 'TOTAL'.padRight(charWidth - amtWidth);
  final totalAmt = 'Rs ${data['total'].toStringAsFixed(2)}'.padLeft(amtWidth);
  buffer.writeln('$totalLabel$totalAmt');
  buffer.writeln('=' * charWidth);

  // 6. Payment
  final cashLabel = 'Cash :'.padRight(charWidth - amtWidth);
  final cashAmt = 'Rs ${data['cash'].toStringAsFixed(2)}'.padLeft(amtWidth);
  buffer.writeln('$cashLabel$cashAmt');

  final cashTenderedLabel = 'Cash tendered:'.padRight(charWidth - amtWidth);
  final cashTenderedAmt = 'Rs ${data['cash_tendered'].toStringAsFixed(2)}'
      .padLeft(amtWidth);
  buffer.writeln('$cashTenderedLabel$cashTenderedAmt');

  // 6b. E-Wallet metadata (if provided)
  if (data['ewallet_provider'] != null || data['ewallet_qr'] != null) {
    buffer.writeln('-' * charWidth);
    buffer.writeln(left('E-Wallet Payment'));
    if (data['ewallet_provider'] != null) {
      buffer.writeln(left('Provider: ${data['ewallet_provider']}'));
    }
    if (data['ewallet_merchant_id'] != null && (data['ewallet_merchant_id'] as String).isNotEmpty) {
      buffer.writeln(left('Merchant ID: ${data['ewallet_merchant_id']}'));
    }
    if (data['ewallet_reference'] != null) {
      buffer.writeln(left('Reference: ${data['ewallet_reference']}'));
    }
    if (data['ewallet_qr'] != null) {
      // For text receipts, show QR data string
      // For image receipts, printer service will render QR bitmap from 'ewallet_qr_image' key
      buffer.writeln(left('Scan QR:'));
      if (data['ewallet_qr_image'] == null) {
        buffer.writeln(left('${data['ewallet_qr']}'));
      } else {
        buffer.writeln(center('[QR CODE IMAGE]'));
      }
    }
  }

  // 7. Footer
  buffer.writeln();
  buffer.writeln(right(data['footer']));

  return buffer.toString();
}

/// Generates a thermal printer receipt as formatted text using ReceiptSettings
/// Optional logoPath parameter can override BusinessInfo.instance.logo
String generateReceiptTextWithSettings({
  required Map<String, dynamic> data,
  required ReceiptSettings settings,
  required int charWidth,
  String? logoPath,
  ReceiptType receiptType = ReceiptType.customer,
}) {
  final buffer = StringBuffer();

  // Helper functions for alignment
  String center(String text) =>
      text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);

  // 1. Header (use settings - conditionally shown based on receipt type)
  if (settings.showLogo) {
    // Get logo from BusinessInfo
    final logoPath = BusinessInfo.instance.logo;
    if (logoPath != null && logoPath.isNotEmpty) {
      // For text-based receipts, add simple ASCII logo placeholder
      // Real logo rendering would require image-to-ASCII conversion
      buffer.writeln(center('[LOGO]'));
      buffer.writeln();
    }
  }

  // For merchant receipts, show full business header
  if (receiptType == ReceiptType.merchant) {
    if (settings.headerText.isNotEmpty) {
      buffer.writeln(center(settings.headerText));
    }

    // Business info from data (store name, address)
    if (data['store_name'] != null) {
      buffer.writeln(center(data['store_name']));
    }

    if (data['address'] != null && data['address'] is List) {
      for (String line in data['address']) {
        buffer.writeln(center(line));
      }
    }
    if (settings.showTaxId && data['tax_id'] != null) {
      final taxId = (data['tax_id'] as String?) ?? '';
      if (taxId.isNotEmpty) {
        buffer.writeln(center(taxId));
      }
    }
  } else {
    // Customer receipt - minimal header
    if (data['store_name'] != null) {
      buffer.writeln(center(data['store_name']));
    }
    if (settings.showTaxId && data['tax_id'] != null) {
      final taxId = (data['tax_id'] as String?) ?? '';
      if (taxId.isNotEmpty) {
        buffer.writeln(center(taxId));
      }
    }
  }

  buffer.writeln();
  final title = receiptType == ReceiptType.merchant
      ? (data['title'] ?? 'RECEIPT')
      : (data['title'] ?? 'CUSTOMER RECEIPT');
  buffer.writeln(center(title));
  buffer.writeln();

  // 2. Date/Time and transaction details (conditionally shown based on receipt type)
  if (receiptType == ReceiptType.merchant) {
    // Merchant receipt - show full details
    if (settings.showDateTime) {
      if (data['date'] != null && data['time'] != null) {
        buffer.writeln(left('Date: ${data['date']}, Time: ${data['time']}'));
      }
    }

    // Customer info
    if (data['customer'] != null) {
      buffer.writeln(left('Customer: ${data['customer']}'));
    }

    // Order/Bill info
    if (settings.showOrderNumber && data['bill_no'] != null) {
      buffer.writeln(left('Bill No: ${data['bill_no']}'));
    }

    if (data['payment_mode'] != null) {
      buffer.writeln(left('Payment Mode: ${data['payment_mode']}'));
    }

    if (data['dr_ref'] != null) {
      buffer.writeln(left('DR Ref: ${data['dr_ref']}'));
    }
  } else {
    // Customer receipt - minimal details
    if (settings.showDateTime && data['date'] != null) {
      buffer.writeln(left('Date: ${data['date']}'));
    }

    if (settings.showOrderNumber && data['bill_no'] != null) {
      buffer.writeln(left('Receipt #: ${data['bill_no']}'));
    }
  }

  // 3. Item Table
  // Calculate column widths (total should equal charWidth)
  final itemWidth = (charWidth * 0.5).floor(); // 50% for item name
  final qtyWidth = (charWidth * 0.25).floor(); // 25% for quantity
  final amtWidth = charWidth - itemWidth - qtyWidth; // Remaining for amount

  // Header
  final itemHeader = 'Item'.padRight(itemWidth);
  final qtyHeader = 'Qty'.padLeft(qtyWidth);
  final amtHeader = 'Amt'.padLeft(amtWidth);
  buffer.writeln('$itemHeader$qtyHeader$amtHeader');

  // Separator
  buffer.writeln('.' * charWidth);

  // Item rows
  if (data['items'] != null && data['items'] is List) {
    for (Map<String, dynamic> item in data['items']) {
      final itemName = item['name'].toString().padRight(itemWidth);
      final qty = item['qty']?.toString() ?? '0';
      final qtyPadded = qty.padLeft(qtyWidth);
      final amtValue = item['amt'] as num?;
      final amt = (amtValue?.toDouble() ?? 0.0)
          .toStringAsFixed(2)
          .padLeft(amtWidth);
      buffer.writeln('$itemName$qtyPadded$amt');
    }
  }

  // Separator
  buffer.writeln('-' * charWidth);

  // 4. Summary
  // Sub Total (3 columns like items)
  if (data['sub_total_qty'] != null && data['sub_total_amt'] != null) {
    final subTotalLabel = 'Sub Total'.padRight(itemWidth);
    final subTotalQty = data['sub_total_qty'].toString().padLeft(qtyWidth);
    final subTotalAmtValue = data['sub_total_amt'] as num?;
    final subTotalAmt = (subTotalAmtValue?.toDouble() ?? 0.0)
        .toStringAsFixed(2)
        .padLeft(amtWidth);
    buffer.writeln('$subTotalLabel$subTotalQty$subTotalAmt');
  }

  // Discount (2 columns)
  final discountValue = data['discount'] as num?;
  if (discountValue != null && discountValue > 0) {
    final discountLabel = '(-) Discount'.padRight(charWidth - amtWidth);
    final discountAmt = discountValue
        .toDouble()
        .toStringAsFixed(2)
        .padLeft(amtWidth);
    buffer.writeln('$discountLabel$discountAmt');
  }

  // Taxes (conditionally shown based on settings)
  if (settings.showTaxBreakdown &&
      data['taxes'] != null &&
      data['taxes'] is List) {
    for (Map<String, dynamic> tax in data['taxes']) {
      final taxLabel = tax['name'].toString().padRight(charWidth - amtWidth);
      final taxAmtValue = tax['amt'] as num?;
      final taxAmt = (taxAmtValue?.toDouble() ?? 0.0)
          .toStringAsFixed(2)
          .padLeft(amtWidth);
      buffer.writeln('$taxLabel$taxAmt');
    }
  }

  // Service Charge (conditionally shown based on settings)
  final serviceChargeValue = data['service_charge'] as num?;
  if (settings.showServiceChargeBreakdown &&
      serviceChargeValue != null &&
      serviceChargeValue > 0) {
    final serviceLabel = 'Service Charge'.padRight(charWidth - amtWidth);
    final serviceAmt = serviceChargeValue
        .toDouble()
        .toStringAsFixed(2)
        .padLeft(amtWidth);
    buffer.writeln('$serviceLabel$serviceAmt');
  }

  // 5. Total
  buffer.writeln('=' * charWidth);
  final totalValue = data['total'] as num?;
  if (totalValue != null) {
    final totalLabel = 'TOTAL'.padRight(charWidth - amtWidth);
    final totalAmt =
        '${data['currency'] ?? 'Rs'} ${totalValue.toDouble().toStringAsFixed(2)}'
            .padLeft(amtWidth);
    buffer.writeln('$totalLabel$totalAmt');
  }
  buffer.writeln('=' * charWidth);

  // 6. Payment
  final paymentSplits = data['payment_splits'] as List?;
  if (paymentSplits != null && paymentSplits.isNotEmpty) {
    // Handle split payments
    for (int i = 0; i < paymentSplits.length; i++) {
      final split = paymentSplits[i] as Map<String, dynamic>;
      final method = split['method'] as String? ?? 'Unknown';
      final amount = split['amount'] as num? ?? 0.0;
      final reference = split['reference'] as String? ?? '';

      final paymentLabel = i == 0
          ? '$method:'.padRight(charWidth - amtWidth)
          : '  $method:'.padRight(charWidth - amtWidth);

      final paymentAmt =
          '${data['currency'] ?? 'Rs'} ${amount.toDouble().toStringAsFixed(2)}'
              .padLeft(amtWidth);
      buffer.writeln('$paymentLabel$paymentAmt');

      // Show reference if available (e.g., card number, transaction ID)
      if (reference.isNotEmpty) {
        final refLabel = '  Ref:'.padRight(charWidth - amtWidth);
        final refValue = reference.padLeft(amtWidth);
        buffer.writeln('$refLabel$refValue');
      }
    }

    // Show total amount paid if different from total
    final amountPaid = data['amount_paid'] as num?;
    if (amountPaid != null && amountPaid != data['total']) {
      final paidLabel = 'Amount Paid:'.padRight(charWidth - amtWidth);
      final paidAmt =
          '${data['currency'] ?? 'Rs'} ${amountPaid.toDouble().toStringAsFixed(2)}'
              .padLeft(amtWidth);
      buffer.writeln('$paidLabel$paidAmt');
    }
  } else {
    // Fallback to legacy single payment fields
    final cashValue = data['cash'] as num?;
    if (cashValue != null) {
      final cashLabel = 'Cash :'.padRight(charWidth - amtWidth);
      final cashAmt =
          '${data['currency'] ?? 'Rs'} ${cashValue.toDouble().toStringAsFixed(2)}'
              .padLeft(amtWidth);
      buffer.writeln('$cashLabel$cashAmt');
    }

    final cashTenderedValue = data['cash_tendered'] as num?;
    if (cashTenderedValue != null) {
      final cashTenderedLabel = 'Cash tendered:'.padRight(charWidth - amtWidth);
      final cashTenderedAmt =
          '${data['currency'] ?? 'Rs'} ${cashTenderedValue.toDouble().toStringAsFixed(2)}'
              .padLeft(amtWidth);
      buffer.writeln('$cashTenderedLabel$cashTenderedAmt');
    }
  }

  // Change (if any)
  final changeValue = data['change'] as num?;
  if (changeValue != null && changeValue > 0) {
    final changeLabel = 'Change:'.padRight(charWidth - amtWidth);
    final changeAmt =
        '${data['currency'] ?? 'Rs'} ${changeValue.toDouble().toStringAsFixed(2)}'
            .padLeft(amtWidth);
    buffer.writeln('$changeLabel$changeAmt');
  }

  // 7. Footer (use settings - different for customer vs merchant)
  buffer.writeln();

  // Custom footer data (e.g. closing report session times) - merchant only
  if (receiptType == ReceiptType.merchant && data['footer'] != null && data['footer'] is List) {
    final footerLines = data['footer'] as List;
    for (final line in footerLines) {
      if (line != null && line.toString().isNotEmpty) {
        buffer.writeln(center(line.toString()));
      }
    }
    buffer.writeln();
  }

  // Thank you message - customer receipt only
  if (receiptType == ReceiptType.customer && settings.showThankYouMessage && settings.thankYouMessage.isNotEmpty) {
    buffer.writeln(center(settings.thankYouMessage));
  }

  // Footer text - merchant receipt only
  if (receiptType == ReceiptType.merchant && settings.footerText.isNotEmpty) {
    buffer.writeln(center(settings.footerText));
  }

  // Terms and conditions - merchant receipt only
  if (receiptType == ReceiptType.merchant && settings.termsAndConditions.isNotEmpty) {
    buffer.writeln();
    buffer.writeln(center('Terms & Conditions:'));
    buffer.writeln(settings.termsAndConditions);
  }

  if (settings.showWifiDetails && data['wifi_details'] != null) {
    final wifi = (data['wifi_details'] as String?) ?? '';
    if (wifi.isNotEmpty) {
      buffer.writeln();
      for (final line in wifi.split('\n')) {
        buffer.writeln(center(line));
      }
    }
  }

  if (settings.showBarcode && data['barcode'] != null) {
    final barcode = (data['barcode'] as String?) ?? '';
    if (barcode.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(center('[BARCODE]'));
      buffer.writeln(center(barcode));
    }
  }

  if (settings.showQrCode && data['qr_data'] != null) {
    final qrData = (data['qr_data'] as String?) ?? '';
    if (qrData.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(center('[QR CODE]'));
      buffer.writeln(center(qrData));
    }
  }

  // Always show thank you for customer receipts
  if (receiptType == ReceiptType.customer) {
    buffer.writeln();
    buffer.writeln(center('Thank You!'));
    buffer.writeln(center('Please Come Again'));
  }

  return buffer.toString();
}

// Example usage
void main() {
  final Map<String, dynamic> receiptData = {
    'store_name': 'RAGA PVT LTD',
    'address': [
      'S USMAN ROAD, T. NAGAR,',
      'CHENNAI, TAMIL NADU.',
      'PHONE : 044 258636222',
      'GSTIN : 33AAAGP0685F1ZH',
    ],
    'title': 'RETAIL INVOICE',
    'date': '23/03/2020',
    'time': '04:57 PM',
    'customer': 'David Stores',
    'bill_no': 'SR2',
    'payment_mode': 'Cash',
    'dr_ref': '2',
    'items': [
      {'name': 'Alternagel', 'qty': 1, 'amt': 200.00},
      {'name': 'Bepanthen', 'qty': 1, 'amt': 560.00},
    ],
    'sub_total_qty': 2,
    'sub_total_amt': 760.00,
    'discount': 26.00,
    'taxes': [
      {'name': 'CGST @ 14.00%', 'amt': 24.36},
      {'name': 'SGST @ 14.00%', 'amt': 24.36},
      {'name': 'CGST @ 2.50%', 'amt': 14.00},
      {'name': 'SGST @ 2.50%', 'amt': 14.00},
    ],
    'total': 811.00,
    'cash': 811.00,
    'cash_tendered': 811.00,
    'footer': 'E & O.E',
  };

  // For 80mm printer (48 characters)
  debugPrint('=== 80mm Receipt (48 chars) ===');
  debugPrint(generateReceiptText(data: receiptData, charWidth: 48));

  // For 58mm printer (32 characters)
  debugPrint('\n=== 58mm Receipt (32 chars) ===');
  debugPrint(generateReceiptText(data: receiptData, charWidth: 32));
}

/// Generates a kitchen order ticket as formatted text
/// Simple format focused on order details for kitchen staff
String generateKitchenOrderText({
  required Map<String, dynamic> data,
  required int charWidth,
  ReceiptSettings? settings,
}) {
  final kitchenSettings = settings ?? ReceiptSettings();
  // Allow override via data payload (printer can pass kitchen_template_style)
  KitchenTemplateStyle effectiveStyle = kitchenSettings.kitchenTemplateStyle;
  if (data['kitchen_template_style'] != null &&
      data['kitchen_template_style'] is String) {
    try {
      final s = data['kitchen_template_style'] as String;
      effectiveStyle = KitchenTemplateStyle.values.firstWhere(
        (e) => e.name == s,
        orElse: () => kitchenSettings.kitchenTemplateStyle,
      );
    } catch (_) {}
  }

  // Use compact template if selected, otherwise use standard
  if (effectiveStyle == KitchenTemplateStyle.compact) {
    return _generateCompactKitchenOrderText(
      data: data,
      charWidth: charWidth,
      settings: kitchenSettings,
    );
  } else {
    return _generateStandardKitchenOrderText(
      data: data,
      charWidth: charWidth,
      settings: kitchenSettings,
    );
  }
}

String _generateCompactKitchenOrderText({
  required Map<String, dynamic> data,
  required int charWidth,
  required ReceiptSettings settings,
}) {
  final buffer = StringBuffer();

  // Helper functions for alignment
  String center(String text) =>
      text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);

  // 1. Header (data override or settings)
  final rawHeader =
      (data['order_header'] as String?) ?? settings.kitchenHeaderText;
  final header = rawHeader.isNotEmpty
      ? rawHeader.toUpperCase()
      : 'KITCHEN ORDER';
  buffer.writeln(center(header));
  buffer.writeln();

  // 1b. Table/Order number header (large and prominent for cafe mode)
  final orderType = data['order_type']?.toString() ?? '';
  if (orderType == 'cafe') {
    // For cafe mode, show calling number prominently
    final callingNumber = data['order_number']?.toString() ?? 'N/A';
    buffer.writeln(center('*** CALLING ***'));
    buffer.writeln(center('ORDER #$callingNumber'));
    buffer.writeln('=' * charWidth);
  } else {
    // For restaurant mode, show table number
    final tableNumber =
        data['table']?.toString() ?? data['order_number']?.toString() ?? 'N/A';
    buffer.writeln(center('TABLE: $tableNumber'));
    buffer.writeln('=' * charWidth);
  }

  // 2. Merchant/Type section (if applicable)
  final merchant = data['merchant']?.toString() ?? '';

  if (merchant.isNotEmpty && merchant != 'none' && merchant != 'takeaway') {
    buffer.writeln(center('---$merchant---'));
  }

  if (orderType.isNotEmpty) {
    if (orderType.toUpperCase() == 'TAKEAWAY') {
      buffer.writeln();
      buffer.writeln(center(orderType.toUpperCase()));
    }
  }

  buffer.writeln();

  // 3. Items
  final items = data['items'] as List<dynamic>? ?? [];
  for (final item in items) {
    final name = item['name']?.toString() ?? 'Unknown Item';
    final quantity = item['quantity']?.toString() ?? '1';
    final modifiers = item['modifiers']?.toString() ?? '';

    buffer.writeln(left('${quantity}x  $name'));

    if (settings.kitchenShowModifiers && modifiers.isNotEmpty) {
      buffer.writeln(left('     $modifiers'));
    }
  }

  buffer.writeln('=' * charWidth);

  // 4. Date/Time footer
  if (settings.kitchenShowDateTime) {
    final timestamp =
        data['timestamp']?.toString() ?? DateTime.now().toString();
    // Format timestamp nicely (e.g., "1/29/2024  11:04 PM")
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(timestamp);
    } catch (e) {
      dateTime = DateTime.now();
    }

    final dateStr = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $amPm';

    buffer.writeln();
    // Split date and time to left and right sides
    final spacing = charWidth - dateStr.length - timeStr.length;
    if (spacing > 0) {
      buffer.writeln('$dateStr${' ' * spacing}$timeStr');
    } else {
      buffer.writeln(center('$dateStr  $timeStr'));
    }
  }

  buffer.writeln('=' * charWidth);

  return buffer.toString();
}

String _generateStandardKitchenOrderText({
  required Map<String, dynamic> data,
  required int charWidth,
  required ReceiptSettings settings,
}) {
  final buffer = StringBuffer();

  // Helper functions for alignment
  String center(String text) =>
      text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);

  // 1. Header - Use a short KOT header similar to the sample
  // Allow header text customization but default to the abbreviation KOT
  final rawHeader =
      (data['order_header'] as String?) ?? settings.kitchenHeaderText;
  final headerText = rawHeader.isNotEmpty ? rawHeader : 'Kitchen Order';
  buffer.writeln(center(headerText.toUpperCase()));
  buffer.writeln();

  // 2. Order Info - Compose a top row with order number (left) and timestamp (right)
  final orderNumber = data['order_number']?.toString() ?? '';
  final orderType = data['order_type']?.toString() ?? '';

  // For cafe mode, show calling number prominently
  if (orderType == 'cafe' && orderNumber.isNotEmpty) {
    buffer.writeln(center('*** CALLING ORDER ***'));
    buffer.writeln(center('ORDER #$orderNumber'));
    buffer.writeln('-' * charWidth);
  }

  // Format timestamp as dd/MM/yyyy hh:mm AM/PM
  String formattedDateTime = '';
  if (settings.kitchenShowDateTime) {
    final ts = data['timestamp']?.toString();
    DateTime dateTime;
    try {
      dateTime = ts != null ? DateTime.parse(ts) : DateTime.now();
    } catch (e) {
      dateTime = DateTime.now();
    }
    final d = dateTime;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    formattedDateTime = '$day/$month/$year $hour:$minute $ampm';
  }

  // Left side: order number, Right side: date/time in the same line
  final orderLeft = orderNumber.isNotEmpty ? orderNumber : '';
  if (orderLeft.isNotEmpty || formattedDateTime.isNotEmpty) {
    final leftPart = orderLeft.isNotEmpty ? orderLeft : '';
    final rightPart = formattedDateTime;
    final spacing = charWidth - leftPart.length - rightPart.length;
    if (spacing > 0) {
      buffer.writeln('$leftPart${' ' * spacing}$rightPart');
    } else {
      buffer.writeln('$leftPart $rightPart');
    }
  }

  // Customer and Table lines as separate lines to match template
  if (data['customer_name'] != null &&
      data['customer_name'].toString().isNotEmpty) {
    buffer.writeln(left('Customer : ${data['customer_name']}'));
  }
  if (settings.kitchenShowTable && data['table'] != null) {
    buffer.writeln(left('Table No. : ${data['table']}'));
  }

  // Add a horizontal separator
  buffer.writeln('-' * charWidth);

  // 3. Items - Render as table with columns: Sl.No | Item Name | Qty
  final items = data['items'] as List<dynamic>? ?? [];
  // Dynamic column widths
  final int slCol = 4; // fits 1..9999
  final int qtyCol = (charWidth >= 48) ? 6 : 5; // 'Qty.' header
  final int itemCol = charWidth - slCol - qtyCol;

  // Header row for items
  final slHeader = 'Sl.No'.padRight(slCol);
  final itemHeader = 'Item Name'.padRight(itemCol);
  final qtyHeader = 'Qty.'.padLeft(qtyCol);
  buffer.writeln('$slHeader$itemHeader$qtyHeader');

  // Separator line
  buffer.writeln('-' * charWidth);

  // Item rows
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final name = (item['name'] ?? 'Unknown Item').toString();
    // Support both 'quantity' and 'qty' fields
    final quantityVal = item['quantity'] ?? item['qty'] ?? 0;
    final quantity = quantityVal.toString();

    // Ensure name doesn't exceed column
    final itemName = name.length > itemCol
        ? name.substring(0, itemCol - 1)
        : name.padRight(itemCol);

    final sl = (i + 1).toString().padRight(slCol);
    final qtyStr = quantity.padLeft(qtyCol);
    buffer.writeln('$sl$itemName$qtyStr');

    // Modifiers (optional) displayed below the item, indented
    if (settings.kitchenShowModifiers) {
      final modifiers = (item['modifiers'] ?? '').toString();
      if (modifiers.isNotEmpty) {
        final modLabel = '   - $modifiers';
        // Wrap modifiers if longer than itemCol
        final modParts = <String>[];
        if (modLabel.length <= charWidth) {
          modParts.add(modLabel);
        } else {
          int start = 0;
          while (start < modLabel.length) {
            final end = (start + charWidth) < modLabel.length
                ? start + charWidth
                : modLabel.length;
            modParts.add(modLabel.substring(start, end));
            start = end;
          }
        }
        for (final p in modParts) {
          buffer.writeln(p);
        }
      }
    }
  }

  // Separator after items
  buffer.writeln('-' * charWidth);

  // 4. Special Instructions
  if (data['special_instructions'] != null &&
      data['special_instructions'].toString().isNotEmpty) {
    buffer.writeln();
    buffer.writeln(left('SPECIAL INSTRUCTIONS:'));
    buffer.writeln(left(data['special_instructions'].toString()));
    buffer.writeln();
    buffer.writeln('=' * charWidth);
  }

  // 5. Totals - Total number of items (i.e., total item lines), shown right aligned
  final totalItems = items.length;
  final totalLabel = 'Total Items :';
  final totalRight = totalItems.toString();
  final spacingAfterTotal = charWidth - totalLabel.length - totalRight.length;
  if (spacingAfterTotal > 0) {
    buffer.writeln('$totalLabel${' ' * spacingAfterTotal}$totalRight');
  } else {
    buffer.writeln('$totalLabel $totalRight');
  }

  // 5. Footer - Use customizable kitchen footer text
  if (settings.kitchenFooterText.isNotEmpty) {
    buffer.writeln();
    buffer.writeln(center(settings.kitchenFooterText));
  }

  return buffer.toString();
}
