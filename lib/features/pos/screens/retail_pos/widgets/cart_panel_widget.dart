import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:flutter/material.dart';

class CartPanelWidget extends StatelessWidget {
  final List<CartItem> cartItems;
  final double subtotal;
  final double taxAmount;
  final double serviceChargeAmount;
  final double billDiscount;
  final String currencySymbol;
  final Function(CartItem, int) onQuantityChanged;
  final VoidCallback onCheckout;

  const CartPanelWidget({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceChargeAmount,
    required this.billDiscount,
    this.currencySymbol = 'RM',
    required this.onQuantityChanged,
    required this.onCheckout,
  });

  double get total =>
      (subtotal - billDiscount < 0 ? 0.0 : subtotal - billDiscount) +
      taxAmount +
      serviceChargeAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: const Text(
              'Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Cart items
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('No items in cart'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                          '$currencySymbol ${item.product.price.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  onQuantityChanged(item, item.quantity - 1),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  onQuantityChanged(item, item.quantity + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Cart total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('$currencySymbol ${subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                if (BusinessInfo.instance.isTaxEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax (${BusinessInfo.instance.taxRatePercentage}):'),
                      Text('$currencySymbol ${taxAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                if (BusinessInfo.instance.isServiceChargeEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Charge (${BusinessInfo.instance.serviceChargeRatePercentage}):',
                      ),
                      Text(
                        '$currencySymbol ${serviceChargeAmount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ],
                if (billDiscount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bill Discount:'),
                      Text('-$currencySymbol ${billDiscount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$currencySymbol ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : onCheckout,
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
