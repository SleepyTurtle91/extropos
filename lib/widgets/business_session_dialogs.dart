import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_session_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/shift/start_shift_dialog.dart';
import 'package:extropos/services/business_session_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Dialog for opening business with starting cash amount
class OpenBusinessDialog extends StatefulWidget {
  const OpenBusinessDialog({super.key});

  @override
  State<OpenBusinessDialog> createState() => _OpenBusinessDialogState();
}

class _OpenBusinessDialogState extends State<OpenBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    // Use context directly with mounted checks

    setState(() => _isLoading = true);

    try {
      final openingCash = double.parse(_cashController.text);
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final success = await BusinessSessionService().openBusiness(
        openingCash,
        notes: notes,
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ToastHelper.showToast(context, 'Business opened successfully!');
        
        // Automatically trigger Start Shift dialog for the logged-in user
        final userSession = UserSessionService();
        if (userSession.hasActiveUser && mounted) {
          // Add a small delay to ensure the dialog closes before showing the next one
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mounted) {
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => StartShiftDialog(
                userId: userSession.currentActiveUser!.id,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to open business');
      }
    } catch (e) {
      if (mounted)
        ToastHelper.showToast(context, 'Failed to open business: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Business'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the starting cash amount in the cash drawer to begin business operations.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cashController,
              decoration: const InputDecoration(
                labelText: 'Starting Cash Amount',
                prefixText: 'RM',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter starting cash amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _openBusiness,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Open Business'),
        ),
      ],
    );
  }
}

/// Dialog for closing business with closing cash amount
class CloseBusinessDialog extends StatefulWidget {
  const CloseBusinessDialog({super.key});

  @override
  State<CloseBusinessDialog> createState() => _CloseBusinessDialogState();
}

