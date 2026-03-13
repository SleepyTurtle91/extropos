part of '../database_service.dart';

extension DatabaseServiceInventory on DatabaseService {
  /// Save an inventory item
  Future<void> saveInventoryItem(inv_model.InventoryItem item) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'inventory',
      {
        'id': item.id,
        'product_id': item.productId,
        'product_name': item.productName,
        'current_quantity': item.currentQuantity,
        'min_stock_level': item.minStockLevel,
        'max_stock_level': item.maxStockLevel,
        'reorder_quantity': item.reorderQuantity,
        'cost_per_unit': item.costPerUnit,
        'unit': item.unit,
        'last_stock_count_date': item.lastStockCountDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all inventory items
  Future<List<inv_model.InventoryItem>> getInventory() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('inventory');
    
    final List<inv_model.InventoryItem> items = [];
    for (final map in maps) {
      final productId = map['product_id'] as String;
      final movements = await getStockMovements(productId);
      
      items.add(inv_model.InventoryItem(
        id: map['id'] as String,
        productId: productId,
        productName: map['product_name'] as String,
        currentQuantity: (map['current_quantity'] as num).toDouble(),
        minStockLevel: (map['min_stock_level'] as num).toDouble(),
        maxStockLevel: (map['max_stock_level'] as num).toDouble(),
        reorderQuantity: (map['reorder_quantity'] as num).toDouble(),
        costPerUnit: (map['cost_per_unit'] as num?)?.toDouble(),
        unit: map['unit'] as String? ?? 'pcs',
        lastStockCountDate: map['last_stock_count_date'] != null 
            ? DateTime.parse(map['last_stock_count_date'] as String) 
            : null,
        movements: movements,
      ));
    }
    return items;
  }

  /// Save a stock movement
  Future<void> saveStockMovement(inv_model.StockMovement movement, String productId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('stock_movements', {
      'id': movement.id,
      'product_id': productId,
      'type': movement.type,
      'quantity': movement.quantity,
      'reason': movement.reason,
      'date': movement.date.toIso8601String(),
      'user_id': movement.userId,
      'reference_id': movement.referenceId,
    });
  }

  /// Get stock movements for a product
  Future<List<inv_model.StockMovement>> getStockMovements(String productId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );

    return maps.map((m) => inv_model.StockMovement(
      id: m['id'] as String,
      type: m['type'] as String,
      quantity: (m['quantity'] as num).toDouble(),
      reason: m['reason'] as String,
      date: DateTime.parse(m['date'] as String),
      userId: m['user_id'] as String?,
      referenceId: m['reference_id'] as String?,
    )).toList();
  }

  /// Save a supplier
  Future<void> saveSupplier(inv_model.Supplier supplier) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'suppliers',
      {
        'id': supplier.id,
        'name': supplier.name,
        'contact_person': supplier.contactPerson,
        'phone': supplier.phone,
        'email': supplier.email,
        'address': supplier.address,
        'tax_number': supplier.taxNumber,
        'is_active': supplier.isActive ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all suppliers
  Future<List<inv_model.Supplier>> getSuppliers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('suppliers');
    return maps.map((m) => inv_model.Supplier(
      id: m['id'] as String,
      name: m['name'] as String,
      contactPerson: m['contact_person'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      email: m['email'] as String? ?? '',
      address: m['address'] as String? ?? '',
      taxNumber: m['tax_number'] as String?,
      isActive: (m['is_active'] as int?) == 1,
    )).toList();
  }

  /// Save a purchase order
  Future<void> savePurchaseOrder(inv_model.PurchaseOrder po) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'purchase_orders',
        {
          'id': po.id,
          'po_number': po.poNumber,
          'supplier_id': po.supplierId,
          'supplier_name': po.supplierName,
          'total_amount': po.totalAmount,
          'status': po.status.name,
          'order_date': po.orderDate.toIso8601String(),
          'expected_delivery_date': po.expectedDeliveryDate?.toIso8601String(),
          'received_date': po.receivedDate?.toIso8601String(),
          'notes': po.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save PO items
      for (final item in po.items) {
        await txn.insert(
          'purchase_order_items',
          {
            'purchase_order_id': po.id,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_cost': item.unitCost,
            'total_cost': item.totalCost,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get all purchase orders
  Future<List<inv_model.PurchaseOrder>> getPurchaseOrders() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> poMaps = await db.query('purchase_orders', orderBy: 'order_date DESC');
    
    final List<inv_model.PurchaseOrder> orders = [];
    for (final poMap in poMaps) {
      final poId = poMap['id'] as String;
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'purchase_order_items',
        where: 'purchase_order_id = ?',
        whereArgs: [poId],
      );

      final items = itemMaps.map((m) => inv_model.PurchaseOrderItem(
        productId: m['product_id'] as String,
        productName: m['product_name'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unitCost: (m['unit_cost'] as num).toDouble(),
        totalCost: (m['total_cost'] as num).toDouble(),
      )).toList();

      orders.add(inv_model.PurchaseOrder(
        id: poId,
        poNumber: poMap['po_number'] as String,
        supplierId: poMap['supplier_id'] as String,
        supplierName: poMap['supplier_name'] as String,
        items: items,
        totalAmount: (poMap['total_amount'] as num).toDouble(),
        status: inv_model.PurchaseOrderStatus.values.firstWhere(
          (s) => s.name == poMap['status'],
          orElse: () => inv_model.PurchaseOrderStatus.draft,
        ),
        orderDate: DateTime.parse(poMap['order_date'] as String),
        expectedDeliveryDate: poMap['expected_delivery_date'] != null 
            ? DateTime.parse(poMap['expected_delivery_date'] as String) 
            : null,
        receivedDate: poMap['received_date'] != null 
            ? DateTime.parse(poMap['received_date'] as String) 
            : null,
        notes: poMap['notes'] as String?,
      ));
    }
    return orders;
  }
}
