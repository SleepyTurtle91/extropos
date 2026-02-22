import 'package:extropos/models/pos_product.dart';
import 'package:extropos/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Seed sample data for ExtroPOS demonstration
/// Creates products for Retail, Cafe, and Restaurant modes
class POSProductSeeder {
  final ProductRepository _repository;
  final _uuid = const Uuid();

  POSProductSeeder(this._repository);

  Future<void> seedAll() async {
    print('🌱 Seeding POS products...');
    
    await seedRetailProducts();
    await seedCafeProducts();
    await seedRestaurantProducts();
    
    print('✅ Seeding complete!');
  }

  Future<void> seedRetailProducts() async {
    final products = [
      POSProduct(
        id: _uuid.v4(),
        name: 'Wireless Mouse',
        price: 29.99,
        category: 'Electronics',
        mode: 'retail',
        color: Colors.blue,
        description: 'Ergonomic wireless mouse',
        barcode: '8888001',
        stock: 50,
        trackStock: true,
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'USB Cable',
        price: 9.99,
        category: 'Electronics',
        mode: 'retail',
        color: Colors.blue,
        description: 'USB-C to USB-A cable 1m',
        barcode: '8888002',
        stock: 100,
        trackStock: true,
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Notebook A4',
        price: 4.50,
        category: 'Stationery',
        mode: 'retail',
        color: Colors.orange,
        description: '200 pages ruled notebook',
        barcode: '8888003',
        stock: 75,
        trackStock: true,
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Pen Set',
        price: 12.00,
        category: 'Stationery',
        mode: 'retail',
        color: Colors.orange,
        description: 'Pack of 12 ballpoint pens',
        barcode: '8888004',
        stock: 60,
        trackStock: true,
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Water Bottle',
        price: 15.00,
        category: 'Accessories',
        mode: 'retail',
        color: Colors.green,
        description: 'Stainless steel 750ml',
        barcode: '8888005',
        stock: 30,
        trackStock: true,
      ),
    ];

    for (var product in products) {
      await _repository.createProduct(product);
    }
    
    print('✅ Retail products seeded');
  }

  Future<void> seedCafeProducts() async {
    final products = [
      POSProduct(
        id: _uuid.v4(),
        name: 'Espresso',
        price: 4.50,
        category: 'Coffee',
        mode: 'cafe',
        color: Colors.brown,
        description: 'Single shot espresso',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Cappuccino',
        price: 6.50,
        category: 'Coffee',
        mode: 'cafe',
        color: Colors.brown,
        description: 'Classic cappuccino',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Latte',
        price: 6.00,
        category: 'Coffee',
        mode: 'cafe',
        color: Colors.brown,
        description: 'Smooth caffe latte',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Croissant',
        price: 3.50,
        category: 'Pastries',
        mode: 'cafe',
        color: Colors.amber,
        description: 'Butter croissant',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Muffin',
        price: 4.00,
        category: 'Pastries',
        mode: 'cafe',
        color: Colors.amber,
        description: 'Blueberry muffin',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Iced Tea',
        price: 5.00,
        category: 'Beverages',
        mode: 'cafe',
        color: Colors.lightBlue,
        description: 'Lemon iced tea',
      ),
    ];

    for (var product in products) {
      await _repository.createProduct(product);
    }
    
    print('✅ Cafe products seeded');
  }

  Future<void> seedRestaurantProducts() async {
    final products = [
      POSProduct(
        id: _uuid.v4(),
        name: 'Grilled Salmon',
        price: 28.00,
        category: 'Mains',
        mode: 'restaurant',
        color: Colors.pink,
        description: 'Atlantic salmon with vegetables',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Beef Steak',
        price: 35.00,
        category: 'Mains',
        mode: 'restaurant',
        color: Colors.red,
        description: '250g ribeye steak',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Pasta Carbonara',
        price: 18.00,
        category: 'Mains',
        mode: 'restaurant',
        color: Colors.yellow[700],
        description: 'Creamy carbonara pasta',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Caesar Salad',
        price: 12.00,
        category: 'Starters',
        mode: 'restaurant',
        color: Colors.lightGreen,
        description: 'Classic Caesar salad',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Tomato Soup',
        price: 8.00,
        category: 'Starters',
        mode: 'restaurant',
        color: Colors.deepOrange,
        description: 'Fresh tomato soup',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Tiramisu',
        price: 9.00,
        category: 'Desserts',
        mode: 'restaurant',
        color: Colors.brown[300],
        description: 'Italian tiramisu',
      ),
      POSProduct(
        id: _uuid.v4(),
        name: 'Cheesecake',
        price: 8.50,
        category: 'Desserts',
        mode: 'restaurant',
        color: Colors.yellow,
        description: 'New York cheesecake',
      ),
    ];

    for (var product in products) {
      await _repository.createProduct(product);
    }
    
    print('✅ Restaurant products seeded');
  }

  /// Clear all products (useful for testing)
  Future<void> clearAll() async {
    print('🗑️ Clearing all POS products...');
    // Note: Implement if needed using repository methods
    print('⚠️ Clear method not fully implemented');
  }
}
