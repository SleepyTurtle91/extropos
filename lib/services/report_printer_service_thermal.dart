part of 'report_printer_service.dart';

extension ReportPrinterServiceThermal on ReportPrinterService {
  /// Print a condensed thermal summary (58/80mm) using the existing printer pipeline.
  Future<bool> printThermalSummary({
    required pos_printer.Printer printer,
    required SalesSummary summary,
    required String periodLabel,
    List<CategoryPerformance>? categories,
    List<PaymentMethodStats>? paymentMethods,
  }) async {
    final info = BusinessInfo.instance;
    final width = (printer.paperSize == pos_printer.ThermalPaperSize.mm80) ? 42 : 32;

    String padRight(String label, String value) {
      final available = width - value.length;
      final paddedLabel = label.padRight(available > 0 ? available : label.length);
      return '$paddedLabel$value';
    }

    List<String> wrap(String text) {
      if (text.isEmpty) return [''];
      final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final lines = <String>[];
      var current = '';
      for (final word in words) {
        if (current.isEmpty) {
          if (word.length <= width) current = word;
          else lines.addAll(_splitWord(word, width));
        } else {
          final candidate = '$current $word';
          if (candidate.length <= width) {
            current = candidate;
          } else {
            lines.add(current);
            current = word.length <= width ? word : '';
            if (word.length > width) lines.addAll(_splitWord(word, width));
          }
        }
      }
      if (current.isNotEmpty) lines.add(current);
      return lines;
    }

    final lines = <String>[];
    lines.addAll(wrap(info.businessName));
    lines.addAll(wrap(info.fullAddress));
    if (info.taxNumber != null && info.taxNumber!.isNotEmpty) {
      lines.addAll(wrap('Tax No: ${info.taxNumber}'));
    }
    lines.add('-' * width);
    lines.addAll(wrap('Sales Report ($periodLabel)'));
    lines.add('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    lines.add('-' * width);

    final c = info.currencySymbol;
    lines.add(padRight('Total Revenue', '$c ${summary.totalRevenue.toStringAsFixed(2)}'));
    lines.add(padRight('Net Sales', '$c ${summary.netSales.toStringAsFixed(2)}'));
    lines.add(padRight('Transactions', summary.transactionCount.toString()));
    lines.add(padRight('Avg Ticket', '$c ${summary.averageTransactionValue.toStringAsFixed(2)}'));
    lines.add(padRight('Total Discount', '$c ${summary.totalDiscount.toStringAsFixed(2)}'));

    if (paymentMethods != null && paymentMethods.isNotEmpty) {
      lines.add('-' * width);
      lines.add('Payments');
      for (final m in paymentMethods) {
        lines.add(padRight(m.paymentMethodName, '$c ${m.totalAmount.toStringAsFixed(2)}'));
      }
    }

    if (categories != null && categories.isNotEmpty) {
      lines.add('-' * width);
      lines.add('Categories');
      for (final cat in categories.take(6)) {
        lines.add(padRight(cat.categoryName, '$c ${cat.revenue.toStringAsFixed(2)}'));
      }
    }

    lines.add('-' * width);
    lines.add('Thank you!');

    return await PrinterService().debugForcePrint(printer, {
      'title': 'Sales Report',
      'content': lines.join('\n'),
    });
  }

  List<String> _splitWord(String word, int width) {
    final chunks = <String>[];
    for (var i = 0; i < word.length; i += width) {
      final end = (i + width) > word.length ? word.length : i + width;
      chunks.add(word.substring(i, end));
    }
    return chunks;
  }

  /// Generate thermal format report for 58mm or 80mm printer
  String generateThermalReport({
    required SalesSummary summary,
    required List<ProductPerformance> topProducts,
    required List<PaymentMethodStats> paymentMethods,
    required String periodLabel,
    required int paperWidth,
  }) {
    final buffer = StringBuffer();
    final businessInfo = BusinessInfo.instance;
    final currency = businessInfo.currencySymbol;

    String center(String text) {
      if (text.length >= paperWidth) return text.substring(0, paperWidth);
      final padding = (paperWidth - text.length) ~/ 2;
      return ' ' * padding + text;
    }

    String alignRight(String text) => text.padLeft(paperWidth);

    buffer.writeln(center('═' * (paperWidth - 2)));
    buffer.writeln(center(businessInfo.businessName));
    buffer.writeln(center('SALES REPORT'));
    buffer.writeln(center('Period: $periodLabel'));
    buffer.writeln(center(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())));
    buffer.writeln(center('═' * (paperWidth - 2)));
    buffer.writeln();

    buffer.writeln(center('SUMMARY'));
    buffer.writeln('─' * paperWidth);
    buffer.writeln('Revenue: ${alignRight('$currency ${summary.totalRevenue.toStringAsFixed(2)}')}');
    buffer.writeln('Discount: ${alignRight('$currency ${summary.totalDiscount.toStringAsFixed(2)}')}');
    buffer.writeln('Tax: ${alignRight('$currency ${summary.totalTax.toStringAsFixed(2)}')}');
    buffer.writeln('Transactions: ${alignRight(summary.transactionCount.toString())}');
    buffer.writeln('Avg Ticket: ${alignRight('$currency ${summary.averageTransactionValue.toStringAsFixed(2)}')}');
    buffer.writeln();

    if (paymentMethods.isNotEmpty) {
      buffer.writeln(center('PAYMENT METHODS'));
      buffer.writeln('─' * paperWidth);
      for (final method in paymentMethods) {
        buffer.writeln('${method.paymentMethodName.padRight(15)} ${method.transactionCount.toString().padLeft(6)} ${method.totalAmount.toStringAsFixed(2).padLeft(10)}');
      }
      buffer.writeln();
    }

    if (topProducts.isNotEmpty) {
      buffer.writeln(center('TOP PRODUCTS'));
      buffer.writeln('─' * paperWidth);
      for (var i = 0; i < topProducts.take(10).length; i++) {
        final product = topProducts[i];
        final name = product.productName.length > 15 ? '${product.productName.substring(0, 15)}..' : product.productName;
        buffer.writeln('${(i + 1).toString()}. ${name.padRight(14)} ${product.unitsSold.toString().padLeft(3)} ${product.revenue.toStringAsFixed(2).padLeft(9)}');
      }
      buffer.writeln();
    }

    buffer.writeln('═' * paperWidth);
    buffer.writeln(center('Thank you'));
    return buffer.toString();
  }
}
