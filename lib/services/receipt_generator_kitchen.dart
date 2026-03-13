part of 'receipt_generator.dart';

/// Generates a kitchen order ticket as formatted text
String generateKitchenOrderText({
  required Map<String, dynamic> data,
  required int charWidth,
  ReceiptSettings? settings,
}) {
  final kitchenSettings = settings ?? ReceiptSettings();
  KitchenTemplateStyle effectiveStyle = kitchenSettings.kitchenTemplateStyle;
  
  if (data['kitchen_template_style'] != null && data['kitchen_template_style'] is String) {
    try {
      final s = data['kitchen_template_style'] as String;
      effectiveStyle = KitchenTemplateStyle.values.firstWhere(
        (e) => e.name == s,
        orElse: () => kitchenSettings.kitchenTemplateStyle,
      );
    } catch (_) {}
  }

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
  String center(String text) => text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);

  final rawHeader = (data['order_header'] as String?) ?? settings.kitchenHeaderText;
  final header = rawHeader.isNotEmpty ? rawHeader.toUpperCase() : 'KITCHEN ORDER';
  buffer.writeln(center(header));
  buffer.writeln();

  final orderType = data['order_type']?.toString() ?? '';
  if (orderType == 'cafe') {
    final callingNumber = data['order_number']?.toString() ?? 'N/A';
    buffer.writeln(center('*** CALLING ***'));
    buffer.writeln(center('ORDER #$callingNumber'));
  } else {
    final tableNumber = data['table']?.toString() ?? data['order_number']?.toString() ?? 'N/A';
    buffer.writeln(center('TABLE: $tableNumber'));
  }
  buffer.writeln('=' * charWidth);

  final items = data['items'] as List<dynamic>? ?? [];
  for (final item in items) {
    final name = item['name']?.toString() ?? 'Unknown Item';
    final quantity = (item['quantity'] ?? item['qty'] ?? 1).toString();
    buffer.writeln(left('${quantity}x  $name'));
    
    final modifiers = item['modifiers']?.toString() ?? '';
    if (settings.kitchenShowModifiers && modifiers.isNotEmpty) {
      buffer.writeln(left('     $modifiers'));
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
  String center(String text) => text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);

  final rawHeader = (data['order_header'] as String?) ?? settings.kitchenHeaderText;
  buffer.writeln(center((rawHeader.isNotEmpty ? rawHeader : 'Kitchen Order').toUpperCase()));
  buffer.writeln();

  final orderNumber = data['order_number']?.toString() ?? '';
  final orderType = data['order_type']?.toString() ?? '';

  if (orderType == 'cafe' && orderNumber.isNotEmpty) {
    buffer.writeln(center('*** CALLING ORDER ***'));
    buffer.writeln(center('ORDER #$orderNumber'));
    buffer.writeln('-' * charWidth);
  }

  if (data['customer_name'] != null && data['customer_name'].toString().isNotEmpty) {
    buffer.writeln(left('Customer : ${data['customer_name']}'));
  }
  if (settings.kitchenShowTable && data['table'] != null) {
    buffer.writeln(left('Table No. : ${data['table']}'));
  }

  buffer.writeln('-' * charWidth);

  final items = data['items'] as List<dynamic>? ?? [];
  final slCol = 4;
  final qtyCol = (charWidth >= 48) ? 6 : 5;
  final itemCol = charWidth - slCol - qtyCol;

  buffer.writeln('${'Sl.No'.padRight(slCol)}${'Item Name'.padRight(itemCol)}${'Qty.'.padLeft(qtyCol)}');
  buffer.writeln('-' * charWidth);

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final name = (item['name'] ?? 'Unknown Item').toString();
    final quantity = (item['quantity'] ?? item['qty'] ?? 0).toString();
    
    final sl = (i + 1).toString().padRight(slCol);
    final itemName = name.length > itemCol ? name.substring(0, itemCol - 1) : name.padRight(itemCol);
    final qtyStr = quantity.padLeft(qtyCol);
    buffer.writeln('$sl$itemName$qtyStr');

    if (settings.kitchenShowModifiers) {
      final modifiers = (item['modifiers'] ?? '').toString();
      if (modifiers.isNotEmpty) buffer.writeln('   - $modifiers');
    }
  }

  buffer.writeln('-' * charWidth);
  return buffer.toString();
}
