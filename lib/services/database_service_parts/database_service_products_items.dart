part of '../database_service.dart';

extension DatabaseServiceProductsItems on DatabaseService {
  Future<List<Item>> getItems({String? categoryId}) async {
    try {
      final sw = Stopwatch()..start();
      developer.log('DB: getItems() called (categoryId=$categoryId)');
      final db = await DatabaseHelper.instance.database;

      String? where;
      List<dynamic>? whereArgs;

      if (categoryId != null) {
        where = 'category_id = ? AND is_available = ?';
        whereArgs = [categoryId, 1];
      } else {
        where = 'is_available = ?';
        whereArgs = [1];
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'items',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );

      final result = List.generate(maps.length, (i) {
        return Item(
          id: maps[i]['id'].toString(),
          name: maps[i]['name'] as String,
          description: (maps[i]['description'] as String?) ?? '',
          categoryId: maps[i]['category_id']?.toString() ?? '',
          price: (maps[i]['price'] as num).toDouble(),
          cost: (maps[i]['cost'] as num?)?.toDouble(),
          sku: maps[i]['sku'] as String?,
          barcode: maps[i]['barcode'] as String?,
          icon: _iconFromDb(
            maps[i]['icon_code_point'] as int?,
            maps[i]['icon_font_family'] as String?,
          ),
          color: _colorFromDb(maps[i]['color_value'] as int?),
          imageUrl: maps[i]['image_url'] as String?,
          merchantPrices:
              (maps[i]['merchant_prices'] == null ||
                      (maps[i]['merchant_prices'] as String).isEmpty)
                  ? {}
                  : Map<String, double>.from(
                      jsonDecode(maps[i]['merchant_prices'] as String),
                    ),
          stock: (maps[i]['stock'] as int?) ?? 0,
          isAvailable: (maps[i]['is_available'] as int?) == 1,
          isFeatured: (maps[i]['is_featured'] as int?) == 1,
          trackStock: (maps[i]['track_stock'] as int?) == 1,
          sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
          printerOverride: maps[i]['printer_override'] as String?,
        );
      });
      sw.stop();
      developer.log(
        'DB: getItems() returning ${result.length} items (categoryId=$categoryId); elapsed=${sw.elapsedMilliseconds}ms',
      );
      return result;
    } catch (e, stackTrace) {
      developer.log('Database error in getItems: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.high,
        category: ErrorCategory.database,
        message: 'Failed to load items from database',
      );
      return [];
    }
  }

