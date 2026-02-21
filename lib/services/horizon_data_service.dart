import 'dart:convert';
import 'package:appwrite/appwrite.dart';

/// Service for fetching and managing horizon admin data from Appwrite
class HorizonDataService {
  static final HorizonDataService _instance = HorizonDataService._internal();

  late Client _client;
  late Databases _databases;
  late Realtime _realtime;
  
  // Track active subscriptions for cleanup
  final Map<String, RealtimeSubscription> _subscriptions = {};

  factory HorizonDataService() {
    return _instance;
  }

  HorizonDataService._internal();

  /// Initialize the service with Appwrite client
  Future<void> initialize(Client client) async {
    _client = client;
    _databases = Databases(_client);
    _realtime = Realtime(_client);
    print('✅ HorizonDataService initialized with Realtime support');
  }

  // ==================== PRODUCT QUERIES ====================

  /// Get all active products
  /// Optional: filter by category or search term
  Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    String? searchTerm,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queries = [
        Query.equal('is_active', true),
      ];

      if (categoryId != null && categoryId.isNotEmpty) {
        queries.add(Query.equal('category_id', categoryId));
      }

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queries.add(Query.search('name', searchTerm));
      }

      queries.add(Query.limit(limit));
      queries.add(Query.offset(offset));

      final response = await _databases.listDocuments(
        databaseId: 'pos_db',
        collectionId: 'items',
        queries: queries,
      );

      return response.documents
          .map((doc) => doc.data)
          .toList();
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// Get product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: 'pos_db',
        collectionId: 'products',
        documentId: productId,
      );

      return doc.data;
    } catch (e) {
      print('❌ Error fetching product: $e');
      return null;
    }
  }
  /// Delete product by ID
  Future<bool> deleteProduct(String productId) async {
    try {
      await _databases.deleteDocument(
        databaseId: 'pos_db',
        collectionId: 'items',
        documentId: productId,
      );
      print('✅ Product deleted: $productId');
      return true;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return false;
    }
  }
  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String categoryId, {
    int limit = 100,
  }) async {
    return getProducts(categoryId: categoryId, limit: limit);
  }

  // ==================== SALES/TRANSACTION QUERIES ====================

  /// Get sales data for dashboard
  /// Returns transactions for the specified date range
  Future<List<Map<String, dynamic>>> getSalesData({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 500,
  }) async {
    try {
      final queries = <String>[];

      final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      final end = endDate ?? DateTime.now();

      queries.add(Query.greaterThanEqual(
        'transaction_date',
        start.millisecondsSinceEpoch,
      ));
      queries.add(Query.lessThanEqual(
        'transaction_date',
        end.millisecondsSinceEpoch,
      ));
      queries.add(Query.limit(limit));
      queries.add(Query.orderDesc('transaction_date'));

      final response = await _databases.listDocuments(
        databaseId: 'pos_db',
        collectionId: 'transactions',
        queries: queries,
      );

      return response.documents
          .map((doc) => doc.data)
          .toList();
    } catch (e) {
      print('❌ Error fetching sales data: $e');
      return [];
    }
  }

  /// Get today's sales data
  Future<List<Map<String, dynamic>>> getTodaysSales() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    return getSalesData(startDate: today, endDate: tomorrow);
  }

  /// Get sales summary for date range
  /// Returns aggregated totals
  Future<Map<String, dynamic>> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getSalesData(
        startDate: startDate,
        endDate: endDate,
      );

      if (transactions.isEmpty) {
        return {
          'total_sales': 0.0,
          'transaction_count': 0,
          'average_order_value': 0.0,
          'total_items': 0,
        };
      }

      double totalSales = 0;
      double totalTax = 0;
      int transactionCount = transactions.length;

      for (final tx in transactions) {
        totalSales += (tx['total_amount'] ?? 0.0) as double;
        totalTax += (tx['tax_amount'] ?? 0.0) as double;
      }

      return {
        'total_sales': totalSales,
        'total_tax': totalTax,
        'transaction_count': transactionCount,
        'average_order_value': totalSales / transactionCount,
        'net_sales': totalSales - totalTax,
        'total_items': transactions.length,
      };
    } catch (e) {
      print('❌ Error calculating sales summary: $e');
      return {
        'total_sales': 0.0,
        'transaction_count': 0,
        'average_order_value': 0.0,
        'total_items': 0,
      };
    }
  }

  /// Get hourly sales data (for bar chart)
  Future<Map<int, double>> getHourlySalesData({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final transactions = await getSalesData(
        startDate: startOfDay,
        endDate: endOfDay,
        limit: 1000,
      );

      // Group by hour
      final hourlyData = <int, double>{};
      for (int i = 0; i < 24; i++) {
        hourlyData[i] = 0.0;
      }

      for (final tx in transactions) {
        final timestamp = tx['transaction_date'] as int?;
        if (timestamp != null) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final hour = dateTime.hour;
          hourlyData[hour] = (hourlyData[hour] ?? 0.0) + (tx['total_amount'] ?? 0.0);
        }
      }

      return hourlyData;
    } catch (e) {
      print('❌ Error fetching hourly sales: $e');
      return <int, double>{};
    }
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      final transactions = await getSalesData(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      // Parse items and count product sales
      final productSales = <String, Map<String, dynamic>>{};

      for (final tx in transactions) {
        final itemsJson = tx['items_json'] as String?;
        if (itemsJson != null && itemsJson.isNotEmpty) {
          try {
            // Parse the JSON array of items
            final items = jsonDecode(itemsJson) as List<dynamic>;

            for (final item in items) {
              final itemMap = item as Map<String, dynamic>;
              final productId = itemMap['productId'] as String?;
              final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 1;
              final unitPrice = (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0;
              final lineTotal = (itemMap['lineTotal'] as num?)?.toDouble() ?? (unitPrice * quantity);

              if (productId != null && productId.isNotEmpty) {
                if (!productSales.containsKey(productId)) {
                  productSales[productId] = {
                    'productId': productId,
                    'productName': itemMap['productName'] ?? 'Unknown Product',
                    'totalQuantity': 0,
                    'totalRevenue': 0.0,
                    'unitPrice': unitPrice,
                  };
                }

                productSales[productId]!['totalQuantity'] = (productSales[productId]!['totalQuantity'] as int) + quantity;
                productSales[productId]!['totalRevenue'] = (productSales[productId]!['totalRevenue'] as double) + lineTotal;
              }
            }
          } catch (e) {
            print('Error parsing items JSON: $e');
          }
        }
      }

      // Convert to list and sort by total quantity sold
      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int));

      // Take top products and enrich with full product data
      final topProductIds = sortedProducts.take(limit).map((p) => p['productId'] as String).toList();

      if (topProductIds.isEmpty) {
        return [];
      }

      // Get full product details for top sellers
      final allProducts = await getProducts();
      final topProducts = allProducts.where((product) =>
        topProductIds.contains(product['id'] as String?)
      ).toList();

      // Merge sales data with product data
      final enrichedProducts = topProducts.map((product) {
        final salesData = productSales[product['id']];
        if (salesData != null) {
          return {
            ...product,
            'totalQuantity': salesData['totalQuantity'],
            'totalRevenue': salesData['totalRevenue'],
          };
        }
        return product;
      }).toList();

      return enrichedProducts;
    } catch (e) {
      print('❌ Error fetching top products: $e');
      return [];
    }
  }

  /// Get category sales data
  Future<Map<String, double>> getCategorySalesData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getSalesData(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      final categorySales = <String, double>{};

      for (final tx in transactions) {
        final itemsJson = tx['items_json'] as String?;
        if (itemsJson != null && itemsJson.isNotEmpty) {
          try {
            final items = jsonDecode(itemsJson) as List<dynamic>;
            for (final item in items) {
              final itemMap = item as Map<String, dynamic>;
              final categoryId = itemMap['categoryId'] as String?;
              final lineTotal = (itemMap['lineTotal'] as num?)?.toDouble() ?? 0.0;

              if (categoryId != null && categoryId.isNotEmpty) {
                categorySales[categoryId] = (categorySales[categoryId] ?? 0.0) + lineTotal;
              }
            }
          } catch (e) {
            print('Error parsing items JSON for category: $e');
          }
        }
      }

      return categorySales;
    } catch (e) {
      print('❌ Error fetching category sales: $e');
      return <String, double>{};
    }
  }

  /// Get payment method data
  Future<Map<String, double>> getPaymentMethodData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getSalesData(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      final paymentData = <String, double>{};

      for (final tx in transactions) {
        final paymentMethod = tx['payment_method'] as String? ?? 'Unknown';
        final totalAmount = (tx['total_amount'] as num?)?.toDouble() ?? 0.0;

        paymentData[paymentMethod] = (paymentData[paymentMethod] ?? 0.0) + totalAmount;
      }

      return paymentData;
    } catch (e) {
      print('❌ Error fetching payment method data: $e');
      return <String, double>{};
    }
  }

  // ==================== INVENTORY QUERIES ====================

  /// Get all inventory items
  Future<List<Map<String, dynamic>>> getInventory({
    String? stockStatus, // 'low', 'out', 'in_stock'
    int limit = 100,
  }) async {
    try {
      final queries = <String>[];

      if (stockStatus == 'low') {
        // Stock is less than min level
        queries.add(Query.lessThan('current_quantity', 5.0));
      } else if (stockStatus == 'out') {
        queries.add(Query.equal('current_quantity', 0.0));
      }

      queries.add(Query.limit(limit));

      final response = await _databases.listDocuments(
        databaseId: 'pos_db',
        collectionId: 'inventory',
        queries: queries,
      );

      return response.documents
          .map((doc) => doc.data)
          .toList();
    } catch (e) {
      print('❌ Error fetching inventory: $e');
      return [];
    }
  }

  /// Get low stock items
  Future<List<Map<String, dynamic>>> getLowStockItems({int limit = 50}) async {
    return getInventory(stockStatus: 'low', limit: limit);
  }

  /// Get out of stock items
  Future<List<Map<String, dynamic>>> getOutOfStockItems({int limit = 50}) async {
    return getInventory(stockStatus: 'out', limit: limit);
  }

  /// Get inventory by product ID
  Future<Map<String, dynamic>?> getInventoryByProductId(String productId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: 'pos_db',
        collectionId: 'inventory',
        queries: [
          Query.equal('product_id', productId),
        ],
      );

      if (response.documents.isEmpty) return null;

      final doc = response.documents.first;
      return doc.data;
    } catch (e) {
      print('❌ Error fetching inventory: $e');
      return null;
    }
  }

  // ==================== CATEGORY QUERIES ====================

  /// Get all product categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: 'pos_db',
        collectionId: 'categories',
        queries: [Query.limit(100)],
      );

      return response.documents
          .map((doc) => doc.data)
          .toList();
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }

  // ==================== REAL-TIME SUBSCRIPTIONS ====================

  /// Subscribe to product changes
  /// Callback triggered whenever products are added/updated/deleted
  void subscribeToProductChanges(Function(dynamic) onUpdate) {
    try {
      const channel = 'databases.pos_db.collections.items.documents';
      
      // Unsubscribe if already subscribed
      if (_subscriptions.containsKey(channel)) {
        _subscriptions[channel]!.close();
      }
      
      final subscription = _realtime.subscribe([channel]);
      _subscriptions[channel] = subscription;
      
      subscription.stream.listen(
        (response) {
          print('📡 Product update: ${response.events}');
          onUpdate(response);
        },
        onError: (error) {
          print('❌ Product subscription error: $error');
        },
      );
      
      print('✅ Subscribed to product changes');
    } catch (e) {
      print('❌ Error subscribing to products: $e');
    }
  }

  /// Subscribe to transaction changes
  /// Callback triggered on new sales
  void subscribeToTransactionChanges(Function(dynamic) onUpdate) {
    try {
      const channel = 'databases.pos_db.collections.transactions.documents';
      
      // Unsubscribe if already subscribed
      if (_subscriptions.containsKey(channel)) {
        _subscriptions[channel]!.close();
      }
      
      final subscription = _realtime.subscribe([channel]);
      _subscriptions[channel] = subscription;
      
      subscription.stream.listen(
        (response) {
          print('📡 Transaction update: ${response.events}');
          onUpdate(response);
        },
        onError: (error) {
          print('❌ Transaction subscription error: $error');
        },
      );
      
      print('✅ Subscribed to transaction changes');
    } catch (e) {
      print('❌ Error subscribing to transactions: $e');
    }
  }

  /// Subscribe to inventory changes
  void subscribeToInventoryChanges(Function(dynamic) onUpdate) {
    try {
      const channel = 'databases.pos_db.collections.inventory.documents';
      
      // Unsubscribe if already subscribed
      if (_subscriptions.containsKey(channel)) {
        _subscriptions[channel]!.close();
      }
      
      final subscription = _realtime.subscribe([channel]);
      _subscriptions[channel] = subscription;
      
      subscription.stream.listen(
        (response) {
          print('📡 Inventory update: ${response.events}');
          onUpdate(response);
        },
        onError: (error) {
          print('❌ Inventory subscription error: $error');
        },
      );
      
      print('✅ Subscribed to inventory changes');
    } catch (e) {
      print('❌ Error subscribing to inventory: $e');
    }
  }
  
  /// Unsubscribe from all real-time channels
  void unsubscribeAll() {
    for (final subscription in _subscriptions.values) {
      subscription.close();
    }
    _subscriptions.clear();
    print('✅ Unsubscribed from all channels');
  }

  // ==================== CREATE/UPDATE/DELETE OPERATIONS ====================

  /// Create new product
  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      await _databases.createDocument(
        databaseId: 'pos_db',
        collectionId: 'products',
        documentId: ID.unique(),
        data: data,
      );
      print('✅ Product created successfully');
      return true;
    } catch (e) {
      print('❌ Error creating product: $e');
      return false;
    }
  }

  /// Update product
  Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _databases.updateDocument(
        databaseId: 'pos_db',
        collectionId: 'products',
        documentId: productId,
        data: data,
      );
      print('✅ Product updated: $productId');
      return true;
    } catch (e) {
      print('❌ Error updating product: $e');
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      await _databases.deleteDocument(
        databaseId: 'pos_db',
        collectionId: 'products',
        documentId: productId,
      );
      print('✅ Product deleted: $productId');
      return true;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return false;
    }
  }

  /// Update inventory
  Future<bool> updateInventory(String inventoryId, Map<String, dynamic> data) async {
    try {
      await _databases.updateDocument(
        databaseId: 'pos_db',
        collectionId: 'inventory',
        documentId: inventoryId,
        data: data,
      );
      print('✅ Inventory updated: $inventoryId');
      return true;
    } catch (e) {
      print('❌ Error updating inventory: $e');
      return false;
    }
  }

  // ==================== CONVERSION HELPERS ====================

  /// Convert Appwrite document to product model
  static Map<String, dynamic> documentToProduct(Map<String, dynamic> doc) {
    return {
      'id': doc['id'] ?? '',
      'name': doc['name'] ?? 'Unknown',
      'price': (doc['price'] ?? 0.0) as double,
      'category_id': doc['category_id'] ?? '',
      'sku': doc['sku'] ?? '',
      'image_url': doc['image_url'],
      'is_active': doc['is_active'] ?? true,
    };
  }

  /// Convert Appwrite document to transaction model
  static Map<String, dynamic> documentToTransaction(Map<String, dynamic> doc) {
    return {
      'id': doc['id'] ?? '',
      'transaction_number': doc['transaction_number'] ?? '',
      'transaction_date': doc['transaction_date'] ?? 0,
      'total_amount': (doc['total_amount'] ?? 0.0) as double,
      'tax_amount': (doc['tax_amount'] ?? 0.0) as double,
      'items_count': doc['items_count'] ?? 0,
      'payment_method': doc['payment_method'] ?? 'cash',
    };
  }

  /// Convert Appwrite document to inventory model
  static Map<String, dynamic> documentToInventory(Map<String, dynamic> doc) {
    return {
      'id': doc['id'] ?? '',
      'product_id': doc['product_id'] ?? '',
      'current_quantity': (doc['current_quantity'] ?? 0.0) as double,
      'min_stock_level': (doc['min_stock_level'] ?? 0.0) as double,
      'reorder_quantity': (doc['reorder_quantity'] ?? 0.0) as double,
    };
  }
}






