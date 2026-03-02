part of 'payment_service.dart';

extension PaymentServiceValidation on PaymentService {
  /// Pre-validate that all cart items exist in database before processing payment
  Future<String?> _validateCartItemsExistInDB(List<CartItem> cartItems) async {
    if (cartItems.isEmpty) return null;

    try {
      final db = await DatabaseHelper.instance.database;
      final rawItems = await db.query('items', columns: ['name']);
      final itemNames = {for (final row in rawItems) (row['name'] as String)};

      final unmappedItems = cartItems
          .where((ci) => !itemNames.contains(ci.product.name))
          .map((ci) => ci.product.name)
          .toList();

      if (unmappedItems.isNotEmpty) {
        developer.log('❌ Cart items not found in database: ${unmappedItems.join(', ')}');
        return 'The following items are not in the database: ${unmappedItems.join(", ")}. '
            'Please use products from the database or ensure all items are properly synced.';
      }

      return null;
    } catch (e) {
      developer.log('⚠️ Warning: Could not validate cart items in DB: $e');
      return null;
    }
  }

  /// Calculate change for a given payment
  double calculateChange(double amountPaid, double totalAmount) {
    if (amountPaid < totalAmount) return 0.0;
    return amountPaid - totalAmount;
  }

  /// Validate if payment amount is sufficient
  bool isPaymentValid(double amountPaid, double totalAmount) {
    return amountPaid >= totalAmount;
  }

  /// Get suggested payment amounts (common denominations)
  List<double> getSuggestedAmounts(double totalAmount) {
    final suggestions = <double>[];

    final roundedUp = (totalAmount / 5).ceil() * 5.0;
    suggestions.add(roundedUp);

    final nextTen = (totalAmount / 10).ceil() * 10.0;
    if (nextTen != roundedUp) suggestions.add(nextTen);

    final nextTwenty = (totalAmount / 20).ceil() * 20.0;
    if (nextTwenty != nextTen && nextTwenty != roundedUp) {
      suggestions.add(nextTwenty);
    }

    suggestions.sort();
    return suggestions.where((amount) => amount >= totalAmount).toList();
  }
}
