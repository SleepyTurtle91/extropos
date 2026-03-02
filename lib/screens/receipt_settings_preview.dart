part of 'receipt_settings_screen.dart';

/// Dialog widget for previewing receipt formatting with current settings
class _ReceiptPreviewDialog extends StatelessWidget {
  final ReceiptSettings settings;

  const _ReceiptPreviewDialog({required this.settings});

  @override
  Widget build(BuildContext context) {
    final info = BusinessInfo.instance;
    // Sample cart values for preview
    const double sampleSubtotal = 33.50; // 10.00 + 15.00 + 8.50
    final double taxAmount = info.isTaxEnabled
        ? sampleSubtotal * info.taxRate
        : 0.0;
    final double serviceChargeAmount = info.isServiceChargeEnabled
        ? sampleSubtotal * info.serviceChargeRate
        : 0.0;
    final double totalAmount = sampleSubtotal + taxAmount + serviceChargeAmount;

    String fmt(double v) => FormattingService.currency(v);

    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF2563EB),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Receipt Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    width: settings.paperWidth.toDouble() * 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Currency symbol for preview
                          Builder(
                            builder: (context) {
                              return const SizedBox.shrink();
                            },
                          ),
                          if (settings.showLogo) ...[
                            Icon(
                              Icons.store,
                              size: settings.fontSize.toDouble() * 3,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            settings.headerText,
                            style: TextStyle(
                              fontSize: settings.fontSize.toDouble() + 4,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (settings.showDateTime)
                            Text(
                              DateTime.now().toString().substring(0, 19),
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 2,
                              ),
                            ),
                          if (settings.showOrderNumber) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Order #12345',
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (settings.showCashierName) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Cashier: John Doe',
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 2,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildReceiptLine(
                            'Item 1',
                            FormattingService.currency(10.00),
                            settings.fontSize,
                          ),
                          _buildReceiptLine(
                            'Item 2',
                            FormattingService.currency(15.00),
                            settings.fontSize,
                          ),
                          _buildReceiptLine(
                            'Item 3',
                            FormattingService.currency(8.50),
                            settings.fontSize,
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildReceiptLine(
                            'Subtotal',
                            fmt(sampleSubtotal),
                            settings.fontSize,
                          ),
                          if (settings.showTaxBreakdown && info.isTaxEnabled)
                            _buildReceiptLine(
                              'Tax (${info.taxRatePercentage})',
                              fmt(taxAmount),
                              settings.fontSize - 2,
                            ),
                          if (settings.showServiceChargeBreakdown &&
                              info.isServiceChargeEnabled)
                            _buildReceiptLine(
                              'Service Charge (${info.serviceChargeRatePercentage})',
                              fmt(serviceChargeAmount),
                              settings.fontSize - 2,
                            ),
                          const SizedBox(height: 4),
                          _buildReceiptLine(
                            'Total',
                            fmt(totalAmount),
                            settings.fontSize,
                            bold: true,
                          ),
                          const SizedBox(height: 16),
                          if (settings.showThankYouMessage) ...[
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              settings.thankYouMessage,
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 1,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (settings.footerText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              settings.footerText,
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (settings.termsAndConditions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              settings.termsAndConditions,
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 3,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single line in the receipt preview with label and value
  Widget _buildReceiptLine(
    String label,
    String value,
    int fontSize, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize.toDouble() - 1,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize.toDouble() - 1,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
