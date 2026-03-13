part of 'report_printer_service.dart';

extension ReportPrinterServicePdf on ReportPrinterService {
  /// Generate PDF document for a sales report
  Future<Uint8List> generateReportPDF({
    required SalesSummary summary,
    required List<CategoryPerformance> categories,
    required List<ProductPerformance> topProducts,
    required List<PaymentMethodStats> paymentMethods,
    required String periodLabel,
  }) async {
    final doc = pw.Document();
    final businessInfo = BusinessInfo.instance;
    final currency = businessInfo.currencySymbol;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(businessInfo.businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Sales Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text('Period: $periodLabel', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              _buildTableRow('Total Revenue', '$currency ${summary.totalRevenue.toStringAsFixed(2)}', isHeader: true),
              _buildTableRow('Net Sales', '$currency ${summary.netSales.toStringAsFixed(2)}'),
              _buildTableRow('Transactions', '${summary.transactionCount}'),
              _buildTableRow('Avg Ticket', '$currency ${summary.averageTransactionValue.toStringAsFixed(2)}'),
              _buildTableRow('Total Discount', '$currency ${summary.totalDiscount.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Payment Methods', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Method', isBold: true),
                  _buildTableCell('Transactions', isBold: true),
                  _buildTableCell('Amount', isBold: true),
                ],
              ),
              ...paymentMethods.map((m) => pw.TableRow(
                children: [
                  _buildTableCell(m.paymentMethodName),
                  _buildTableCell('${m.transactionCount}'),
                  _buildTableCell('$currency ${m.totalAmount.toStringAsFixed(2)}'),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Top Products', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Rank', isBold: true),
                  _buildTableCell('Product', isBold: true),
                  _buildTableCell('Units', isBold: true),
                  _buildTableCell('Revenue', isBold: true),
                ],
              ),
              ...topProducts.asMap().entries.map((entry) => pw.TableRow(
                children: [
                  _buildTableCell('${entry.key + 1}'),
                  _buildTableCell(entry.value.productName),
                  _buildTableCell('${entry.value.unitsSold}'),
                  _buildTableCell('$currency ${entry.value.revenue.toStringAsFixed(2)}'),
                ],
              )),
            ],
          ),
          pw.Divider(),
          pw.Center(child: pw.Text('This is a computer-generated report', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500))),
        ],
      ),
    );
    return doc.save();
  }

  pw.TableRow _buildTableRow(String label, String value, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey300) : null,
      children: [
        _buildTableCell(label, isBold: isHeader),
        _buildTableCell(value, isBold: isHeader),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
    );
  }

  Future<void> printPDF({required Uint8List pdfBytes, required String documentName}) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => pdfBytes, name: documentName);
    } catch (e) {
      developer.log('Print error: $e');
    }
  }

  Future<String?> exportToPDFFile({required Uint8List pdfBytes}) async {
    try {
      final fileName = 'sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final directory = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      return filePath;
    } catch (e) {
      rethrow;
    }
  }
}
