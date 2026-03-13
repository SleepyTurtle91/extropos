part of 'receipt_generator.dart';

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
  buffer.writeln(center(data['store_name'] ?? ''));
  final address = data['address'] as List<dynamic>? ?? [];
  for (final line in address) {
    buffer.writeln(center(line.toString()));
  }
  buffer.writeln();
  buffer.writeln(center(data['title'] ?? 'RECEIPT'));
  buffer.writeln();

  // 2. Metadata (Left-Aligned)
  buffer.writeln(left('Date : ${data['date'] ?? ''}, ${data['time'] ?? ''}'));
  buffer.writeln(left(data['customer'] ?? 'Walk-in Customer'));
  buffer.writeln();
  buffer.writeln(left('Bill No: ${data['bill_no'] ?? ''}'));
  buffer.writeln(left('Payment Mode: ${data['payment_mode'] ?? ''}'));
  buffer.writeln(left('DR Ref : ${data['dr_ref'] ?? ''}'));

  // 3. Item Table
  final itemWidth = (charWidth * 0.5).floor();
  final qtyWidth = (charWidth * 0.25).floor();
  final amtWidth = charWidth - itemWidth - qtyWidth;

  final itemHeader = 'Item'.padRight(itemWidth);
  final qtyHeader = 'Qty'.padLeft(qtyWidth);
  final amtHeader = 'Amt'.padLeft(amtWidth);
  buffer.writeln('$itemHeader$qtyHeader$amtHeader');
  buffer.writeln('.' * charWidth);

  final items = data['items'] as List<dynamic>? ?? [];
  for (final item in items) {
    final itemName = item['name'].toString().padRight(itemWidth);
    final qty = item['qty'].toString().padLeft(qtyWidth);
    final amt = (item['amt'] as num).toStringAsFixed(2).padLeft(amtWidth);
    buffer.writeln('$itemName$qty$amt');
  }

  buffer.writeln('-' * charWidth);

  // 4. Summary
  final subTotalLabel = 'Sub Total'.padRight(itemWidth);
  final subTotalQty = (data['sub_total_qty'] ?? 0).toString().padLeft(qtyWidth);
  final subTotalAmt = (data['sub_total_amt'] as num? ?? 0.0)
      .toStringAsFixed(2)
      .padLeft(amtWidth);
  buffer.writeln('$subTotalLabel$subTotalQty$subTotalAmt');

  final discountValue = data['discount'] as num? ?? 0.0;
  if (discountValue > 0) {
    final discountLabel = '(-) Discount'.padRight(charWidth - amtWidth);
    final discountAmt = discountValue.toStringAsFixed(2).padLeft(amtWidth);
    buffer.writeln('$discountLabel$discountAmt');
  }

  final taxes = data['taxes'] as List<dynamic>? ?? [];
  for (final tax in taxes) {
    final taxLabel = tax['name'].toString().padRight(charWidth - amtWidth);
    final taxAmt = (tax['amt'] as num).toStringAsFixed(2).padLeft(amtWidth);
    buffer.writeln('$taxLabel$taxAmt');
  }

  // 5. Total
  buffer.writeln('=' * charWidth);
  final totalLabel = 'TOTAL'.padRight(charWidth - amtWidth);
  final totalAmt = 'Rs ${(data['total'] as num? ?? 0.0).toStringAsFixed(2)}'.padLeft(amtWidth);
  buffer.writeln('$totalLabel$totalAmt');
  buffer.writeln('=' * charWidth);

  // 6. Payment
  final cashAmt = (data['cash'] as num? ?? 0.0).toStringAsFixed(2);
  buffer.writeln('${'Cash :'.padRight(charWidth - amtWidth)}Rs $cashAmt');
  
  final tendered = (data['cash_tendered'] as num? ?? 0.0).toStringAsFixed(2);
  buffer.writeln('${'Cash tendered:'.padRight(charWidth - amtWidth)}Rs $tendered');

  if (data['ewallet_provider'] != null || data['ewallet_qr'] != null) {
    buffer.writeln('-' * charWidth);
    buffer.writeln(left('E-Wallet Payment'));
    if (data['ewallet_provider'] != null) {
      buffer.writeln(left('Provider: ${data['ewallet_provider']}'));
    }
    if (data['ewallet_reference'] != null) {
      buffer.writeln(left('Reference: ${data['ewallet_reference']}'));
    }
  }

  // 7. Footer
  buffer.writeln();
  buffer.writeln(right(data['footer']?.toString() ?? 'E & O.E'));

  return buffer.toString();
}

