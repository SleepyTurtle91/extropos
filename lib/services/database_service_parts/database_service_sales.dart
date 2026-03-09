part of '../database_service.dart';

extension DatabaseServiceSales on DatabaseService {
  Future<String?> saveCompletedSale({
    required List<CartItem> cartItems,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
    String orderType = 'retail',
    String? tableId,
    int? cafeOrderNumber,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? specialInstructions,
    double discount = 0.0,
    String? merchantId,
    String status = 'completed',
  }) async {
    try {
      if (cartItems.isEmpty) return null;

      final db = await DatabaseHelper.instance.database;

      final rawItems = await db.query('items', columns: ['id', 'name', 'price']);
      final Map<String, Map<String, Object?>> itemByName = {
        for (final row in rawItems) (row['name'] as String): row,
      };

      final unmapped = cartItems
          .where((ci) => !itemByName.containsKey(ci.product.name))
          .toList();
      if (unmapped.isNotEmpty) {
        return null;
      }

      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final uuid = const Uuid();
      final generatedOrderNumber = _generateOrderNumber(
        orderType: orderType,
        cafeOrderNumber: cafeOrderNumber,
      );
      final resolvedUserId = userId ?? '1';

      final activeShift = await ShiftService.instance.getCurrentShift(
        resolvedUserId,
      );
      final shiftId = activeShift?.id;

      await db.transaction((txn) async {
        final orderId = uuid.v4();

        await txn.insert('orders', {
          'id': orderId,
          'order_number': generatedOrderNumber,
          'table_id': tableId,
          'user_id': resolvedUserId,
          'shift_id': shiftId,
          'status': status,
          'order_type': orderType,
          'subtotal': subtotal,
          'tax': tax,
          'discount': discount,
          'merchant_id': merchantId,
          'total': total,
          'payment_method_id': paymentMethod.id,
          'notes': notes,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_email': customerEmail,
          'special_instructions': specialInstructions,
          'created_at': nowIso,
          'updated_at': nowIso,
          'completed_at': nowIso,
        });

        for (final ci in cartItems) {
          final dbItem = itemByName[ci.product.name]!;
          final itemId = dbItem['id'] as String;

          final mods = ci.modifiers
              .map(
                (m) => {
                  'id': m.id,
                  'groupId': m.modifierGroupId,
                  'name': m.name,
                  'priceAdjustment': m.priceAdjustment,
                },
              )
              .toList();
          final notes = mods.isEmpty ? null : jsonEncode({'modifiers': mods});

          await txn.insert('order_items', {
            'id': uuid.v4(),
            'order_id': orderId,
            'item_id': itemId,
            'item_name': ci.product.name,
            'item_price': ci.finalPrice,
            'quantity': ci.quantity,
            'subtotal': ci.totalPrice,
            'seat_number': ci.seatNumber,
            'notes': notes,
            'created_at': nowIso,
          });
        }

        await txn.insert('transactions', {
          'id': uuid.v4(),
          'order_id': orderId,
          'payment_method_id': paymentMethod.id,
          'amount': total,
          'change_amount': change,
          'transaction_date': nowIso,
          'receipt_number': generatedOrderNumber,
          'created_at': nowIso,
        });
      });

      try {
        await OfflineSyncService().queueTransaction({
          'receipt_number': generatedOrderNumber,
          'order_type': orderType,
          'status': status,
          'subtotal': subtotal,
          'tax': tax,
          'service_charge': serviceCharge,
          'discount': discount,
          'total': total,
          'payment_method_id': paymentMethod.id,
          'amount_paid': amountPaid,
          'change': change,
          'table_id': tableId,
          'user_id': resolvedUserId,
          'created_at': nowIso,
          'items': cartItems.map((item) => item.toJson()).toList(),
        });
      } catch (queueError) {
        developer.log(
          'Failed to queue offline sync transaction: $queueError',
          name: 'database_service',
        );
      }

      return generatedOrderNumber;
    } catch (e, stackTrace) {
      developer.log('Database error in saveCompletedSale: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.high,
        category: ErrorCategory.database,
        message: 'Failed to save completed sale to database',
      );
      return null;
    }
  }

