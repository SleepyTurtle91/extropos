part of 'reports_screen.dart';

extension _ReportsScreenExports on _ReportsScreenState {
  void _showProductReports() {
    if (_topProducts.isEmpty && _productAnalytics.isEmpty) {
      ToastHelper.showToast(context, 'No product report data available');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._topProducts.take(5).map(
                  (product) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.productName),
                    subtitle: Text('${product.unitsSold} units sold'),
                    trailing: Text('RM ${product.revenue.toStringAsFixed(2)}'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportToCSV();
                        },
                        icon: const Icon(Icons.file_download),
                        label: const Text('Export CSV'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportToPDF();
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFinancialReports() {
    final summary = _salesSummary;
    if (summary == null) {
      ToastHelper.showToast(context, 'No financial report data available');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Financial Report Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gross Sales: RM ${summary.grossSales.toStringAsFixed(2)}'),
              Text('Net Sales: RM ${summary.netSales.toStringAsFixed(2)}'),
              Text('Tax: RM ${summary.totalTax.toStringAsFixed(2)}'),
              Text('Service Charge: RM ${summary.totalServiceCharge.toStringAsFixed(2)}'),
              Text('Discounts: RM ${summary.totalDiscount.toStringAsFixed(2)}'),
              Text('Transactions: ${summary.transactionCount}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToCSV();
              },
              child: const Text('Export CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToPDF();
              },
              child: const Text('Export PDF'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToCSV() async {
    try {
      final csvData = _generateCSVData();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvData);

      if (mounted) {
        ToastHelper.showToast(context, 'CSV exported to: $fileName');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to export CSV: $e');
      }
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                if (_salesSummary != null) ...[
                  pw.Text('Total Revenue: RM ${_salesSummary!.grossSales.toStringAsFixed(2)}'),
                  pw.Text('Net Sales: RM ${_salesSummary!.netSales.toStringAsFixed(2)}'),
                  pw.Text('Total Orders: ${_salesSummary!.transactionCount}'),
                  pw.SizedBox(height: 20),
                ],
                pw.Text('Top Products:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ..._topProducts.map((product) =>
                  pw.Text('${product.itemName}: RM ${product.revenue.toStringAsFixed(2)} (${product.quantitySold} sold)')
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ToastHelper.showToast(context, 'PDF exported to: $fileName');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to export PDF: $e');
      }
    }
  }

  String _generateCSVData() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Sales Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
    buffer.writeln('');

    // Summary
    if (_salesSummary != null) {
      buffer.writeln('Summary');
      buffer.writeln('Total Revenue,RM ${_salesSummary!.grossSales.toStringAsFixed(2)}');
      buffer.writeln('Net Sales,RM ${_salesSummary!.netSales.toStringAsFixed(2)}');
      buffer.writeln('Total Orders,${_salesSummary!.transactionCount}');
      buffer.writeln('');
    }

    // Top Products
    buffer.writeln('Top Products');
    buffer.writeln('Product Name,Revenue,Quantity Sold');
    for (final product in _topProducts) {
      buffer.writeln('${product.itemName},RM ${product.revenue.toStringAsFixed(2)},${product.quantitySold}');
    }
    buffer.writeln('');

    // Staff Performance
    if (_staffPerformance.isNotEmpty) {
      buffer.writeln('Staff Performance');
      buffer.writeln('Staff Name,Total Sales,Transaction Count,Average Order Value');
      for (final staff in _staffPerformance) {
        buffer.writeln('${staff.name},RM ${staff.totalSales.toStringAsFixed(2)},${staff.transactionCount},RM ${staff.averageOrderValue.toStringAsFixed(2)}');
      }
      buffer.writeln('');
    }

    // Product Analytics
    if (_productAnalytics.isNotEmpty) {
      buffer.writeln('Product Analytics (ABC Analysis)');
      buffer.writeln('Product Name,Revenue,Quantity Sold,ABC Class,Profit Margin %');
      for (final product in _productAnalytics) {
        buffer.writeln('${product.name},RM ${product.revenue.toStringAsFixed(2)},${product.quantitySold},${product.abcClass},${product.profitMargin.toStringAsFixed(1)}');
      }
    }

    return buffer.toString();
  }
}
