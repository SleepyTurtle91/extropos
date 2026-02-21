import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get lineTotal => (product.price) * quantity;
}

class CartPanel extends StatelessWidget {
  final List<CartItem> items;
  final void Function(CartItem, int) onQtyChange;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  const CartPanel({
    super.key,
    required this.items,
    required this.onQtyChange,
    required this.onClear,
    required this.onCheckout,
  });

  double get subtotal => items.fold(0.0, (s, it) => s + it.lineTotal);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cart', style: Theme.of(context).textTheme.titleLarge),
              TextButton(onPressed: onClear, child: Text('Clear'))
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('Cart is empty'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ci = items[index];
                      return ListTile(
                        title: Text(ci.product.name),
                        subtitle: Text('${ci.quantity} x RM${ci.product.price.toStringAsFixed(2)}'),
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(onPressed: () => onQtyChange(ci, ci.quantity - 1), icon: Icon(Icons.remove)),
                              Text('${ci.quantity}'),
                              IconButton(onPressed: () => onQtyChange(ci, ci.quantity + 1), icon: Icon(Icons.add)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Subtotal'), Text('RM${subtotal.toStringAsFixed(2)}')],
                ),
                SizedBox(height: 8),
                ElevatedButton(onPressed: onCheckout, child: Text('Take Payment')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