  Future<String?> saveCompletedSaleWithSplits({
    required List<CartItem> cartItems,
    required List<PaymentSplit> paymentSplits,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required double amountPaid,
    required double change,
    String orderType = 'retail',
    String? tableId,
    int? cafeOrderNumber,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? specialInstructions,
    double discount = 0.0,
    String? merchantId,
    String status = 'completed',
  }) async {
    if (cartItems.isEmpty || paymentSplits.isEmpty) return null;

    final db = await DatabaseHelper.instance.database;

    final rawItems = await db.query('items', columns: ['id', 'name', 'price']);
    final Map<String, Map<String, Object?>> itemByName = {
      for (final row in rawItems) (row['name'] as String): row,
    };

    final unmapped = cartItems
        .where((ci) => !itemByName.containsKey(ci.product.name))
        .toList();
    if (unmapped.isNotEmpty) {
      final unmappedNames = unmapped.map((ci) => ci.product.name).toList();
      final availableNames = itemByName.keys.toList();
      developer.log(
        '❌ Cart items not found in database:\n'
        'Unmapped items: $unmappedNames\n'
        'Available items in DB: $availableNames',
        name: 'database_service',
      );
      return null;
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final uuid = const Uuid();
    final generatedOrderNumber = _generateOrderNumber(
      orderType: orderType,
      cafeOrderNumber: cafeOrderNumber,
    );
    final resolvedUserId = userId ?? '1';

    final activeShift = await ShiftService.instance.getCurrentShift(
      resolvedUserId,
    );
    final shiftId = activeShift?.id;

    await db.transaction((txn) async {
      final orderId = uuid.v4();

      await txn.insert('orders', {
        'id': orderId,
        'order_number': generatedOrderNumber,
        'table_id': tableId,
        'user_id': resolvedUserId,
        'shift_id': shiftId,
        'status': status,
        'order_type': orderType,
        'subtotal': subtotal,
        'tax': tax,
        'discount': discount,
        'merchant_id': merchantId,
        'total': total,
        'service_charge': serviceCharge,
        'created_at': nowIso,
        'updated_at': nowIso,
      });

      for (final ci in cartItems) {
        final itemId = uuid.v4();
        final itemRow = itemByName[ci.product.name]!;
        await txn.insert('order_items', {
          'id': itemId,
          'order_id': orderId,
          'item_id': itemRow['id'] as String,
          'item_name': ci.product.name,
          'item_price': ci.finalPrice,
          'quantity': ci.quantity,
          'subtotal': ci.totalPrice,
          'seat_number': ci.seatNumber,
          'notes': notes,
          'created_at': nowIso,
        });
      }

      final transactionId = uuid.v4();
      await txn.insert('transactions', {
        'id': transactionId,
        'order_id': orderId,
        'payment_method_id': paymentSplits.first.paymentMethod.id,
        'amount': amountPaid,
        'change_amount': change,
        'transaction_date': nowIso,
        'receipt_number': generatedOrderNumber,
        'created_at': nowIso,
      });

      for (final split in paymentSplits) {
        await txn.insert('payment_splits', {
          'id': uuid.v4(),
          'transaction_id': transactionId,
          'payment_method_id': split.paymentMethod.id,
          'amount': split.amount,
          'reference': split.reference,
          'created_at': nowIso,
        });
      }
    });

    try {
      await OfflineSyncService().queueTransaction({
        'receipt_number': generatedOrderNumber,
        'order_type': orderType,
        'status': status,
        'subtotal': subtotal,
        'tax': tax,
        'service_charge': serviceCharge,
        'discount': discount,
        'total': total,
        'amount_paid': amountPaid,
        'change': change,
        'table_id': tableId,
        'user_id': resolvedUserId,
        'created_at': nowIso,
        'payment_splits': paymentSplits
            .map(
              (split) => {
                'payment_method_id': split.paymentMethod.id,
                'amount': split.amount,
                'reference': split.reference,
              },
            )
            .toList(),
        'items': cartItems.map((item) => item.toJson()).toList(),
      });
    } catch (queueError) {
      developer.log(
        'Failed to queue offline split transaction: $queueError',
        name: 'database_service',
      );
    }

    return generatedOrderNumber;
  }

  Future<bool> voidOrder(
    String orderId, {
    String? reason,
    String? userId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        'orders',
        {
          'status': 'voided',
          'notes': reason ?? 'Order voided',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );

      return true;
    } catch (e) {
      debugPrint('Error voiding order: $e');
      return false;
    }
  }

  Future<bool> refundOrder({
    required String orderId,
    required double refundAmount,
    required String paymentMethodId,
    String? reason,
    String? userId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      final uuid = const Uuid();

      await db.transaction((txn) async {
        await txn.update(
          'orders',
          {
            'status': 'refunded',
            'notes': reason ?? 'Order refunded',
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );

        await txn.insert('transactions', {
          'id': uuid.v4(),
          'order_id': orderId,
          'payment_method_id': paymentMethodId,
          'amount': -refundAmount,
          'change_amount': 0.0,
          'transaction_date': now,
          'receipt_number': 'REFUND-${uuid.v4().substring(0, 8).toUpperCase()}',
          'created_at': now,
        });
      });

      return true;
    } catch (e) {
      debugPrint('Error refunding order: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 50}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'orders',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return maps;
    } catch (e, stackTrace) {
      developer.log('Database error in getRecentOrders: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.medium,
        category: ErrorCategory.database,
        message: 'Failed to load recent orders from database',
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOrders({
    DateTime? from,
    DateTime? to,
    String? paymentMethodId,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (from != null) {
        whereClauses.add('created_at >= ?');
        whereArgs.add(from.toIso8601String());
      }
      if (to != null) {
        whereClauses.add('created_at <= ?');
        whereArgs.add(to.toIso8601String());
      }
      if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
        whereClauses.add('payment_method_id = ?');
        whereArgs.add(paymentMethodId);
      }

      final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

      final List<Map<String, dynamic>> maps = await db.query(
        'orders',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return maps;
    } catch (e, stackTrace) {
      developer.log('Database error in getOrders: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.medium,
        category: ErrorCategory.database,
        message: 'Failed to load orders from database',
      );
      return [];
    }
  }

  Future<String> exportOrdersCsv({
    DateTime? from,
    DateTime? to,
    String? paymentMethodId,
    int limit = 100000,
  }) async {
    final orders = await getOrders(
      from: from,
      to: to,
      paymentMethodId: paymentMethodId,
      offset: 0,
      limit: limit,
    );
    final sb = StringBuffer();
    final now = DateTime.now().toIso8601String();
    final bizName = BusinessInfo.instance.businessName;
    final bizAddress = BusinessInfo.instance.fullAddress;
    final taxNumber = BusinessInfo.instance.taxNumber ?? '';

    sb.writeln('meta_key,meta_value');
    sb.writeln('generated_at,${_escapeCsv(now)}');
    sb.writeln('business_name,${_escapeCsv(bizName)}');
    sb.writeln('business_address,${_escapeCsv(bizAddress)}');
    sb.writeln('tax_number,${_escapeCsv(taxNumber)}');
    sb.writeln(
      'opening_time,${_escapeCsv(BusinessInfo.instance.openingTimeToday)}',
    );
    sb.writeln(
      'closing_time,${_escapeCsv(BusinessInfo.instance.closingTimeToday)}',
    );
    sb.writeln();
    sb.writeln(
      'order_number,created_at,total,payment_method_id,merchant_id,merchant_name,table_id,user_id,status,item_id,item_name,quantity,item_price,item_subtotal,seat,notes',
    );

    for (final o in orders) {
      final orderId = o['id'].toString();
      final orderNumber = (o['order_number'] ?? '').toString();
      final createdAt = (o['created_at'] ?? '').toString();
      final total = ((o['total'] as num?)?.toDouble() ?? 0.0)
          .toStringAsFixed(2);
      final paymentMethod = (o['payment_method_id'] ?? '').toString();
      final merchantId = (o['merchant_id'] ?? '').toString();
      final merchantName = MerchantHelper.displayName(merchantId);
      final tableId = (o['table_id'] ?? '').toString();
      final userId = (o['user_id'] ?? '').toString();
      final status = (o['status'] ?? '').toString();

      final items = await getOrderItems(orderId);
      if (items.isEmpty) {
        sb.writeln(
          '${_escapeCsv(orderNumber)},${_escapeCsv(createdAt)},$total,${_escapeCsv(paymentMethod)},${_escapeCsv(merchantId)},${_escapeCsv(merchantName)},${_escapeCsv(tableId)},${_escapeCsv(userId)},${_escapeCsv(status)},,,0,0.00,,',
        );
        continue;
      }

      for (final it in items) {
        final itemId = (it['item_id'] ?? '').toString();
        final itemName = (it['item_name'] ?? '').toString();
        final qty = (it['quantity'] as num?)?.toInt() ?? 0;
        final itemPrice = ((it['item_price'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(2);
        final itemSubtotal = ((it['subtotal'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(2);
        final notes = (it['notes'] ?? '').toString();

        final seat = (it['seat_number'] as int?)?.toString() ?? '';
        sb.writeln(
          '${_escapeCsv(orderNumber)},${_escapeCsv(createdAt)},$total,${_escapeCsv(paymentMethod)},${_escapeCsv(merchantId)},${_escapeCsv(merchantName)},${_escapeCsv(tableId)},${_escapeCsv(userId)},${_escapeCsv(status)},${_escapeCsv(itemId)},${_escapeCsv(itemName)},$qty,$itemPrice,$itemSubtotal,${_escapeCsv(seat)},${_escapeCsv(notes)}',
        );
      }
    }

    return sb.toString();
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at ASC',
    );
    return maps;
  }

  Future<List<CartItem>> getOrderItemsAsCartItems(String orderId) async {
    final itemMaps = await getOrderItems(orderId);
    final cartItems = <CartItem>[];

    for (final map in itemMaps) {
      final product = Product(
        map['item_name'] as String,
        (map['item_price'] as num).toDouble(),
        '',
        Icons.shopping_cart,
        id: map['item_id'] as String,
      );

      List<ModifierItem> modifiers = [];
      if (map['notes'] != null && (map['notes'] as String).isNotEmpty) {
        try {
          final notesData = json.decode(map['notes'] as String);
          if (notesData is Map && notesData['modifiers'] is List) {
            modifiers = (notesData['modifiers'] as List)
                .map(
                  (m) => ModifierItem(
                    id: m['id'] as String? ?? '',
                    modifierGroupId: m['groupId'] as String? ?? '',
                    name: m['name'] as String,
                    priceAdjustment:
                        (m['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
                  ),
                )
                .toList();
          }
        } catch (e) {
          // Ignore JSON parse errors
        }
      }

      cartItems.add(
        CartItem(
          product,
          ((map['quantity'] as num?)?.toInt() ?? 0),
          modifiers: modifiers,
          seatNumber: (map['seat_number'] as num?)?.toInt(),
        ),
      );
    }

    return cartItems;
  }

  Future<List<Map<String, dynamic>>> getTransactionsForOrder(
    String orderId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'transaction_date DESC',
    );
    return maps;
  }

  Future<Map<String, dynamic>?> getOrderByNumber(String orderNumber) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'orders',
      where: 'order_number = ?',
      whereArgs: [orderNumber],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final order = Map<String, dynamic>.from(result.first);
    final items = await getOrderItems(order['id'].toString());
    order['item_count'] = items.length;

    return order;
  }

  Future<List<Map<String, dynamic>>> getOrdersByCustomerPhone(
    String phone,
    DateTimeRange dateRange,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'orders',
      where: 'customer_phone = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        phone,
        dateRange.start.toIso8601String(),
        dateRange.end.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );

    final orders = <Map<String, dynamic>>[];
    for (final result in results) {
      final order = Map<String, dynamic>.from(result);
      final items = await getOrderItems(order['id'].toString());
      order['item_count'] = items.length;
      orders.add(order);
    }

    return orders;
  }

  Future<List<Map<String, dynamic>>> getOrdersInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'orders',
        where: 'created_at >= ? AND created_at <= ? AND status != ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String(), 'cancelled'],
        orderBy: 'created_at DESC',
        limit: 100,
      );

      final orders = <Map<String, dynamic>>[];
      for (final result in results) {
        final order = Map<String, dynamic>.from(result);
        final items = await getOrderItems(order['id'].toString());
        order['item_count'] = items.length;
        orders.add(order);
      }

      return orders;
    } catch (e, stackTrace) {
      developer.log(
        'Database error in getOrdersInDateRange: $e',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.medium,
        category: ErrorCategory.database,
        message: 'Failed to load orders in date range from database',
      );
      return [];
    }
  }
}
