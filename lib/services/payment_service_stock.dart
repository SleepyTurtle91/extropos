part of 'payment_service.dart';

extension PaymentServiceStock on PaymentService {
  /// Deduct stock for sold items
  Future<void> _deductStockForItems(List<CartItem> cartItems) async {
    try {
      for (final cartItem in cartItems) {
        final items = await DatabaseService.instance.getItems();
        Item? matchingItem;
        try {
          matchingItem = items.firstWhere(
            (item) => item.name == cartItem.product.name,
          );
        } catch (e) {
          matchingItem = null;
        }

        if (matchingItem != null &&
            matchingItem.trackStock &&
            matchingItem.stock > 0) {
          final newStock = matchingItem.stock - cartItem.quantity;
          if (newStock >= 0) {
            final updatedItem = matchingItem.copyWith(stock: newStock);
            await DatabaseService.instance.updateItem(updatedItem);
            developer.log(
              'Deducted ${cartItem.quantity} from ${matchingItem.name} stock. New stock: $newStock',
            );
          } else {
            developer.log(
              'Warning: Insufficient stock for ${matchingItem.name}. Current: ${matchingItem.stock}, Required: ${cartItem.quantity}',
            );
          }
        }
      }
    } catch (e) {
      developer.log('Error deducting stock: $e');
    }
  }
}
