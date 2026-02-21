import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/shift_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EndShiftDialog extends StatefulWidget {
  final Shift shift;
  const EndShiftDialog({super.key, required this.shift});

  @override
  State<EndShiftDialog> createState() => _EndShiftDialogState();
}

class _EndShiftDialogState extends State<EndShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _endShift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final endedShift = await ShiftService().endShift(
        widget.shift.id,
        amount,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Generate and print X-Report
      await _printShiftReport(endedShift);

      if (mounted) {
        Navigator.of(context).pop(true);
        ToastHelper.showToast(context, 'Shift ended successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error ending shift: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _printShiftReport(Shift shift) async {
    try {
      final info = BusinessInfo.instance;
      final now = DateTime.now();

      final receiptData = {
        'store_name': info.businessName,
        'address': [
          info.fullAddress,
          if (info.taxNumber != null && info.taxNumber!.isNotEmpty)
            'Tax No: ${info.taxNumber}',
        ],
        'title': 'SHIFT END REPORT (X-REPORT)',
        'date':
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
        'customer': '',
        'bill_no': 'SHIFT-${shift.id}',
        'payment_mode': '',
        'dr_ref': '',
        'currency': info.currencySymbol,
        'items': [
          {'name': 'Opening Float', 'qty': 1, 'amt': shift.openingCash},
          {'name': 'Expected Cash', 'qty': 1, 'amt': shift.expectedCash ?? 0.0},
          {'name': 'Closing Cash', 'qty': 1, 'amt': shift.closingCash ?? 0.0},
          {
            'name': 'Variance',
            'qty': 1,
            'amt': (shift.closingCash ?? 0.0) - (shift.expectedCash ?? 0.0),
          },
        ],
        'sub_total_qty': 1,
        'sub_total_amt': shift.expectedCash ?? 0.0,
        'discount': 0.0,
        'taxes': [],
        'total': shift.expectedCash ?? 0.0,
        'footer': [
          'Shift Start: ${shift.startTime.toString().substring(0, 16)}',
          'Shift End: ${shift.endTime?.toString().substring(0, 16) ?? 'N/A'}',
          if (shift.notes != null && shift.notes!.isNotEmpty)
            'Notes: ${shift.notes}',
          '',
          '*** X-REPORT - Running Total ***',
          'Business day continues...',
        ],
      };

      // Get default printer
      final printers = await DatabaseService.instance.getPrinters();
      final defaultPrinter = printers.isNotEmpty
          ? printers.firstWhere(
              (p) => p.isDefault,
              orElse: () => printers.first,
            )
          : null;

      if (defaultPrinter != null) {
        await PrinterService().printReceipt(defaultPrinter, receiptData);
      }
    } catch (e) {
      // Don't show error for printing failure, as shift is already ended
      print('Failed to print shift report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('End Shift'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift started: ${widget.shift.startTime.toString().substring(0, 16)}',
              ),
              Text(
                'Opening Float: RM ${widget.shift.openingCash.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Closing Cash Amount',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _endShift,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('End Shift', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
