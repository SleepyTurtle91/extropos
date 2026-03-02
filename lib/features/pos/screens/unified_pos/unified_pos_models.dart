part of 'unified_pos_screen.dart';

enum POSMode { retail, cafe, restaurant }

class Product {
  final String id; // Changed to String for DB compatibility (e.g., Firestore UID)
  final String name;
  final double price;
  final String category;
  final POSMode mode;
  final Color color;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.mode,
    required this.color,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}