class _CloseBusinessDialogState extends State<CloseBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current session's opening cash as a reference
    final session = BusinessSessionService().currentSession;
    if (session != null) {
      _cashController.text = session.openingCash.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _closeBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    // Use context directly with mounted checks

    setState(() => _isLoading = true);

    try {
      final closingCash = double.parse(_cashController.text);
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final success = await BusinessSessionService().closeBusiness(
        closingCash,
        notes: notes,
      );

      if (success && mounted) {
        // Clear any active user sessions
        UserSessionService().clearSession();

        // Print Z-Report
        await _printClosingReport();

        Navigator.of(context).pop(true);
        ToastHelper.showToast(context, 'Business closed successfully!');
      } else {
        throw Exception('Failed to close business');
      }
    } catch (e) {
      if (mounted)
        ToastHelper.showToast(context, 'Failed to close business: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _createClosingReportReceiptData(
    BusinessSession session,
    SalesSummaryReport salesReport,
  ) {
    final info = BusinessInfo.instance;
    final now = DateTime.now();

    return {
      'store_name': info.businessName,
      'address': [
        info.fullAddress,
        if (info.taxNumber != null && info.taxNumber!.isNotEmpty)
          'Tax No: ${info.taxNumber}',
      ],
      'title': 'Z-REPORT (END OF DAY)',
      'date':
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
      'customer': '',
      'bill_no': 'SESSION-${session.id}',
      'payment_mode': '',
      'dr_ref': '',
      'currency': info.currencySymbol,
      'items': [
        {'name': 'Opening Cash', 'qty': 1, 'amt': session.openingCash},
        {'name': 'Gross Sales', 'qty': 1, 'amt': salesReport.grossSales},
        {'name': 'Net Sales', 'qty': 1, 'amt': salesReport.netSales},
        {
          'name': 'Total Transactions',
          'qty': salesReport.totalTransactions,
          'amt': 0.0,
        },
        {
          'name': 'Avg Transaction',
          'qty': 1,
          'amt': salesReport.averageTransactionValue,
        },
        {'name': 'Tax Collected', 'qty': 1, 'amt': salesReport.taxCollected},
        {'name': 'Discounts', 'qty': 1, 'amt': salesReport.totalDiscounts},
        if (session.closingCash != null)
          {'name': 'Closing Cash', 'qty': 1, 'amt': session.closingCash!},
        if (session.closingCash != null)
          {'name': 'Cash Diff', 'qty': 1, 'amt': session.cashDifference},
      ],
      'sub_total_qty': salesReport.totalTransactions,
      'sub_total_amt': salesReport.grossSales,
      'discount': 0.0,
      'taxes': [],
      'service_charge': 0.0,
      'total': salesReport.netSales,
      'amount_paid': 0.0,
      'change': 0.0,
      'footer': [
        'Session Start: ${session.openDate.toString().substring(0, 19)}',
        'Session End: ${DateTime.now().toString().substring(0, 19)}',
        if (session.notes != null && session.notes!.isNotEmpty)
          'Notes: ${session.notes}',
      ],
    };
  }

  Future<void> _printClosingReport() async {
    // Use context directly with mounted checks
    final session = BusinessSessionService().currentSession;
    if (session == null) return;

    try {
      // Generate sales summary for the current business session
      final period = ReportPeriod(
        label: 'Current Session',
        startDate: session.openDate,
        endDate: DateTime.now(),
      );
      final salesReport = await DatabaseService.instance
          .generateSalesSummaryReport(period);

      // Check for default printer
      final printers = await DatabaseService.instance.getPrinters();
      final defaultPrinter = printers.isNotEmpty
          ? printers.firstWhere(
              (p) => p.isDefault,
              orElse: () => printers.first,
            )
          : null;

      if (defaultPrinter != null) {
        // Print thermal report
        final receiptData = _createClosingReportReceiptData(
          session,
          salesReport,
        );
        final success = await PrinterService().printReceipt(
          defaultPrinter,
          receiptData,
        );

        if (success) {
          if (mounted) {
            ToastHelper.showToast(
              context,
              'Closing report printed successfully',
            );
          }
          return;
        } else {
          if (mounted) {
            ToastHelper.showToast(
              context,
              'Thermal print failed, falling back to PDF',
            );
          }
        }
      }

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Business Closing Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Business Period: ${session.openDate.toString().substring(0, 19)} - ${DateTime.now().toString().substring(0, 19)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Opening Cash: RM${session.openingCash.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Sales Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Metric', 'Value'],
                  data: [
                    [
                      'Gross Sales',
                      'RM${salesReport.grossSales.toStringAsFixed(2)}',
                    ],
                    [
                      'Net Sales',
                      'RM${salesReport.netSales.toStringAsFixed(2)}',
                    ],
                    [
                      'Total Transactions',
                      salesReport.totalTransactions.toString(),
                    ],
                    [
                      'Average Transaction',
                      'RM${salesReport.averageTransactionValue.toStringAsFixed(2)}',
                    ],
                    [
                      'Tax Collected',
                      'RM${salesReport.taxCollected.toStringAsFixed(2)}',
                    ],
                    [
                      'Total Discounts',
                      'RM${salesReport.totalDiscounts.toStringAsFixed(2)}',
                    ],
                  ],
                ),
                pw.SizedBox(height: 20),
                if (session.closingCash != null) ...[
                  pw.Text(
                    'Closing Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Closing Cash: RM${session.closingCash!.toStringAsFixed(2)}',
                  ),
                  pw.Text(
                    'Cash Difference: RM${session.cashDifference.toStringAsFixed(2)}',
                  ),
                ],
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Notes: ${session.notes}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted)
        ToastHelper.showToast(context, 'Failed to print closing report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = BusinessSessionService().currentSession;
    if (session == null) {
      return AlertDialog(
        title: Text('Error'),
        content: Text('No active business session found.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      );
    }

    final openingCash = session.openingCash;
    final cashDifference = double.tryParse(_cashController.text) != null
        ? double.parse(_cashController.text) - openingCash
        : 0.0;

    return AlertDialog(
      title: const Text('Close Business'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Business opened: ${session.openDate.toString().substring(0, 19)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Opening cash: RM${openingCash.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the current cash amount in the cash drawer to close business operations.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cashController,
              decoration: const InputDecoration(
                labelText: 'Closing Cash Amount',
                prefixText: 'RM',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter closing cash amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Difference: ${cashDifference >= 0 ? '+' : ''}RM${cashDifference.toStringAsFixed(2)}',
              style: TextStyle(
                color: cashDifference >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _printClosingReport,
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Print Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _closeBusiness,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Close Business'),
        ),
      ],
    );
  }
}
