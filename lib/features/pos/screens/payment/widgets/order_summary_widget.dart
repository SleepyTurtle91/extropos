import 'package:extropos/models/cart_item.dart';
import 'package:flutter/material.dart';

/// Displays a summary of cart items with pricing information
class OrderSummaryWidget extends StatelessWidget {
  final List<CartItem> cartItems;
  final String currencySymbol;

  const OrderSummaryWidget({
    super.key,
    required this.cartItems,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...cartItems.map((ci) {
                  final unit = ci.finalPrice; // includes modifiers
                  final lineTotal = ci.totalPrice;
                  final mods = ci.modifiers;
                  final hasMods = mods.isNotEmpty;
                  final modsText = hasMods
                      ? mods
                          .map(
                            (m) => m.priceAdjustment == 0
                                ? m.name
                                : '${m.name} (${m.getPriceAdjustmentDisplay()})',
                          )
                          .join(', ')
                      : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      ci.seatNumber != null
                                          ? '${ci.product.name} (Seat ${ci.seatNumber})'
                                          : ci.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'x${ci.quantity}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasMods) ...[
                                const SizedBox(height: 4),
                                Text(
                                  modsText,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$currencySymbol ${lineTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '@ $currencySymbol ${unit.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
