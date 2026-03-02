import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:flutter/material.dart';

/// Displays payment breakdown with subtotal, tax, service charge, and total
class PaymentBreakdownWidget extends StatelessWidget {
  final List<CartItem> cartItems;
  final double billDiscount;
  final String currencySymbol;

  const PaymentBreakdownWidget({
    super.key,
    required this.cartItems,
    required this.billDiscount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final items = cartItems;
    final subtotal = Pricing.subtotal(items);
    final info = BusinessInfo.instance;
    final discount = billDiscount;
    final tax = Pricing.taxAmountWithDiscount(items, discount);
    final service = Pricing.serviceChargeAmountWithDiscount(items, discount);
    final total = Pricing.totalWithDiscount(items, discount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text(
                      '$currencySymbol ${subtotal.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (discount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount'),
                      Text(
                        '-$currencySymbol ${discount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (info.isTaxEnabled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax (${info.taxRatePercentage})'),
                      Text(
                        '$currencySymbol ${tax.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (info.isServiceChargeEnabled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Charge (${info.serviceChargeRatePercentage})',
                      ),
                      Text(
                        '$currencySymbol ${service.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$currencySymbol ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
