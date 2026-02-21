import 'package:extropos/models/cart_item.dart';
import 'package:flutter/material.dart';

class SplitBillDialog extends StatefulWidget {
  final List<CartItem> cartItems;
  final int tableCapacity;
  const SplitBillDialog({super.key, required this.cartItems, required this.tableCapacity});

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  late List<int> selectedQuantities;
  late List<int?> selectedSeats;

  @override
  void initState() {
    super.initState();
    selectedQuantities = widget.cartItems.map((ci) => 0).toList();
    selectedSeats = widget.cartItems.map((ci) => ci.seatNumber).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = 'RM';

    double getSplitSubtotal() {
      double sum = 0.0;
      for (int i = 0; i < widget.cartItems.length; i++) {
        final ci = widget.cartItems[i];
        sum += ci.finalPrice * selectedQuantities[i];
      }
      return sum;
    }

    return AlertDialog(
      title: const Text('Split Bill — Select items to move'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          // Limit height so dialog stays usable on short screens
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use a non-viewport scrollable to avoid intrinsic viewport measurements
            // which can produce RenderShrinkWrappingViewport errors during tests.
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(widget.cartItems.length, (index) {
                    final ci = widget.cartItems[index];
                    return ListTile(
                      title: Text(ci.product.name),
                      subtitle: Text('x${ci.quantity} • @ ${ci.finalPrice.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: selectedQuantities[index] > 0
                                ? () => setState(() => selectedQuantities[index]--)
                                : null,
                          ),
                          Text('${selectedQuantities[index]}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: selectedQuantities[index] < ci.quantity
                                ? () => setState(() => selectedQuantities[index]++)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          // Seat assignment for split line
                          Material(
                            color: Colors.transparent,
                            child: DropdownButton<int?>(
                              value: selectedSeats[index],
                              hint: const Text('Seat'),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                                ...List.generate(widget.tableCapacity, (i) => i + 1).map(
                                  (s) => DropdownMenuItem<int?>(value: s, child: Text('Seat $s')),
                                )
                              ],
                              onChanged: selectedQuantities[index] > 0
                                  ? (v) => setState(() => selectedSeats[index] = v)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Split subtotal:'),
                Text('$currency ${getSplitSubtotal().toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            // Build list of split items and map original indices so we can
            // attach seat numbers deterministically
            final selected = <CartItem>[];
            final selectedOrigIndices = <int>[];
            for (int i = 0; i < widget.cartItems.length; i++) {
              final qty = selectedQuantities[i];
              if (qty > 0) {
                final ci = widget.cartItems[i];
                selected.add(
                  CartItem(ci.product, qty, modifiers: ci.modifiers, priceAdjustment: ci.priceAdjustment, discountPerUnit: ci.discountPerUnit),
                );
                selectedOrigIndices.add(i);
              }
            }
            // Attach seat numbers using the corresponding original indices
            for (int k = 0; k < selected.length; k++) {
              final origIndex = selectedOrigIndices[k];
              selected[k].seatNumber = selectedSeats[origIndex];
            }
            Navigator.of(context).pop(selected);
          },
          child: const Text('Split & Pay'),
        ),
      ],
    );
  }
}
