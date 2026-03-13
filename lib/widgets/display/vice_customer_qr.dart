import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Layer B widget: customer-facing DuitNow QR presentation.
///
/// This widget is display-only and receives all data via constructor params.
class ViceCustomerQR extends StatelessWidget {
  final String qrData;
  final double totalAmount;
  final String currencySymbol;
  final String title;
  final String subtitle;
  final String? reference;

  const ViceCustomerQR({
    super.key,
    required this.qrData,
    required this.totalAmount,
    required this.currencySymbol,
    this.title = 'Scan to Pay',
    this.subtitle = 'DuitNow QR',
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final qrSize = (shortestSide * 0.55).clamp(180.0, 340.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$currencySymbol ${totalAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((reference ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ref: ${reference!.trim()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        );
      },
    );
  }
}