  Future<Item?> getItemById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'items',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return Item(
        id: maps[0]['id'].toString(),
        name: maps[0]['name'] as String,
        description: (maps[0]['description'] as String?) ?? '',
        categoryId: maps[0]['category_id']?.toString() ?? '',
        price: (maps[0]['price'] as num).toDouble(),
        cost: (maps[0]['cost'] as num?)?.toDouble(),
        sku: maps[0]['sku'] as String?,
        barcode: maps[0]['barcode'] as String?,
        icon: _iconFromDb(
          maps[0]['icon_code_point'] as int?,
          maps[0]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[0]['color_value'] as int?),
        imageUrl: maps[0]['image_url'] as String?,
        printerOverride: maps[0]['printer_override'] as String?,
        merchantPrices:
            (maps[0]['merchant_prices'] == null ||
                    (maps[0]['merchant_prices'] as String).isEmpty)
                ? {}
                : Map<String, double>.from(
                    jsonDecode(maps[0]['merchant_prices'] as String),
                  ),
        stock: (maps[0]['stock'] as int?) ?? 0,
        isAvailable: (maps[0]['is_available'] as int?) == 1,
        isFeatured: (maps[0]['is_featured'] as int?) == 1,
        trackStock: (maps[0]['track_stock'] as int?) == 1,
        sortOrder: (maps[0]['sort_order'] as int?) ?? 0,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Database error in getItemById($id): $e',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.medium,
        category: ErrorCategory.database,
        message: 'Failed to load item by ID from database',
      );
      return null;
    }
  }

  Future<int> importItemsFromJson(String jsonString) async {
    final db = await DatabaseHelper.instance.database;
    final dynamic parsed = jsonDecode(jsonString);
    final List<dynamic> list;

    if (parsed is List) {
      list = parsed;
    } else if (parsed is Map && parsed['items'] is List) {
      list = parsed['items'] as List<dynamic>;
    } else {
      throw FormatException('Invalid JSON format for items import');
    }

    int imported = 0;

    for (final raw in list) {
      try {
        final Map<String, dynamic> obj = Map<String, dynamic>.from(raw as Map);
        final name = (obj['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final price = (obj['price'] != null)
            ? (obj['price'] is num
                  ? (obj['price'] as num).toDouble()
                  : double.tryParse(obj['price'].toString()) ?? 0.0)
            : 0.0;

        final categoryName = (obj['category'] ?? 'Uncategorized').toString();

        String categoryId;
        final existing = await db.query(
          'categories',
          where: 'name = ?',
          whereArgs: [categoryName],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          categoryId = existing[0]['id'] as String;
        } else {
          categoryId = DateTime.now().millisecondsSinceEpoch.toString();
          final category = Category(
            id: categoryId,
            name: categoryName,
            description: (obj['category_description'] ?? '').toString(),
            icon: Icons.category,
            color: Colors.blue,
          );
          await insertCategory(category);
        }

        final itemId =
            (obj['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
                .toString();

        final item = Item(
          id: itemId,
          name: name,
          description: (obj['description'] ?? '').toString(),
          price: price,
          categoryId: categoryId,
          sku: obj['sku']?.toString(),
          barcode: obj['barcode']?.toString(),
          icon: Icons.shopping_bag,
          color: Colors.blue,
          isAvailable: (obj['isAvailable'] == null)
              ? true
              : (obj['isAvailable'] == true || obj['isAvailable'] == 1),
          isFeatured: (obj['isFeatured'] == true || obj['isFeatured'] == 1),
          trackStock: (obj['trackStock'] == true || obj['trackStock'] == 1),
          stock: (obj['stock'] is int)
              ? obj['stock'] as int
              : int.tryParse(obj['stock']?.toString() ?? '') ?? 0,
          cost: (obj['cost'] != null)
              ? (obj['cost'] is num
                    ? (obj['cost'] as num).toDouble()
                    : double.tryParse(obj['cost'].toString()))
              : null,
        );

        await insertItem(item);
        imported++;
      } catch (e) {
        debugPrint('Import item failed: $e');
        continue;
      }
    }

    return imported;
  }

  Future<int> importItemsFromCsv(String csv) async {
    final converter = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    );
    final List<List<dynamic>> rows;
    try {
      rows = converter.convert(csv);
    } catch (e) {
      final lines = csv
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) return 0;
      final header = _splitCsvLine(lines.first);
      final parsedFallback = <Map<String, String>>[];
      for (final row in lines.skip(1)) {
        final cols = _splitCsvLine(row);
        final map = <String, String>{};
        for (int i = 0; i < header.length && i < cols.length; i++) {
          map[header[i].toLowerCase()] = cols[i];
        }
        parsedFallback.add(map);
      }
      return await importItemsFromJson(jsonEncode(parsedFallback));
    }

    if (rows.isEmpty) return 0;

    final header = rows.first
        .map((e) => e?.toString().trim().toLowerCase() ?? '')
        .toList();
    final parsed = <Map<String, String>>[];
    for (final r in rows.skip(1)) {
      final map = <String, String>{};
      for (int i = 0; i < header.length && i < r.length; i++) {
        map[header[i]] = r[i]?.toString() ?? '';
      }
      parsed.add(map);
    }

    return await importItemsFromJson(jsonEncode(parsed));
  }

  Future<List<Map<String, dynamic>>> parseItemsFromContent(
    String content,
  ) async {
    try {
      final parsed = jsonDecode(content);
      List<dynamic> list;
      if (parsed is List) {
        list = parsed;
      } else if (parsed is Map && parsed['items'] is List) {
        list = parsed['items'] as List<dynamic>;
      } else {
        throw FormatException('Unknown JSON structure');
      }

      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      try {
        final converter = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        );
        final rows = converter.convert(content);
        if (rows.isEmpty) return [];
        final header = rows.first
            .map((e) => e?.toString().toLowerCase() ?? '')
            .toList();
        final parsed = <Map<String, dynamic>>[];
        for (final r in rows.skip(1)) {
          final map = <String, dynamic>{};
          for (int i = 0; i < header.length && i < r.length; i++) {
            map[header[i]] = r[i]?.toString() ?? '';
          }
          parsed.add(map);
        }
        return parsed;
      } catch (e) {
        return [];
      }
    }
  }

  Future<int> insertItem(Item item) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('items', {
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'category_id': item.categoryId,
      'price': item.price,
      'cost': item.cost,
      'sku': item.sku,
      'barcode': item.barcode,
      'icon_code_point': item.icon.codePoint,
      'icon_font_family': item.icon.fontFamily,
      'color_value': item.color.toARGB32(),
      'image_url': item.imageUrl,
      'stock': item.trackStock ? item.stock : 0,
      'is_available': item.isAvailable ? 1 : 0,
      'is_featured': item.isFeatured ? 1 : 0,
      'track_stock': item.trackStock ? 1 : 0,
      'sort_order': item.sortOrder,
      'merchant_prices': jsonEncode(item.merchantPrices),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'printer_override': item.printerOverride,
    });
  }

  Future<int> updateItem(Item item) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {
        'name': item.name,
        'description': item.description,
        'category_id': item.categoryId,
        'price': item.price,
        'cost': item.cost,
        'sku': item.sku,
        'barcode': item.barcode,
        'icon_code_point': item.icon.codePoint,
        'icon_font_family': item.icon.fontFamily,
        'color_value': item.color.toARGB32(),
        'image_url': item.imageUrl,
        'stock': item.stock,
        'is_available': item.isAvailable ? 1 : 0,
        'is_featured': item.isFeatured ? 1 : 0,
        'track_stock': item.trackStock ? 1 : 0,
        'sort_order': item.sortOrder,
        'merchant_prices': jsonEncode(item.merchantPrices),
        'updated_at': DateTime.now().toIso8601String(),
        'printer_override': item.printerOverride,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {'is_available': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItemStock(String id, int quantity) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {'stock': quantity, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Item>> searchItems(String query) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: '(name LIKE ? OR sku LIKE ? OR barcode LIKE ?) AND is_available = ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        categoryId: maps[i]['category_id']?.toString() ?? '',
        price: (maps[i]['price'] as num).toDouble(),
        cost: (maps[i]['cost'] as num?)?.toDouble(),
        sku: maps[i]['sku'] as String?,
        barcode: maps[i]['barcode'] as String?,
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        imageUrl: maps[i]['image_url'] as String?,
        stock: (maps[i]['stock'] as int?) ?? 0,
        isAvailable: (maps[i]['is_available'] as int?) == 1,
        isFeatured: (maps[i]['is_featured'] as int?) == 1,
        trackStock: (maps[i]['track_stock'] as int?) == 1,
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
      );
    });
  }

  Future<List<Item>> getLowStockItems() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM items
      WHERE track_stock = 1
      AND is_available = 1
      AND stock <= 10
      ORDER BY stock ASC
    ''');

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        categoryId: maps[i]['category_id']?.toString() ?? '',
        price: (maps[i]['price'] as num).toDouble(),
        cost: (maps[i]['cost'] as num?)?.toDouble(),
        sku: maps[i]['sku'] as String?,
        barcode: maps[i]['barcode'] as String?,
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        imageUrl: maps[i]['image_url'] as String?,
        stock: (maps[i]['stock'] as int?) ?? 0,
        isAvailable: (maps[i]['is_available'] as int?) == 1,
        isFeatured: (maps[i]['is_featured'] as int?) == 1,
        trackStock: (maps[i]['track_stock'] as int?) == 1,
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
      );
    });
  }

  Future<List<Item>> getFavoriteItems() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'is_featured = ? AND is_available = ?',
      whereArgs: [1, 1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        categoryId: maps[i]['category_id']?.toString() ?? '',
        price: (maps[i]['price'] as num).toDouble(),
        cost: (maps[i]['cost'] as num?)?.toDouble(),
        sku: maps[i]['sku'] as String?,
        barcode: maps[i]['barcode'] as String?,
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        imageUrl: maps[i]['image_url'] as String?,
        stock: (maps[i]['stock'] as int?) ?? 0,
        isAvailable: (maps[i]['is_available'] as int?) == 1,
        isFeatured: (maps[i]['is_featured'] as int?) == 1,
        trackStock: (maps[i]['track_stock'] as int?) == 1,
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
      );
    });
  }
}
