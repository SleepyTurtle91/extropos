import 'package:extropos/models/business_info_model.dart';
import 'package:flutter/material.dart';

/// Cash Payment Dialog
/// Allows user to enter tendered amount and calculates change
class CashPaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(double) onPaymentConfirmed; // Called with tendered amount

  const CashPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPaymentConfirmed,
  });

  @override
  State<CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<CashPaymentDialog> {
  late TextEditingController _tenderedController;
  double _tendered = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tenderedController = TextEditingController();
  }

  @override
  void dispose() {
    _tenderedController.dispose();
    super.dispose();
  }

  double get _change => (_tendered - widget.totalAmount).clamp(0.0, double.infinity);

  void _updateTendered(String value) {
    setState(() {
      _tendered = double.tryParse(value) ?? 0.0;
      if (_tendered < widget.totalAmount) {
        _error = 'Amount is less than total';
      } else {
        _error = null;
      }
    });
  }

  void _confirmPayment() {
    if (_tendered < widget.totalAmount) {
      setState(() => _error = 'Insufficient payment');
      return;
    }
    Navigator.of(context).pop();
    widget.onPaymentConfirmed(_tendered);
  }

  void _addQuickAmount(double amount) {
    final newTotal = _tendered + amount;
    _tenderedController.text = newTotal.toStringAsFixed(2);
    _updateTendered(newTotal.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final businessInfo = BusinessInfo.instance;
    final tax = businessInfo.isTaxEnabled ? (widget.totalAmount * businessInfo.taxRate) : 0.0;
    final serviceCharge = businessInfo.isServiceChargeEnabled
        ? ((widget.totalAmount - tax) * businessInfo.serviceChargeRate)
        : 0.0;

    return AlertDialog(
      title: Text('Cash Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal:', style: TextStyle(fontSize: 14)),
                      Text(
                        '${businessInfo.currencySymbol}${(widget.totalAmount - tax - serviceCharge).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (businessInfo.isTaxEnabled) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax (${businessInfo.taxRatePercentage}):', style: TextStyle(fontSize: 12)),
                        Text(
                          '${businessInfo.currencySymbol}${tax.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (businessInfo.isServiceChargeEnabled) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Service (${businessInfo.serviceChargeRatePercentage}):', style: TextStyle(fontSize: 12)),
                        Text(
                          '${businessInfo.currencySymbol}${serviceCharge.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  Divider(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '${businessInfo.currencySymbol}${widget.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Tendered amount input
            TextField(
              controller: _tenderedController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount Tendered',
                hintText: '0.00',
                prefixText: businessInfo.currencySymbol,
                border: OutlineInputBorder(),
                errorText: _error,
              ),
              onChanged: _updateTendered,
            ),
            SizedBox(height: 12),

            // Quick amount buttons
            Wrap(
              spacing: 8,
              children: [10, 20, 50, 100].map((amt) {
                return ElevatedButton(
                  onPressed: () => _addQuickAmount(amt.toDouble()),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.blue[50],
                  ),
                  child: Text('+${businessInfo.currencySymbol}$amt'),
                );
              }).toList(),
            ),
            SizedBox(height: 12),

            // Change display
            if (_tendered > 0)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Change:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      '${businessInfo.currencySymbol}${_change.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _error != null ? null : _confirmPayment,
          child: Text('Confirm Payment'),
        ),
      ],
    );
  }
}
