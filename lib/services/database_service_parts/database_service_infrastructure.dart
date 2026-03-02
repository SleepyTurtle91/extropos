part of '../database_service.dart';

/// Infrastructure domain: Printers, Customer Displays, Receipt Settings, Tables, Kitchen Display System
extension DatabaseServiceInfrastructure on DatabaseService {
  // ==================== PRINTERS ====================

  Future<List<Printer>> getPrinters() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'printers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'is_default DESC, name ASC',
    );

    return maps.map((map) => _printerFromDb(map)).toList();
  }

  Future<Printer?> getPrinterById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'printers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _printerFromDb(maps[0]);
  }

  Future<Printer?> getDefaultPrinter() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'printers',
      where: 'is_default = ? AND is_active = ?',
      whereArgs: [1, 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _printerFromDb(maps[0]);
  }

  Future<void> savePrinter(Printer printer) async {
    developer.log(
      'DatabaseService.savePrinter: Starting for printer ${printer.id} (${printer.name})',
    );

    final db = await DatabaseHelper.instance.database;
    developer.log('DatabaseService.savePrinter: Database connection obtained');

    if (printer.isDefault) {
      developer.log('DatabaseService.savePrinter: Clearing other defaults');
      await db.update('printers', {
        'is_default': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    developer.log('DatabaseService.savePrinter: Checking if printer exists');
    final existing = await db.query(
      'printers',
      where: 'id = ?',
      whereArgs: [printer.id],
      limit: 1,
    );
    developer.log(
      'DatabaseService.savePrinter: Existing records: ${existing.length}',
    );

    final tableInfo = await db.rawQuery('PRAGMA table_info(printers)');
    final columnNames = tableInfo.map((col) => col['name'] as String).toSet();
    final hasPaperSize = columnNames.contains('paper_size');
    final hasStatus = columnNames.contains('status');
    final hasPermission = columnNames.contains('has_permission');
    final hasCategories = columnNames.contains('categories');

    developer.log('DatabaseService.savePrinter: Table columns: $columnNames');

    final data = <String, dynamic>{
      'id': printer.id,
      'name': printer.name,
      'type': printer.type.name,
      'connection_type': printer.connectionType.name,
      'ip_address': printer.ipAddress,
      'port': printer.port,
      'device_id':
          printer.usbDeviceId ??
          printer.bluetoothAddress ??
          printer.platformSpecificId,
      'device_name': printer.modelName,
      'is_default': printer.isDefault ? 1 : 0,
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (hasPaperSize) {
      data['paper_size'] = printer.paperSize?.name;
    }
    if (hasStatus) {
      data['status'] = printer.status.name;
    }
    if (hasPermission) {
      data['has_permission'] = printer.hasPermission ? 1 : 0;
    }
    if (hasCategories) {
      data['categories'] = jsonEncode(printer.categories);
    }

    developer.log('DatabaseService.savePrinter: Prepared data: $data');

    try {
      if (existing.isNotEmpty) {
        developer.log('DatabaseService.savePrinter: Updating existing printer');
        final result = await db.update(
          'printers',
          data,
          where: 'id = ?',
          whereArgs: [printer.id],
        );
        developer.log(
          'Database: Updated printer ${printer.id}, result: $result',
        );
      } else {
        developer.log('DatabaseService.savePrinter: Inserting new printer');
        data['created_at'] = DateTime.now().toIso8601String();
        final result = await db.insert('printers', data);
        developer.log(
          'Database: Inserted printer ${printer.id}, result: $result',
        );
      }
      developer.log('Database: Printer data saved successfully');
    } catch (e, stackTrace) {
      developer.log('Database: ERROR saving printer ${printer.id}: $e');
      developer.log('Database: Stack trace: $stackTrace');
      developer.log('Database: Printer data that failed: $data');
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('A printer with this ID already exists');
      } else if (e.toString().contains('NOT NULL constraint failed')) {
        throw Exception('Required printer information is missing');
      } else if (e.toString().contains('no such table')) {
        throw Exception('Database table missing - try resetting the database');
      } else {
        throw Exception('Database error: $e');
      }
    }
  }

  Future<void> deletePrinter(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'printers',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setDefaultPrinter(String id) async {
    final db = await DatabaseHelper.instance.database;

    await db.update('printers', {
      'is_default': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.update(
      'printers',
      {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CUSTOMER DISPLAYS ====================

  Future<List<CustomerDisplay>> getCustomerDisplays() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_displays',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'is_default DESC, name ASC',
    );
    return maps.map((m) => _customerDisplayFromDb(m)).toList();
  }

  Future<CustomerDisplay?> getCustomerDisplayById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_displays',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _customerDisplayFromDb(maps[0]);
  }

  Future<CustomerDisplay?> getDefaultCustomerDisplay() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_displays',
      where: 'is_default = ? AND is_active = ?',
      whereArgs: [1, 1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _customerDisplayFromDb(maps[0]);
  }

  Future<void> saveCustomerDisplay(CustomerDisplay display) async {
    final db = await DatabaseHelper.instance.database;
    if (display.isDefault) {
      await db.update('customer_displays', {
        'is_default': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    final existing = await db.query(
      'customer_displays',
      where: 'id = ?',
      whereArgs: [display.id],
      limit: 1,
    );
    final data = <String, dynamic>{
      'id': display.id,
      'name': display.name,
      'connection_type': display.connectionType.name,
      'ip_address': display.ipAddress,
      'port': display.port,
      'usb_device_id': display.usbDeviceId,
      'bluetooth_address': display.bluetoothAddress,
      'platform_specific_id': display.platformSpecificId,
      'device_name': display.modelName,
      'is_default': display.isDefault ? 1 : 0,
      'is_active': display.isActive ? 1 : 0,
      'status': display.status.name,
      'has_permission': display.hasPermission ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (existing.isNotEmpty) {
      await db.update(
        'customer_displays',
        data,
        where: 'id = ?',
        whereArgs: [display.id],
      );
    } else {
      data['created_at'] = DateTime.now().toIso8601String();
      await db.insert('customer_displays', data);
    }
  }

  Future<void> deleteCustomerDisplay(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'customer_displays',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setDefaultCustomerDisplay(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('customer_displays', {
      'is_default': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.update(
      'customer_displays',
      {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== RECEIPT SETTINGS ====================

  Future<ReceiptSettings> getReceiptSettings() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_settings',
      limit: 1,
    );

    if (maps.isEmpty) {
      return ReceiptSettings();
    }

    return ReceiptSettings(
      showLogo: maps[0]['show_logo'] == 1,
      showDateTime: maps[0]['show_date_time'] == 1,
      showOrderNumber: maps[0]['show_order_number'] == 1,
      showCashierName: maps[0]['show_cashier_name'] == 1,
      showTaxBreakdown: maps[0]['show_tax_breakdown'] == 1,
      showServiceChargeBreakdown:
          (maps[0]['show_service_charge_breakdown'] as int?) != 0,
      showThankYouMessage: maps[0]['show_thank_you_message'] == 1,
      showTaxId: (maps[0]['show_tax_id'] as int?) != 0,
      taxIdText: maps[0]['tax_id_text'] ?? '',
      showWifiDetails: (maps[0]['show_wifi_details'] as int?) != 0,
      wifiDetails: maps[0]['wifi_details'] ?? '',
      showBarcode: (maps[0]['show_barcode'] as int?) != 0,
      barcodeData: maps[0]['barcode_data'] ?? '',
      showQrCode: (maps[0]['show_qr_code'] as int?) != 0,
      qrData: maps[0]['qr_data'] ?? '',
      autoPrint: maps[0]['auto_print'] == 1,
      paperSize: ReceiptPaperSize.values.firstWhere(
        (e) => e.name == (maps[0]['paper_size'] as String? ?? 'mm80'),
        orElse: () => ReceiptPaperSize.mm80,
      ),
      paperWidth: (maps[0]['paper_width'] as int?) ?? 80,
      fontSize: (maps[0]['font_size'] as int?) ?? 12,
      headerText: maps[0]['header_text'] ?? 'ExtroPOS',
      footerText: maps[0]['footer_text'] ?? 'Thank you for your business!',
      thankYouMessage:
          maps[0]['thank_you_message'] ?? 'Thank you! Please come again.',
      termsAndConditions: maps[0]['terms_and_conditions'] ?? '',
    );
  }

  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'receipt_settings',
      limit: 1,
    );

    final data = {
      'show_logo': settings.showLogo ? 1 : 0,
      'show_date_time': settings.showDateTime ? 1 : 0,
      'show_order_number': settings.showOrderNumber ? 1 : 0,
      'show_cashier_name': settings.showCashierName ? 1 : 0,
      'show_tax_breakdown': settings.showTaxBreakdown ? 1 : 0,
      'show_service_charge_breakdown': settings.showServiceChargeBreakdown
          ? 1
          : 0,
      'show_thank_you_message': settings.showThankYouMessage ? 1 : 0,
      'show_tax_id': settings.showTaxId ? 1 : 0,
      'tax_id_text': settings.taxIdText,
      'show_wifi_details': settings.showWifiDetails ? 1 : 0,
      'wifi_details': settings.wifiDetails,
      'show_barcode': settings.showBarcode ? 1 : 0,
      'barcode_data': settings.barcodeData,
      'show_qr_code': settings.showQrCode ? 1 : 0,
      'qr_data': settings.qrData,
      'auto_print': settings.autoPrint ? 1 : 0,
      'paper_size': settings.paperSize.name,
      'paper_width': settings.paperWidth,
      'font_size': settings.fontSize,
      'header_text': settings.headerText,
      'footer_text': settings.footerText,
      'thank_you_message': settings.thankYouMessage,
      'terms_and_conditions': settings.termsAndConditions,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      await db.update(
        'receipt_settings',
        data,
        where: 'id = ?',
        whereArgs: [existing[0]['id']],
      );
    } else {
      data['created_at'] = DateTime.now().toIso8601String();
      await db.insert('receipt_settings', data);
    }
  }

  // ==================== RESTAURANT TABLES ====================

  Future<List<RestaurantTable>> getTables() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return RestaurantTable(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        capacity: maps[i]['capacity'] as int,
        status: TableStatus.values.firstWhere(
          (s) => s.name == maps[i]['status'] as String,
          orElse: () => TableStatus.available,
        ),
        orders: [],
        occupiedSince: maps[i]['occupied_since'] != null
            ? DateTime.parse(maps[i]['occupied_since'] as String)
            : null,
        customerName: maps[i]['customer_name'] as String?,
      );
    });
  }

  Future<RestaurantTable?> getTableById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return RestaurantTable(
      id: map['id'].toString(),
      name: map['name'] as String,
      capacity: map['capacity'] as int,
      status: TableStatus.values.firstWhere(
        (s) => s.name == map['status'] as String,
        orElse: () => TableStatus.available,
      ),
      orders: [],
      occupiedSince: map['occupied_since'] != null
          ? DateTime.parse(map['occupied_since'] as String)
          : null,
      customerName: map['customer_name'] as String?,
    );
  }

  Future<int> insertTable(RestaurantTable table) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('tables', {
      'id': table.id,
      'name': table.name,
      'capacity': table.capacity,
      'status': table.status.name,
      'occupied_since': table.occupiedSince?.toIso8601String(),
      'customer_name': table.customerName,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateTable(RestaurantTable table) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'tables',
      {
        'name': table.name,
        'capacity': table.capacity,
        'status': table.status.name,
        'occupied_since': table.occupiedSince?.toIso8601String(),
        'customer_name': table.customerName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  Future<int> deleteTable(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== KITCHEN DISPLAY SYSTEM ====================

  Future<List<Map<String, dynamic>>> getKitchenOrders() async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery('''
      SELECT 
        o.*,
        t.name as table_name
      FROM orders o
      LEFT JOIN tables t ON o.table_id = t.id
      WHERE o.status IN ('sent_to_kitchen', 'preparing', 'ready')
      ORDER BY 
        CASE o.status
          WHEN 'sent_to_kitchen' THEN 1
          WHEN 'preparing' THEN 2
          WHEN 'ready' THEN 3
          ELSE 4
        END,
        o.sent_to_kitchen_at ASC,
        o.created_at ASC
    ''');

    return results;
  }

  Future<void> updateOrderStatus(
    String orderId,
    dynamic newStatus, {
    String? changedBy,
    String? notes,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    String statusValue;
    if (newStatus is String) {
      statusValue = newStatus;
    } else {
      statusValue = newStatus.toString().split('.').last;
      statusValue = statusValue.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      if (statusValue.startsWith('_')) {
        statusValue = statusValue.substring(1);
      }
    }

    await db.transaction((txn) async {
      await txn.update(
        'orders',
        {
          'status': statusValue,
          'updated_at': now,
          if (statusValue == 'sent_to_kitchen') 'sent_to_kitchen_at': now,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );

      await txn.insert('order_status_history', {
        'id': const Uuid().v4(),
        'order_id': orderId,
        'status': statusValue,
        'changed_by': changedBy,
        'notes': notes,
        'created_at': now,
      });
    });
  }

  Future<int> getOrderCountByStatus(
    dynamic status, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    String statusValue;
    if (status is String) {
      statusValue = status;
    } else {
      statusValue = status.toString().split('.').last;
      statusValue = statusValue.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      if (statusValue.startsWith('_')) {
        statusValue = statusValue.substring(1);
      }
    }

    String whereClause = 'status = ?';
    List<dynamic> whereArgs = [statusValue];

    if (startDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE $whereClause',
      whereArgs,
    );

    if (result.isEmpty) return 0;
    return result.first['count'] as int? ?? 0;
  }

  Future<List<Map<String, dynamic>>> getOrderStatusHistory(
    String orderId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'order_status_history',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getCafeQueueOrders() async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery('''
      SELECT 
        o.id,
        o.order_number,
        o.status,
        o.created_at,
        COUNT(oi.id) as item_count
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.order_type = 'cafe' 
        AND o.status IN ('preparing', 'ready')
      GROUP BY o.id
      ORDER BY 
        CASE o.status
          WHEN 'ready' THEN 1
          WHEN 'preparing' THEN 2
          ELSE 3
        END,
        o.created_at ASC
    ''');

    return results;
  }
}