/// Generates a thermal printer receipt as formatted text using ReceiptSettings
String generateReceiptTextWithSettings({
  required Map<String, dynamic> data,
  required ReceiptSettings settings,
  required int charWidth,
  String? logoPath,
  ReceiptType receiptType = ReceiptType.customer,
}) {
  final buffer = StringBuffer();

  String center(String text) =>
      text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);

  // 1. Header
  if (settings.showLogo) {
    buffer.writeln(center('[LOGO]'));
    buffer.writeln();
  }

  if (receiptType == ReceiptType.merchant) {
    if (settings.headerText.isNotEmpty) buffer.writeln(center(settings.headerText));
    if (data['store_name'] != null) buffer.writeln(center(data['store_name']));
    final address = data['address'] as List<dynamic>? ?? [];
    for (final line in address) buffer.writeln(center(line.toString()));
  } else {
    if (data['store_name'] != null) buffer.writeln(center(data['store_name']));
  }

  buffer.writeln();
  final title = receiptType == ReceiptType.merchant
      ? (data['title'] ?? 'RECEIPT')
      : (data['title'] ?? 'CUSTOMER RECEIPT');
  buffer.writeln(center(title));
  buffer.writeln();

  // 2. Details
  if (receiptType == ReceiptType.merchant) {
    if (settings.showDateTime && data['date'] != null) {
      buffer.writeln(left('Date: ${data['date']}, Time: ${data['time']}'));
    }
    if (data['customer'] != null) buffer.writeln(left('Customer: ${data['customer']}'));
    if (settings.showOrderNumber && data['bill_no'] != null) {
      buffer.writeln(left('Bill No: ${data['bill_no']}'));
    }
  } else {
    if (settings.showDateTime && data['date'] != null) buffer.writeln(left('Date: ${data['date']}'));
    if (settings.showOrderNumber && data['bill_no'] != null) {
      buffer.writeln(left('Receipt #: ${data['bill_no']}'));
    }
  }

  // 3. Item Table
  final itemWidth = (charWidth * 0.5).floor();
  final qtyWidth = (charWidth * 0.25).floor();
  final amtWidth = charWidth - itemWidth - qtyWidth;

  buffer.writeln('${'Item'.padRight(itemWidth)}${'Qty'.padLeft(qtyWidth)}${'Amt'.padLeft(amtWidth)}');
  buffer.writeln('.' * charWidth);

  final items = data['items'] as List<dynamic>? ?? [];
  for (final item in items) {
    final name = item['name'].toString().padRight(itemWidth);
    final qty = (item['qty']?.toString() ?? '0').padLeft(qtyWidth);
    final amtValue = item['amt'] as num?;
    final amt = (amtValue?.toDouble() ?? 0.0).toStringAsFixed(2).padLeft(amtWidth);
    buffer.writeln('$name$qty$amt');
  }
  buffer.writeln('-' * charWidth);

  // 4. Summary & Totals
  if (data['sub_total_amt'] != null) {
    final subLabel = 'Sub Total'.padRight(itemWidth);
    final subQty = (data['sub_total_qty'] ?? 0).toString().padLeft(qtyWidth);
    final subAmt = (data['sub_total_amt'] as num).toDouble().toStringAsFixed(2).padLeft(amtWidth);
    buffer.writeln('$subLabel$subQty$subAmt');
  }

  final totalValue = data['total'] as num? ?? 0.0;
  buffer.writeln('=' * charWidth);
  final totalLabel = 'TOTAL'.padRight(charWidth - amtWidth);
  final totalAmt = '${data['currency'] ?? 'Rs'} ${totalValue.toDouble().toStringAsFixed(2)}'.padLeft(amtWidth);
  buffer.writeln('$totalLabel$totalAmt');
  buffer.writeln('=' * charWidth);

  // 7. Footer
  if (receiptType == ReceiptType.customer) {
    if (settings.showThankYouMessage) buffer.writeln(center(settings.thankYouMessage));
    buffer.writeln();
    buffer.writeln(center('Thank You!'));
    buffer.writeln(center('Please Come Again'));
  }

  return buffer.toString();
}
