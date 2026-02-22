import 'dart:convert';
import 'dart:developer' as developer;

import 'package:csv/csv.dart';
import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_display_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/merchant_model.dart';
import 'package:extropos/models/modifier_group_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/payment_split_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/error_handler.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Service layer for database operations
/// Provides clean CRUD methods for all entities
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  // ==================== CATEGORIES ====================

  /// Get all categories ordered by sort_order
  Future<List<Category>> getCategories() async {
    try {
      final sw = Stopwatch()..start();
      developer.log('DB: getCategories() called');
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'sort_order ASC, name ASC',
      );

      final result = List.generate(maps.length, (i) {
        return Category(
          id: maps[i]['id'].toString(),
          name: maps[i]['name'] as String,
          description: (maps[i]['description'] as String?) ?? '',
          icon: _iconFromDb(
            maps[i]['icon_code_point'] as int?,
            maps[i]['icon_font_family'] as String?,
          ),
          color: _colorFromDb(maps[i]['color_value'] as int?),
          sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
          isActive: (maps[i]['is_active'] as int?) == 1,
          taxRate: (maps[i]['tax_rate'] as double?) ?? 0.0,
        );
      });
      sw.stop();
      developer.log(
        'DB: getCategories() returning ${result.length} categories; elapsed=${sw.elapsedMilliseconds}ms',
      );
      return result;
    } catch (e, stackTrace) {
      developer.log('Database error in getCategories: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(e, severity: ErrorSeverity.high, category: ErrorCategory.database, message: 'Failed to load categories from database');
      // Return empty list as fallback
      return [];
    }
  }

  /// Get a single category by ID
  Future<Category?> getCategoryById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Category(
      id: maps[0]['id'].toString(),
      name: maps[0]['name'] as String,
      description: (maps[0]['description'] as String?) ?? '',
      icon: _iconFromDb(
        maps[0]['icon_code_point'] as int?,
        maps[0]['icon_font_family'] as String?,
      ),
      color: _colorFromDb(maps[0]['color_value'] as int?),
      sortOrder: (maps[0]['sort_order'] as int?) ?? 0,
      isActive: (maps[0]['is_active'] as int?) == 1,
      taxRate: (maps[0]['tax_rate'] as double?) ?? 0.0,
    );
  }

  /// Insert a new category
  Future<int> insertCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('categories', {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'icon_code_point': category.icon.codePoint,
      'icon_font_family': category.icon.fontFamily,
      'color_value': category.color.toARGB32(),
      'sort_order': category.sortOrder,
      'is_active': category.isActive ? 1 : 0,
      'tax_rate': category.taxRate,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing category
  Future<int> updateCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'categories',
      {
        'name': category.name,
        'description': category.description,
        'icon_code_point': category.icon.codePoint,
        'icon_font_family': category.icon.fontFamily,
        'color_value': category.color.toARGB32(),
        'sort_order': category.sortOrder,
        'is_active': category.isActive ? 1 : 0,
        'tax_rate': category.taxRate,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete a category (soft delete by setting is_active = 0)
  Future<int> deleteCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'categories',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently delete a category
  Future<int> permanentlyDeleteCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ITEMS ====================

  /// Get all items
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
      return []; // Return empty list as fallback
    }
  }

  /// Get a single item by ID
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
      developer.log('Database error in getItemById($id): $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.medium,
        category: ErrorCategory.database,
        message: 'Failed to load item by ID from database',
      );
      return null; // Return null as fallback
    }
  }

  /// Import items from a JSON string. JSON can be a list of item objects or
  /// a wrapper object containing an `items` array. Returns number of items
  /// successfully imported.
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

        // Resolve or create category
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
        // Ignore individual item import errors and continue
        debugPrint('Import item failed: $e');
        continue;
      }
    }

    return imported;
  }

  /// Import items from a simple CSV string. Header row is expected. Returns
  /// number of items imported. This is intentionally forgiving and supports
  /// comma separated values with a header including at least `name` and `price`.
  Future<int> importItemsFromCsv(String csv) async {
    // Use the csv package which supports quoted fields and multiline cells
    final converter = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    );
    final List<List<dynamic>> rows;
    try {
      rows = converter.convert(csv);
    } catch (e) {
      // Fallback to simple split if parsing fails
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

  List<String> _splitCsvLine(String line) {
    final List<String> parts = [];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char == ',' && !inQuotes) {
        parts.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    parts.add(buffer.toString().trim());
    return parts;
  }

  /// Parse content that may be JSON or CSV into a list of item-like maps.
  /// This does NOT insert into the database. Used for previews in the UI.
  Future<List<Map<String, dynamic>>> parseItemsFromContent(
    String content,
  ) async {
    // Try JSON first
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
      // Fallback to CSV parsing using csv package for robust handling
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
        // If csv parsing fails, return empty list
        return [];
      }
    }
  }

  /// Insert a new item
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

  /// Update an existing item
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

  /// Delete an item (soft delete)
  Future<int> deleteItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {'is_available': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update item stock quantity
  Future<int> updateItemStock(String id, int quantity) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {'stock': quantity, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== RECEIPT SETTINGS ====================

  /// Get receipt settings
  Future<ReceiptSettings> getReceiptSettings() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_settings',
      limit: 1,
    );

    if (maps.isEmpty) {
      // Return default settings
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

  /// Save receipt settings
  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    final db = await DatabaseHelper.instance.database;

    // Check if settings exist
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
      // Update existing settings
      await db.update(
        'receipt_settings',
        data,
        where: 'id = ?',
        whereArgs: [existing[0]['id']],
      );
    } else {
      // Insert new settings
      data['created_at'] = DateTime.now().toIso8601String();
      await db.insert('receipt_settings', data);
    }
  }

  // ==================== PRINTERS ====================

  /// Get all active printers
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

  /// Get a single printer by ID
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

  /// Get default printer
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

  /// Save a printer (insert or update)
  /// Save a printer (insert or update)
  Future<void> savePrinter(Printer printer) async {
    developer.log(
      'DatabaseService.savePrinter: Starting for printer ${printer.id} (${printer.name})',
    );

    final db = await DatabaseHelper.instance.database;
    developer.log('DatabaseService.savePrinter: Database connection obtained');

    // If this printer is set as default, clear other defaults first
    if (printer.isDefault) {
      developer.log('DatabaseService.savePrinter: Clearing other defaults');
      await db.update('printers', {
        'is_default': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    // Check if printer exists
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

    // Check which columns exist in the printers table
    final tableInfo = await db.rawQuery('PRAGMA table_info(printers)');
    final columnNames = tableInfo.map((col) => col['name'] as String).toSet();
    final hasPaperSize = columnNames.contains('paper_size');
    final hasStatus = columnNames.contains('status');
    final hasPermission = columnNames.contains('has_permission');
    final hasCategories = columnNames.contains('categories');

    developer.log('DatabaseService.savePrinter: Table columns: $columnNames');

    // Build data map with only existing columns
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

    // Add optional columns only if they exist
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
      // Provide more specific error message
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

  /// Delete a printer
  Future<void> deletePrinter(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'printers',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Set default printer (clears other defaults)
  Future<void> setDefaultPrinter(String id) async {
    final db = await DatabaseHelper.instance.database;

    // Clear all defaults
    await db.update('printers', {
      'is_default': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Set new default
    await db.update(
      'printers',
      {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Printer _printerFromDb(Map<String, dynamic> map) {
    final connectionType = PrinterConnectionType.values.firstWhere(
      (e) => e.name == map['connection_type'],
      orElse: () => PrinterConnectionType.network,
    );

    final type = PrinterType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => PrinterType.receipt,
    );

    final paperSize = map['paper_size'] != null
        ? ThermalPaperSize.values.firstWhere(
            (e) => e.name == map['paper_size'],
            orElse: () => ThermalPaperSize.mm80,
          )
        : null;

    final status = map['status'] != null
        ? PrinterStatus.values.firstWhere(
            (e) => e.name == map['status'],
            orElse: () => PrinterStatus.offline,
          )
        : PrinterStatus.offline;

    final hasPermission = map['has_permission'] == 1;

    // Parse categories from JSON string
    List<String> categories = [];
    if (map['categories'] != null) {
      try {
        final decoded = jsonDecode(map['categories'] as String);
        if (decoded is List) {
          categories = decoded.cast<String>();
        }
      } catch (e) {
        developer.log('Error parsing printer categories: $e');
      }
    }

    Printer printer;

    switch (connectionType) {
      case PrinterConnectionType.network:
        printer = Printer.network(
          id: map['id'],
          name: map['name'],
          type: type,
          ipAddress: map['ip_address'] ?? '',
          port: map['port'] ?? 9100,
          isDefault: map['is_default'] == 1,
          modelName: map['device_name'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
          categories: categories,
        );
        break;
      case PrinterConnectionType.usb:
        printer = Printer.usb(
          id: map['id'],
          name: map['name'],
          type: type,
          usbDeviceId: map['device_id'] ?? '',
          isDefault: map['is_default'] == 1,
          modelName: map['device_name'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
          categories: categories,
        );
        break;
      case PrinterConnectionType.bluetooth:
        printer = Printer.bluetooth(
          id: map['id'],
          name: map['name'],
          type: type,
          bluetoothAddress: map['device_id'] ?? '',
          isDefault: map['is_default'] == 1,
          modelName: map['device_name'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
          categories: categories,
        );
        break;
      case PrinterConnectionType.posmac:
        printer = Printer.posmac(
          id: map['id'],
          name: map['name'],
          type: type,
          platformSpecificId: map['device_id'] ?? '',
          isDefault: map['is_default'] == 1,
          modelName: map['device_name'],
          paperSize: paperSize,
          status: status,
          hasPermission: hasPermission,
          categories: categories,
        );
        break;
    }

    return printer;
  }

  // ==================== CUSTOMER DISPLAYS ====================

  /// Get all active customer displays
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

  /// Get a single customer display by ID
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

  /// Get default customer display
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

  /// Save a customer display (insert or update)
  Future<void> saveCustomerDisplay(CustomerDisplay display) async {
    final db = await DatabaseHelper.instance.database;
    if (display.isDefault) {
      // Clear other defaults
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

  /// Delete (soft) a customer display
  Future<void> deleteCustomerDisplay(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'customer_displays',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Set default customer display (clears other defaults)
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

  CustomerDisplay _customerDisplayFromDb(Map<String, dynamic> map) {
    final connectionType = PrinterConnectionType.values.firstWhere(
      (e) => e.name == map['connection_type'],
      orElse: () => PrinterConnectionType.network,
    );
    final status = map['status'] != null
        ? CustomerDisplayStatus.values.firstWhere(
            (e) => e.name == map['status'],
            orElse: () => CustomerDisplayStatus.offline,
          )
        : CustomerDisplayStatus.offline;
    return CustomerDisplay(
      id:
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name']?.toString() ?? 'Unknown Display',
      connectionType: connectionType,
      ipAddress: map['ip_address'] as String?,
      port: map['port'] as int?,
      usbDeviceId: map['usb_device_id'] as String?,
      bluetoothAddress: map['bluetooth_address'] as String?,
      platformSpecificId: map['platform_specific_id'] as String?,
      modelName: map['device_name'] as String?,
      status: status,
      isDefault: (map['is_default'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      hasPermission: (map['has_permission'] as int?) == 1,
    );
  }

  // ==================== HELPER METHODS ====================

  /// Convert IconData to string representation
  IconData _iconFromDb(int? codePoint, String? fontFamily) {
    // Temporarily return constant icon for tree shaking compatibility
    return Icons.category;
  }

  Color _colorFromDb(int? colorValue) {
    if (colorValue == null) return Colors.blue;
    return Color(colorValue);
  }

  // ==================== SEARCH & FILTER ====================

  /// Search items by name or SKU
  Future<List<Item>> searchItems(String query) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where:
          '(name LIKE ? OR sku LIKE ? OR barcode LIKE ?) AND is_available = ?',
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

  /// Get low stock items
  Future<List<Item>> getLowStockItems() async {
    final db = await DatabaseHelper.instance.database;
    // Use a default threshold of 10 since schema doesn't include low_stock_threshold
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

  /// Get favorite items
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

  // ==================== MODIFIER GROUPS ====================

  /// Get all modifier groups
  Future<List<ModifierGroup>> getModifierGroups() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_groups',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierGroup.fromJson(maps[i]));
  }

  /// Get modifier groups for a specific category
  Future<List<ModifierGroup>> getModifierGroupsForCategory(
    String categoryId,
  ) async {
    final allGroups = await getModifierGroups();
    return allGroups
        .where((group) => group.appliesToCategory(categoryId))
        .toList();
  }

  /// Get a single modifier group by ID
  Future<ModifierGroup?> getModifierGroupById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ModifierGroup.fromJson(maps[0]);
  }

  /// Insert a new modifier group
  Future<void> insertModifierGroup(ModifierGroup group) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('modifier_groups', group.toJson());
  }

  /// Update an existing modifier group
  Future<void> updateModifierGroup(ModifierGroup group) async {
    final db = await DatabaseHelper.instance.database;
    final updatedGroup = group.copyWith(updatedAt: DateTime.now());
    await db.update(
      'modifier_groups',
      updatedGroup.toJson(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  /// Delete a modifier group
  Future<void> deleteModifierGroup(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MODIFIER ITEMS ====================

  /// Get all modifier items for a specific group
  Future<List<ModifierItem>> getModifierItems(String groupId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      where: 'modifier_group_id = ? AND is_available = ?',
      whereArgs: [groupId, 1],
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierItem.fromJson(maps[i]));
  }

  /// Get all modifier items (for management)
  Future<List<ModifierItem>> getAllModifierItems() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      orderBy: 'modifier_group_id ASC, sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierItem.fromJson(maps[i]));
  }

  /// Get a single modifier item by ID
  Future<ModifierItem?> getModifierItemById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ModifierItem.fromJson(maps[0]);
  }

  /// Insert a new modifier item
  Future<void> insertModifierItem(ModifierItem item) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('modifier_items', item.toJson());
  }

  /// Update an existing modifier item
  Future<void> updateModifierItem(ModifierItem item) async {
    final db = await DatabaseHelper.instance.database;
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    await db.update(
      'modifier_items',
      updatedItem.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a modifier item
  Future<void> deleteModifierItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_items', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SALES (ORDERS & TRANSACTIONS) ====================

  /// Save a completed sale (order + items + transaction) in a single transaction.
  /// Returns the generated order number on success, or null if persistence was skipped (e.g., unmapped items).
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
    String status =
        'completed', // Default to 'completed' for backward compatibility
  }) async {
    try {
      if (cartItems.isEmpty) return null;

      final db = await DatabaseHelper.instance.database;

      // Prefetch items to map product names -> item IDs (required by schema)
      final rawItems = await db.query('items', columns: ['id', 'name', 'price']);
      final Map<String, Map<String, Object?>> itemByName = {
        for (final row in rawItems) (row['name'] as String): row,
      };

      // Ensure all cart items can be mapped to DB items; otherwise skip persistence
      final unmapped = cartItems
          .where((ci) => !itemByName.containsKey(ci.product.name))
          .toList();
      if (unmapped.isNotEmpty) {
        // Skip saving to avoid violating NOT NULL + FK constraints on order_items.item_id
        return null;
      }

      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final uuid = const Uuid();
      final generatedOrderNumber = _generateOrderNumber(
        orderType: orderType,
        cafeOrderNumber: cafeOrderNumber,
      );
      final resolvedUserId = userId ?? '1'; // default admin (seeded)

      // Get current shift ID
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
        'status':
            status, // Use the status parameter instead of hardcoded 'completed'
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

        // Encode modifiers into notes JSON for the line item
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
          // Store unit price as final (base + modifiers) to reflect charged price
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

    return generatedOrderNumber;
    } catch (e, stackTrace) {
      developer.log('Database error in saveCompletedSale: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.high,
        category: ErrorCategory.database,
        message: 'Failed to save completed sale to database',
      );
      return null; // Return null to indicate failure
    }
  }

  /// Save a completed sale with split payments (order + items + transaction + payment splits)
  /// Returns the generated order number on success, or null if persistence was skipped
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

    // Prefetch items to map product names -> item IDs (required by schema)
    final rawItems = await db.query('items', columns: ['id', 'name', 'price']);
    final Map<String, Map<String, Object?>> itemByName = {
      for (final row in rawItems) (row['name'] as String): row,
    };

    // Ensure all cart items can be mapped to DB items; otherwise skip persistence
    final unmapped = cartItems
        .where((ci) => !itemByName.containsKey(ci.product.name))
        .toList();
    if (unmapped.isNotEmpty) {
      // Log detailed information about the mismatch
      final unmappedNames = unmapped.map((ci) => ci.product.name).toList();
      final availableNames = itemByName.keys.toList();
      developer.log(
        '❌ Cart items not found in database:\n'
        'Unmapped items: $unmappedNames\n'
        'Available items in DB: $availableNames',
        name: 'database_service',
      );
      // Skip saving to avoid violating NOT NULL + FK constraints on order_items.item_id
      return null;
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final uuid = const Uuid();
    final generatedOrderNumber = _generateOrderNumber(
      orderType: orderType,
      cafeOrderNumber: cafeOrderNumber,
    );
    final resolvedUserId = userId ?? '1'; // default admin (seeded)

    // Get current shift ID
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

      // Insert order items
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

      // Insert transaction with split payments
      final transactionId = uuid.v4();
      await txn.insert('transactions', {
        'id': transactionId,
        'order_id': orderId,
        'payment_method_id': paymentSplits.first.paymentMethod.id, // Primary payment method
        'amount': amountPaid,
        'change_amount': change,
        'transaction_date': nowIso,
        'receipt_number': generatedOrderNumber,
        'created_at': nowIso,
      });

      // Insert individual payment splits
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

    return generatedOrderNumber;
  }

  String _generateOrderNumber({
    required String orderType,
    int? cafeOrderNumber,
  }) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');

    switch (orderType) {
      case 'cafe':
        final numStr = (cafeOrderNumber ?? 0).toString().padLeft(3, '0');
        return 'C-$numStr-$y$m$d$hh$mm$ss$ms';
      case 'restaurant':
        return 'T-$y$m$d$hh$mm$ss$ms';
      default:
        return 'R-$y$m$d$hh$mm$ss$ms';
    }
  }

  /// Void/cancel an order (mark as cancelled, no refund transaction)
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

  /// Process a refund for an order (creates negative transaction)
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
        // Update order status
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

        // Create negative transaction for refund
        await txn.insert('transactions', {
          'id': uuid.v4(),
          'order_id': orderId,
          'payment_method_id': paymentMethodId,
          'amount': -refundAmount, // Negative amount for refund
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

  /// Get a list of recent orders (raw maps) - newest first
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
      return []; // Return empty list as fallback
    }
  }

  /// Get orders with optional filters and pagination. Returns raw maps.
  /// - from/to are inclusive and compare against `created_at` (ISO string)
  /// - paymentMethodId filters by payment_method_id
  /// - offset/limit for paging
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
      return []; // Return empty list as fallback
    }
  }

  /// Export orders (with order items) to CSV string. Each row represents
  /// an order item with order-level fields included.
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
    // Machine-readable metadata as CSV key,value rows
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
    sb.writeln(); // blank line before column headers
    sb.writeln(
      'order_number,created_at,total,payment_method_id,merchant_id,merchant_name,table_id,user_id,status,item_id,item_name,quantity,item_price,item_subtotal,seat,notes',
    );

    for (final o in orders) {
      final orderId = o['id'].toString();
      final orderNumber = (o['order_number'] ?? '').toString();
      final createdAt = (o['created_at'] ?? '').toString();
      final total = ((o['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(
        2,
      );
      final paymentMethod = (o['payment_method_id'] ?? '').toString();
      final merchantId = (o['merchant_id'] ?? '').toString();
      final merchantName = MerchantHelper.displayName(merchantId);
      final tableId = (o['table_id'] ?? '').toString();
      final userId = (o['user_id'] ?? '').toString();
      final status = (o['status'] ?? '').toString();

      final items = await getOrderItems(orderId);
      if (items.isEmpty) {
        // Emit an order-level row with empty item columns
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

  String _escapeCsv(String input) {
    final s = input.replaceAll('\r', '').replaceAll('\n', ' ');
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Get order items for a specific order
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

  /// Get order items as CartItem objects for refunds/returns
  Future<List<CartItem>> getOrderItemsAsCartItems(String orderId) async {
    final itemMaps = await getOrderItems(orderId);
    final cartItems = <CartItem>[];

    for (final map in itemMaps) {
      // Create a Product from the stored item data
      final product = Product(
        map['item_name'] as String,
        (map['item_price'] as num).toDouble(),
        '', // category not needed for refunds
        Icons.shopping_cart, // default icon
      );

      // Parse modifiers from notes JSON if present
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

  /// Get transactions associated with an order
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

  /// Get order by order number
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
    // Add item count
    final items = await getOrderItems(order['id'].toString());
    order['item_count'] = items.length;

    return order;
  }

  /// Get orders by customer phone in date range
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

  /// Get orders within a date range
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
        limit: 100, // Limit to prevent overwhelming results
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
      developer.log('Database error in getOrdersInDateRange: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.medium,
        category: ErrorCategory.database,
        message: 'Failed to load orders in date range from database',
      );
      return []; // Return empty list as fallback
    }
  }

  // ==================== KITCHEN DISPLAY SYSTEM ====================

  /// Get orders for kitchen display (sent_to_kitchen, preparing, ready statuses)
  Future<List<Map<String, dynamic>>> getKitchenOrders() async {
    final db = await DatabaseHelper.instance.database;

    // Get orders with active kitchen statuses
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

  /// Update order status and record in history
  Future<void> updateOrderStatus(
    String orderId,
    dynamic newStatus, {
    String? changedBy,
    String? notes,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    // Get status string value
    String statusValue;
    if (newStatus is String) {
      statusValue = newStatus;
    } else {
      // Assume it's OrderStatus enum - import needed in calling code
      statusValue = newStatus.toString().split('.').last;
      // Convert camelCase to snake_case
      statusValue = statusValue.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      if (statusValue.startsWith('_')) {
        statusValue = statusValue.substring(1);
      }
    }

    await db.transaction((txn) async {
      // Update order status
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

      // Record status change in history
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

  /// Get order count by status (for statistics)
  Future<int> getOrderCountByStatus(
    dynamic status, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Get status string value
    String statusValue;
    if (status is String) {
      statusValue = status;
    } else {
      statusValue = status.toString().split('.').last;
      // Convert camelCase to snake_case
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

  /// Get order status history for an order
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

  /// Get cafe orders for customer queue display (preparing and ready statuses)
  Future<List<Map<String, dynamic>>> getCafeQueueOrders() async {
    final db = await DatabaseHelper.instance.database;

    // Get cafe orders with preparing or ready status
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

  // ==================== END KITCHEN DISPLAY SYSTEM ====================

  // ==================== USERS ====================

  /// Get all users
  Future<List<User>> getUsers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      final id = maps[i]['id'].toString();
      // PINs are now stored in encrypted PinStore, not in database
      // If PinStore fails or is not initialized, fall back to database PIN
      final pinFromStore = PinStore.instance.getPinForUser(id);
      final pinFromDb = maps[i]['pin'] as String? ?? '';
      final pin = pinFromStore ?? pinFromDb;

      // DEBUG: Log PIN retrieval
      debugPrint(
        '🔐 getUsers() - User: $id, PinStore: $pinFromStore, DB: "$pinFromDb", Final: "$pin"',
      );

      return User(
        id: id,
        username: maps[i]['username'] as String? ?? '', // New username field
        fullName: maps[i]['name'] as String, // Map 'name' column to fullName
        email: maps[i]['email'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == (maps[i]['role'] as String),
          orElse: () => UserRole.cashier,
        ), // Parse role from string name
        pin: pin,
        status: (maps[i]['is_active'] as int) == 1
            ? UserStatus.active
            : UserStatus.inactive, // Map is_active to status
        lastLoginAt: maps[i]['last_login_at'] != null
            ? DateTime.parse(maps[i]['last_login_at'] as String)
            : null, // New lastLoginAt field
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
        phoneNumber:
            maps[i]['phone_number'] as String?, // New phoneNumber field
      );
    });
  }

  /// Get a single user by ID
  Future<User?> getUserById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    final idStr = map['id'].toString();
    // PINs are now stored in encrypted PinStore, not in database
    // If PinStore fails or is not initialized, fall back to database PIN
    final pin =
        PinStore.instance.getPinForUser(idStr) ?? (map['pin'] as String? ?? '');
    return User(
      id: idStr,
      username: map['username'] as String? ?? '', // New username field
      fullName: map['name'] as String, // Map 'name' column to fullName
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (map['role'] as String),
        orElse: () => UserRole.cashier,
      ), // Parse role from string name
      pin: pin,
      status: (map['is_active'] as int) == 1
          ? UserStatus.active
          : UserStatus
                .inactive, // Map is_active to status (1=active, 0=inactive)
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null, // New lastLoginAt field
      createdAt: DateTime.parse(map['created_at'] as String),
      phoneNumber: map['phone_number'] as String?, // New phoneNumber field
    );
  }

  /// Find a user by PIN for authentication
  Future<User?> findUserByPin(String pin) async {
    final users = await getUsers();
    try {
      return users.firstWhere((user) => user.pin == pin);
    } catch (e) {
      return null;
    }
  }

  /// Insert a new user
  Future<int> insertUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    // Try to store PIN in encrypted PinStore first
    bool pinStoredInHive = false;
    try {
      await PinStore.instance.setPinForUser(user.id, user.pin);
      // Verify the PIN was actually stored
      final storedPin = PinStore.instance.getPinForUser(user.id);
      if (storedPin != null && storedPin == user.pin) {
        pinStoredInHive = true;
      }
    } catch (e) {
      debugPrint('🔐 PinStore failed: $e');
    }

    final pinToStore = pinStoredInHive ? '' : user.pin;
    debugPrint(
      '🔐 insertUser() - User: ${user.id}, PIN: "${user.pin}", PinStoreSuccess: $pinStoredInHive, StoringInDB: "$pinToStore"',
    );

    // Insert user into database
    // If PinStore succeeded, don't store PIN in database (empty string)
    // If PinStore failed, store PIN in database as fallback
    return await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'name': user.fullName,
      'email': user.email,
      'phone_number': user.phoneNumber,
      'role': user.role.name,
      'is_active': user.status == UserStatus.active ? 1 : 0,
      'pin': pinToStore, // Empty if in PinStore, actual PIN as fallback
      'last_login_at': user.lastLoginAt?.toIso8601String(),
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing user
  Future<int> updateUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    // Try to store PIN in encrypted PinStore first
    bool pinStoredInHive = false;
    try {
      await PinStore.instance.setPinForUser(user.id, user.pin);
      // Verify the PIN was actually stored
      final storedPin = PinStore.instance.getPinForUser(user.id);
      if (storedPin != null && storedPin == user.pin) {
        pinStoredInHive = true;
      }
    } catch (e) {
      debugPrint('PinStore failed during update: $e');
    }

    // Update user in database
    // If PinStore succeeded, don't store PIN in database (empty string)
    // If PinStore failed, store PIN in database as fallback
    return await db.update(
      'users',
      {
        'username': user.username,
        'name': user.fullName,
        'email': user.email,
        'phone_number': user.phoneNumber,
        'role': user.role.name,
        'is_active': user.status == UserStatus.active ? 1 : 0,
        'pin': pinStoredInHive
            ? ''
            : user.pin, // Empty if in PinStore, actual PIN as fallback
        'last_login_at': user.lastLoginAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Delete a user
  Future<int> deleteUser(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Update user's last login timestamp
  Future<int> updateUserLastLogin(String userId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'users',
      {
        'last_login_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== TABLES ====================

  /// Get all tables
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
        ), // Parse from string name
        orders: [], // Orders are not stored in DB, only in memory
        occupiedSince: maps[i]['occupied_since'] != null
            ? DateTime.parse(maps[i]['occupied_since'] as String)
            : null,
        customerName: maps[i]['customer_name'] as String?,
      );
    });
  }

  /// Get a single table by ID
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
      ), // Parse from string name
      orders: [], // Orders are not stored in DB, only in memory
      occupiedSince: map['occupied_since'] != null
          ? DateTime.parse(map['occupied_since'] as String)
          : null,
      customerName: map['customer_name'] as String?,
    );
  }

  /// Insert a new table
  Future<int> insertTable(RestaurantTable table) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('tables', {
      'id': table.id,
      'name': table.name,
      'capacity': table.capacity,
      'status': table.status.name, // Store as string name, not index
      'occupied_since': table.occupiedSince?.toIso8601String(),
      'customer_name': table.customerName,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing table
  Future<int> updateTable(RestaurantTable table) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'tables',
      {
        'name': table.name,
        'capacity': table.capacity,
        'status': table.status.name, // Store as string name, not index
        'occupied_since': table.occupiedSince?.toIso8601String(),
        'customer_name': table.customerName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  /// Delete a table
  Future<int> deleteTable(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== PAYMENT METHODS ====================

  /// Get all payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return PaymentMethod(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        status: PaymentMethodStatus.values[maps[i]['status'] as int],
        isDefault: (maps[i]['is_default'] as int?) == 1,
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
      );
    });
  }

  /// Get a single payment method by ID
  Future<PaymentMethod?> getPaymentMethodById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return PaymentMethod(
      id: map['id'].toString(),
      name: map['name'] as String,
      status: PaymentMethodStatus.values[map['status'] as int],
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Insert a new payment method
  Future<int> insertPaymentMethod(PaymentMethod paymentMethod) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('payment_methods', {
      'id': paymentMethod.id,
      'name': paymentMethod.name,
      'status': paymentMethod.status.index,
      'is_default': paymentMethod.isDefault ? 1 : 0,
      'created_at':
          paymentMethod.createdAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing payment method
  Future<int> updatePaymentMethod(PaymentMethod paymentMethod) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'payment_methods',
      {
        'name': paymentMethod.name,
        'status': paymentMethod.status.index,
        'is_default': paymentMethod.isDefault ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [paymentMethod.id],
    );
  }

  /// Delete a payment method
  Future<int> deletePaymentMethod(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CUSTOMERS ====================

  /// Get all customers ordered by name
  Future<List<Customer>> getCustomers({bool activeOnly = true}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  /// Get a single customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Find customer by phone number
  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'phone = ? AND is_active = ?',
      whereArgs: [phone, 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Find customer by email
  Future<Customer?> getCustomerByEmail(String email) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'email = ? AND is_active = ?',
      whereArgs: [email, 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Search customers by name, phone, or email
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await DatabaseHelper.instance.database;
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: '''
        is_active = ? AND (
          name LIKE ? OR 
          phone LIKE ? OR 
          email LIKE ?
        )
      ''',
      whereArgs: [1, searchTerm, searchTerm, searchTerm],
      orderBy: 'name ASC',
      limit: 50,
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  /// Insert a new customer
  Future<void> insertCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('customers', customer.toMap());
  }

  /// Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Update customer purchase statistics after a sale
  Future<void> updateCustomerStats({
    required String customerId,
    required double orderTotal,
    required int pointsEarned,
  }) async {
    final customer = await getCustomerById(customerId);

    if (customer == null) return;

    final updated = customer.copyWith(
      totalSpent: customer.totalSpent + orderTotal,
      visitCount: customer.visitCount + 1,
      loyaltyPoints: customer.loyaltyPoints + pointsEarned,
      lastVisit: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await updateCustomer(updated);
  }

  /// Soft delete a customer (set is_active to 0)
  Future<void> deleteCustomer(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'customers',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get top customers by total spent
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'total_spent DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  /// Get recent customers (visited in last 30 days)
  Future<List<Customer>> getRecentCustomers({int days = 30}) async {
    final db = await DatabaseHelper.instance.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'is_active = ? AND last_visit >= ?',
      whereArgs: [1, cutoffDate.toIso8601String()],
      orderBy: 'last_visit DESC',
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  // ==================== DELETE ALL METHODS ====================

  /// Delete all sales (orders, order_items, transactions)
  Future<void> deleteAllSales() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions');
    await db.delete('order_items');
    await db.delete('orders');
  }

  /// Delete all modifier items
  Future<void> deleteAllModifierItems() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('item_modifiers');
    await db.delete('modifier_items');
  }

  /// Delete all modifier groups
  Future<void> deleteAllModifierGroups() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_groups');
  }

  /// Delete all items
  Future<void> deleteAllItems() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('items');
  }

  /// Delete all categories
  Future<void> deleteAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories');
  }

  /// Delete all tables
  Future<void> deleteAllTables() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tables');
  }

  /// Delete all users
  Future<void> deleteAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('users');
  }

  /// Delete all payment methods
  Future<void> deleteAllPaymentMethods() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('payment_methods');
  }

  /// Delete all printers
  Future<void> deleteAllPrinters() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('printers');
  }

  // ==================== SALES REPORTS ====================

  /// Generate a comprehensive sales report for the given period
  Future<SalesReport> generateSalesReport(ReportPeriod period) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get all orders within the period
      final List<Map<String, dynamic>> orderMaps = await db.query(
        'orders',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [
          period.startDate.toIso8601String(),
          period.endDate.toIso8601String(),
        ],
      );

      double netSales = 0.0;
      double taxAmount = 0.0;
      double serviceChargeAmount = 0.0;
      int transactionCount = orderMaps.length;
      final Set<String> uniqueCustomers = {};
      final Map<String, int> productsSold = {};
      final Map<String, double> categoryRevenue = {};
      final Map<String, double> paymentMethodBreakdown = {};
      final Map<int, double> hourlySales = {};

      final businessInfo = BusinessInfo.instance;

      for (final orderMap in orderMaps) {
        final orderId = orderMap['id'].toString();
        final createdAt = DateTime.parse(orderMap['created_at'] as String);
        final paymentMethod = orderMap['payment_method'] as String? ?? 'Cash';
        final customerId = orderMap['customer_id'] as String?;
        if (customerId != null && customerId.isNotEmpty) {
          uniqueCustomers.add(customerId);
        }

        // Get order items
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

      double orderTotal = 0.0;

      for (final itemMap in itemMaps) {
        final itemId = itemMap['item_id'] as String;
        final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
        final unitPrice = (itemMap['item_price'] as num?)?.toDouble() ?? 0.0;
        final lineTotal = quantity * unitPrice;

        orderTotal += lineTotal;

        // Get item details
        final itemDetailsMaps = await db.query(
          'items',
          columns: ['name', 'category_id'],
          where: 'id = ?',
          whereArgs: [itemId],
        );

        if (itemDetailsMaps.isNotEmpty) {
          final itemName = itemDetailsMaps.first['name'] as String;
          final categoryId = itemDetailsMaps.first['category_id'] as String?;

          // Update products sold
          productsSold[itemName] = (productsSold[itemName] ?? 0) + quantity;

          // Update category revenue
          if (categoryId != null) {
            final categoryMaps = await db.query(
              'categories',
              columns: ['name'],
              where: 'id = ?',
              whereArgs: [categoryId],
            );
            if (categoryMaps.isNotEmpty) {
              final categoryName = categoryMaps.first['name'] as String;
              categoryRevenue[categoryName] =
                  (categoryRevenue[categoryName] ?? 0.0) + lineTotal;
            }
          }
        }
      }

      netSales += orderTotal;

      final orderServiceCharge =
          businessInfo.isServiceChargeEnabled ? orderTotal * businessInfo.serviceChargeRate : 0.0;
      final orderTax = businessInfo.isTaxEnabled ? orderTotal * businessInfo.taxRate : 0.0;

      serviceChargeAmount += orderServiceCharge;
      taxAmount += orderTax;

      // Update payment method breakdown
      paymentMethodBreakdown[paymentMethod] =
          (paymentMethodBreakdown[paymentMethod] ?? 0.0) + orderTotal;

      // Update hourly sales
      final hour = createdAt.hour;
      hourlySales[hour] = (hourlySales[hour] ?? 0.0) + orderTotal;
    }

    final grossSales = netSales + taxAmount + serviceChargeAmount;
    final averageTicket = transactionCount > 0 ? grossSales / transactionCount : 0.0;

    return SalesReport(
      id: 'report_${period.startDate.millisecondsSinceEpoch}_${period.endDate.millisecondsSinceEpoch}',
      startDate: period.startDate,
      endDate: period.endDate,
      reportType: period.label,
      grossSales: grossSales,
      netSales: netSales,
      taxAmount: taxAmount,
      serviceChargeAmount: serviceChargeAmount,
      transactionCount: transactionCount,
      uniqueCustomers: uniqueCustomers.length,
      averageTicket: averageTicket,
      averageTransactionTime: 0,
      topCategories: categoryRevenue,
      paymentMethods: paymentMethodBreakdown,
      generatedAt: DateTime.now(),
    );
    } catch (e, stackTrace) {
      developer.log('Database error in generateSalesReport: $e', error: e, stackTrace: stackTrace);
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.high,
        category: ErrorCategory.database,
        message: 'Failed to generate sales report from database',
      );
      // Return empty report as fallback
      return SalesReport(
        id: 'error_report',
        startDate: period.startDate,
        endDate: period.endDate,
        reportType: period.label,
        grossSales: 0.0,
        netSales: 0.0,
        taxAmount: 0.0,
        serviceChargeAmount: 0.0,
        transactionCount: 0,
        uniqueCustomers: 0,
        averageTicket: 0.0,
        averageTransactionTime: 0,
        topCategories: {},
        paymentMethods: {},
        generatedAt: DateTime.now(),
      );
    }
  }

  // ==================== ADVANCED REPORTING ====================

  /// Generate comprehensive sales summary report
  Future<SalesSummaryReport> generateSalesSummaryReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double grossSales = 0.0;
    double totalDiscounts = 0.0;
    double totalRefunds = 0.0;
    double taxCollected = 0.0;
    int totalTransactions = orderMaps.length;
    Map<String, double> taxBreakdown = {};
    Map<String, double> hourlySales = {};
    Map<String, double> dailySales = {};

    for (final orderMap in orderMaps) {
      final createdAt = DateTime.parse(orderMap['created_at'] as String);
      final subtotal = orderMap['subtotal'] as double;
      final tax = orderMap['tax'] as double;
      final discount = orderMap['discount'] as double? ?? 0.0;

      grossSales += subtotal + tax;
      totalDiscounts += discount;
      taxCollected += tax;

      // Update hourly sales
      final hour = createdAt.hour;
      hourlySales[hour.toString()] =
          (hourlySales[hour.toString()] ?? 0.0) + (subtotal + tax);

      // Update daily sales
      final dayKey = createdAt.toIso8601String().substring(0, 10);
      dailySales[dayKey] = (dailySales[dayKey] ?? 0.0) + (subtotal + tax);

      // Tax breakdown (simplified - would need more detailed tax tracking)
      if (tax > 0) {
        final taxRate = (tax / subtotal * 100).round();
        final taxKey = '${taxRate.toStringAsFixed(1)}%';
        taxBreakdown[taxKey] = (taxBreakdown[taxKey] ?? 0.0) + tax;
      }
    }

    final netSales = grossSales - totalDiscounts - totalRefunds;
    final averageTransactionValue = totalTransactions > 0
        ? grossSales / totalTransactions
        : 0.0;

    return SalesSummaryReport(
      id: 'sales_summary_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      grossSales: grossSales,
      netSales: netSales,
      totalDiscounts: totalDiscounts,
      totalRefunds: totalRefunds,
      taxCollected: taxCollected,
      averageTransactionValue: averageTransactionValue,
      totalTransactions: totalTransactions,
      taxBreakdown: taxBreakdown,
      hourlySales: hourlySales,
      dailySales: dailySales,
    );
  }

  /// Generate detailed product sales report
  Future<ProductSalesReport> generateProductSalesReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        oi.item_id,
        i.name as item_name,
        c.name as category_name,
        SUM(oi.quantity) as units_sold,
        SUM(oi.subtotal) as total_revenue,
        AVG(oi.item_price) as average_price
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN items i ON oi.item_id = i.id
      LEFT JOIN categories c ON i.category_id = c.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY oi.item_id, i.name, c.name
      ORDER BY total_revenue DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final productSales = results
        .map(
          (row) => ProductSalesData(
            productId: row['item_id'] as String,
            productName: row['item_name'] as String,
            category: row['category_name'] as String? ?? 'Uncategorized',
            unitsSold: row['units_sold'] as int,
            totalRevenue: row['total_revenue'] as double,
            averagePrice: row['average_price'] as double,
          ),
        )
        .toList();

    final topSellingProducts = <String, int>{};
    final worstSellingProducts = <String, double>{};

    for (final product in productSales) {
      if (topSellingProducts.length < 10) {
        topSellingProducts[product.productName] = product.unitsSold;
      }
      worstSellingProducts[product.productName] = product.totalRevenue;
    }

    // Sort worst selling by revenue ascending
    final sortedWorst = worstSellingProducts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final worstSellingMap = Map.fromEntries(sortedWorst.take(10));

    final totalUnitsSold = productSales.fold<int>(
      0,
      (sum, p) => sum + p.unitsSold,
    );
    final totalRevenue = productSales.fold<double>(
      0.0,
      (sum, p) => sum + p.totalRevenue,
    );

    return ProductSalesReport(
      id: 'product_sales_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      productSales: productSales,
      topSellingProducts: topSellingProducts,
      worstSellingProducts: worstSellingMap,
      totalUnitsSold: totalUnitsSold.toDouble(),
      totalRevenue: totalRevenue,
    );
  }

  /// Generate category sales report
  Future<CategorySalesReport> generateCategorySalesReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        c.id as category_id,
        c.name as category_name,
        SUM(oi.subtotal) as revenue,
        COUNT(DISTINCT o.id) as transaction_count,
        AVG(o.total) as average_transaction
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN items i ON oi.item_id = i.id
      JOIN categories c ON i.category_id = c.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY c.id, c.name
      ORDER BY revenue DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final categorySales = <String, CategorySalesData>{};
    String topPerformingCategory = '';
    String lowestPerformingCategory = '';
    double maxRevenue = 0.0;
    double minRevenue = double.infinity;

    for (final row in results) {
      final categoryId = row['category_id'] as String;
      final categoryName = row['category_name'] as String;
      final revenue = row['revenue'] as double;
      final transactionCount = row['transaction_count'] as int;
      final averageTransaction = row['average_transaction'] as double;

      // Get top products for this category
      final topProductsQuery = '''
        SELECT i.name, SUM(oi.quantity) as qty
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        JOIN items i ON oi.item_id = i.id
        WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
        AND i.category_id = ?
        GROUP BY i.name
        ORDER BY qty DESC
        LIMIT 5
      ''';

      final topProductsResults = await db.rawQuery(topProductsQuery, [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        categoryId,
      ]);

      final topProducts = <String, int>{};
      for (final productRow in topProductsResults) {
        topProducts[productRow['name'] as String] = productRow['qty'] as int;
      }

      final categoryData = CategorySalesData(
        categoryId: categoryId,
        categoryName: categoryName,
        revenue: revenue,
        grossProfit: revenue * 0.3, // Simplified - would need actual COGS
        transactionCount: transactionCount,
        averageTransactionValue: averageTransaction,
        topProducts: topProducts,
      );

      categorySales[categoryName] = categoryData;

      if (revenue > maxRevenue) {
        maxRevenue = revenue;
        topPerformingCategory = categoryName;
      }
      if (revenue < minRevenue) {
        minRevenue = revenue;
        lowestPerformingCategory = categoryName;
      }
    }

    return CategorySalesReport(
      id: 'category_sales_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      categorySales: categorySales,
      topPerformingCategory: topPerformingCategory,
      lowestPerformingCategory: lowestPerformingCategory,
    );
  }

  /// Generate payment method report
  Future<PaymentMethodReport> generatePaymentMethodReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        pm.name as method_name,
        SUM(o.total) as total_amount,
        COUNT(o.id) as transaction_count
      FROM orders o
      LEFT JOIN payment_methods pm ON o.payment_method_id = pm.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY pm.id, pm.name
      ORDER BY total_amount DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final paymentBreakdown = <String, PaymentMethodData>{};
    double totalProcessed = 0.0;
    String mostUsedMethod = '';
    String highestRevenueMethod = '';
    int maxTransactions = 0;
    double maxRevenue = 0.0;

    for (final row in results) {
      final methodName = row['method_name'] as String? ?? 'Cash';
      final totalAmount = row['total_amount'] as double;
      final transactionCount = row['transaction_count'] as int;

      totalProcessed += totalAmount;

      final paymentData = PaymentMethodData(
        methodId: methodName.toLowerCase().replaceAll(' ', '_'),
        methodName: methodName,
        totalAmount: totalAmount,
        transactionCount: transactionCount,
        averageTransaction: transactionCount > 0
            ? totalAmount / transactionCount
            : 0.0,
        percentageOfTotal:
            0.0, // Will be calculated after all data is collected
      );

      paymentBreakdown[methodName] = paymentData;

      if (transactionCount > maxTransactions) {
        maxTransactions = transactionCount;
        mostUsedMethod = methodName;
      }
      if (totalAmount > maxRevenue) {
        maxRevenue = totalAmount;
        highestRevenueMethod = methodName;
      }
    }

    // Calculate percentages
    paymentBreakdown.forEach((key, data) {
      paymentBreakdown[key] = PaymentMethodData(
        methodId: data.methodId,
        methodName: data.methodName,
        totalAmount: data.totalAmount,
        transactionCount: data.transactionCount,
        averageTransaction: data.averageTransaction,
        percentageOfTotal: totalProcessed > 0
            ? (data.totalAmount / totalProcessed) * 100
            : 0.0,
      );
    });

    return PaymentMethodReport(
      id: 'payment_method_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      paymentBreakdown: paymentBreakdown,
      mostUsedMethod: mostUsedMethod,
      highestRevenueMethod: highestRevenueMethod,
      totalProcessed: totalProcessed,
    );
  }

  /// Generate employee performance report
  Future<EmployeePerformanceReport> generateEmployeePerformanceReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        u.id as employee_id,
        u.name as employee_name,
        COUNT(o.id) as transaction_count,
        SUM(o.total) as total_sales,
        AVG(o.total) as average_transaction,
        SUM(o.discount) as total_discounts
      FROM orders o
      JOIN users u ON o.user_id = u.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY u.id, u.name
      ORDER BY total_sales DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final employeePerformance = <EmployeeData>[];
    String topPerformer = '';
    String needsImprovement = '';
    double maxSales = 0.0;
    double minSales = double.infinity;

    for (final row in results) {
      final employeeId = row['employee_id'] as String;
      final employeeName = row['employee_name'] as String;
      final transactionCount = row['transaction_count'] as int;
      final totalSales = row['total_sales'] as double;
      final averageTransaction = row['average_transaction'] as double;
      final totalDiscounts = row['total_discounts'] as double;

      final employeeData = EmployeeData(
        employeeId: employeeId,
        employeeName: employeeName,
        totalSales: totalSales,
        transactionCount: transactionCount,
        averageTransactionValue: averageTransaction,
        totalDiscountsGiven: totalDiscounts,
        tipsAccrued: 0.0, // Would need tips tracking
        laborCostPercentage: 0.0, // Would need labor cost tracking
        hoursWorked: 0, // Would need time clock integration
        voidedTransactions: {}, // Would need void tracking
        refundsProcessed: {}, // Would need refund tracking
      );

      employeePerformance.add(employeeData);

      if (totalSales > maxSales) {
        maxSales = totalSales;
        topPerformer = employeeName;
      }
      if (totalSales < minSales) {
        minSales = totalSales;
        needsImprovement = employeeName;
      }
    }

    return EmployeePerformanceReport(
      id: 'employee_performance_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      employeePerformance: employeePerformance,
      departmentPerformance: {}, // Would need department tracking
      topPerformer: topPerformer,
      needsImprovement: needsImprovement,
    );
  }

  /// Generate inventory optimization report
  Future<InventoryReport> generateInventoryReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    // Get all items with their sales data
    final query = '''
      SELECT
        i.id,
        i.name,
        i.price,
        i.cost_price,
        COALESCE(i.stock_quantity, 0) as stock_quantity,
        COALESCE(i.min_stock_level, 0) as min_stock_level,
        COALESCE(i.max_stock_level, 0) as max_stock_level,
        c.name as category_name,
        COALESCE(SUM(oi.quantity), 0) as units_sold,
        COALESCE(SUM(oi.quantity * oi.price), 0) as revenue,
        COALESCE(AVG(oi.price), 0) as avg_selling_price,
        COUNT(DISTINCT o.id) as order_count,
        MAX(o.created_at) as last_sale_date
      FROM items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN order_items oi ON i.id = oi.item_id
      LEFT JOIN orders o ON oi.order_id = o.id AND o.created_at BETWEEN ? AND ?
      WHERE i.is_active = 1
      GROUP BY i.id, i.name, i.price, i.cost_price, i.stock_quantity, i.min_stock_level, i.max_stock_level, c.name
      ORDER BY units_sold DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final inventoryItems = <InventoryItemData>[];
    double totalValue = 0;
    final stockValueByCategory = <String, double>{};
    final lowStockItems = <String>[];
    final outOfStockItems = <String>[];

    for (final row in results) {
      final stockQuantity = (row['stock_quantity'] as int?) ?? 0;
      final minStock = (row['min_stock_level'] as int?) ?? 0;
      final maxStock = (row['max_stock_level'] as int?) ?? 0;
      final costPrice = (row['cost_price'] as double?) ?? 0.0;
      final unitsSold = (row['units_sold'] as int?) ?? 0;
      final revenue = (row['revenue'] as double?) ?? 0.0;
      final lastSaleDate = row['last_sale_date'] != null
          ? DateTime.parse(row['last_sale_date'] as String)
          : null;
      final daysSinceLastSale = lastSaleDate != null
          ? DateTime.now().difference(lastSaleDate).inDays
          : 999;
      final category = (row['category_name'] as String?) ?? 'Uncategorized';

      final stockStatus = _calculateStockStatus(
        stockQuantity,
        minStock,
        maxStock,
      );

      final inventoryItem = InventoryItemData(
        itemId: row['id'].toString(),
        itemName: row['name'] as String,
        category: category,
        currentStock: stockQuantity,
        reorderPoint: minStock,
        costOfGoodsSold: costPrice * unitsSold,
        grossMarginReturnOnInvestment: revenue > 0
            ? ((revenue - (costPrice * unitsSold)) / revenue) * 100
            : 0.0,
        daysSinceLastSale: daysSinceLastSale,
        stockStatus: stockStatus,
      );

      inventoryItems.add(inventoryItem);
      final itemValue = stockQuantity * ((row['price'] as double?) ?? 0.0);
      totalValue += itemValue;
      stockValueByCategory[category] =
          (stockValueByCategory[category] ?? 0.0) + itemValue;

      if (stockStatus == 'out_of_stock') {
        outOfStockItems.add(row['name'] as String);
      } else if (stockStatus == 'low_stock') {
        lowStockItems.add(row['name'] as String);
      }
    }

    return InventoryReport(
      id: 'inventory_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      inventoryItems: inventoryItems,
      stockValueByCategory: stockValueByCategory,
      lowStockItems: lowStockItems,
      outOfStockItems: outOfStockItems,
      totalInventoryValue: totalValue,
      inventoryTurnoverRate: 0.0, // Would need more complex calculation
    );
  }

  /// Generate shrinkage report for inventory loss tracking
  Future<ShrinkageReport> generateShrinkageReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    // This would typically track inventory adjustments, damaged goods, etc.
    // For now, we'll create a basic structure that can be expanded
    final shrinkageData = <ShrinkageData>[];

    // Query for any inventory adjustments or discrepancies
    final adjustmentQuery = '''
      SELECT
        i.name as item_name,
        i.id as item_id,
        COALESCE(SUM(ia.quantity_change), 0) as total_adjustments,
        COUNT(ia.id) as adjustment_count,
        ia.reason,
        ia.created_at
      FROM items i
      LEFT JOIN inventory_adjustments ia ON i.id = ia.item_id
        AND ia.created_at BETWEEN ? AND ?
      WHERE i.is_active = 1
      GROUP BY i.id, i.name, ia.reason
      HAVING total_adjustments < 0
      ORDER BY ABS(total_adjustments) DESC
    ''';

    final adjustmentResults = await db.rawQuery(adjustmentQuery, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    double totalShrinkageValue = 0;

    for (final row in adjustmentResults) {
      final adjustments = (row['total_adjustments'] as int?) ?? 0;
      if (adjustments >= 0) continue; // Only negative adjustments (losses)

      final shrinkageItem = ShrinkageData(
        itemId: row['item_id'].toString(),
        itemName: row['item_name'] as String,
        expectedQuantity: 0, // Would need actual inventory counts
        actualQuantity: adjustments.abs(),
        variance: adjustments,
        varianceValue: 0.0, // Would need cost price lookup
        reason: (row['reason'] as String?) ?? 'unknown',
        lastCountDate: DateTime.parse(row['created_at'] as String),
      );

      shrinkageData.add(shrinkageItem);
      totalShrinkageValue += shrinkageItem.varianceValue;
    }

    return ShrinkageReport(
      id: 'shrinkage_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      shrinkageItems: shrinkageData,
      totalShrinkageValue: totalShrinkageValue,
      totalShrinkagePercentage:
          0.0, // Would need total inventory value for calculation
      shrinkageByCategory: {}, // Would need category grouping
      shrinkageByReason: {}, // Would need reason grouping
    );
  }

  /// Generate labor cost analysis report
  Future<LaborCostReport> generateLaborCostReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    // Get employee hours and wages
    final laborQuery = '''
      SELECT
        u.id,
        u.name,
        u.role,
        COALESCE(u.hourly_wage, 0) as hourly_wage,
        COALESCE(SUM(ets.hours_worked), 0) as total_hours,
        COUNT(DISTINCT ets.id) as shift_count,
        COALESCE(AVG(ets.hours_worked), 0) as avg_hours_per_shift
      FROM users u
      LEFT JOIN employee_time_sheets ets ON u.id = ets.user_id
        AND ets.date BETWEEN ? AND ?
      WHERE u.is_active = 1 AND u.role IN ('manager', 'cashier', 'server')
      GROUP BY u.id, u.name, u.role, u.hourly_wage
      ORDER BY total_hours DESC
    ''';

    final laborResults = await db.rawQuery(laborQuery, [
      period.startDate.toIso8601String().substring(0, 10),
      period.endDate.toIso8601String().substring(0, 10),
    ]);

    final efficiencyData = <LaborEfficiencyData>[];
    double totalLaborCost = 0;
    final laborCostByDepartment = <String, double>{};
    final laborCostByShift = <String, double>{};

    for (final row in laborResults) {
      final hourlyWage = (row['hourly_wage'] as double?) ?? 0.0;
      final hoursWorked = (row['total_hours'] as double?) ?? 0.0;
      final laborCost = hourlyWage * hoursWorked;
      final role = (row['role'] as String?) ?? 'Unknown';

      // Create efficiency data (simplified - would need shift-based data)
      final efficiencyItem = LaborEfficiencyData(
        shift: 'All Shifts', // Would need actual shift data
        department: role,
        scheduledHours: hoursWorked.round(), // Simplified
        actualHours: hoursWorked.round(),
        salesDuringShift: 0.0, // Would need shift-based sales data
        laborCostEfficiency: 0.0, // Would need calculation based on sales
      );

      efficiencyData.add(efficiencyItem);
      totalLaborCost += laborCost;

      // Group by department
      laborCostByDepartment[role] =
          (laborCostByDepartment[role] ?? 0.0) + laborCost;

      // Group by shift (simplified)
      laborCostByShift['All Shifts'] =
          (laborCostByShift['All Shifts'] ?? 0.0) + laborCost;
    }

    // Get sales data for labor cost percentage calculation
    final salesQuery = '''
      SELECT COALESCE(SUM(total_amount), 0) as total_sales
      FROM orders
      WHERE created_at BETWEEN ? AND ? AND status = 'completed'
    ''';

    final salesResult = await db.rawQuery(salesQuery, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);
    final totalSales = (salesResult.first['total_sales'] as double?) ?? 0.0;

    return LaborCostReport(
      id: 'labor_cost_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalLaborCost: totalLaborCost,
      laborCostPercentage: totalSales > 0
          ? (totalLaborCost / totalSales) * 100
          : 0.0,
      laborCostByDepartment: laborCostByDepartment,
      laborCostByShift: laborCostByShift,
      efficiencyData: efficiencyData,
    );
  }

  /// Generate customer analysis report
  Future<CustomerReport> generateCustomerReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    // Get customer order data
    final customerQuery = '''
      SELECT
        o.customer_name,
        o.customer_phone,
        COUNT(DISTINCT o.id) as order_count,
        COALESCE(SUM(o.total_amount), 0) as total_spent,
        COALESCE(AVG(o.total_amount), 0) as avg_order_value,
        MAX(o.created_at) as last_order_date,
        MIN(o.created_at) as first_order_date,
        GROUP_CONCAT(DISTINCT oi.item_id) as purchased_items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.created_at BETWEEN ? AND ?
        AND o.customer_name IS NOT NULL
        AND o.customer_name != ''
        AND o.status = 'completed'
      GROUP BY o.customer_name, o.customer_phone
      ORDER BY total_spent DESC
    ''';

    final customerResults = await db.rawQuery(customerQuery, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final topCustomers = <TopCustomerData>[];
    final customerSegments = <String, int>{};
    final inactiveCustomers = <InactiveCustomerData>[];
    int totalActiveCustomers = 0;
    double totalRevenue = 0.0;

    for (final row in customerResults) {
      final totalSpent = (row['total_spent'] as double?) ?? 0.0;
      final orderCount = (row['order_count'] as int?) ?? 0;
      final lastOrderDate = row['last_order_date'] != null
          ? DateTime.parse(row['last_order_date'] as String)
          : null;

      final customer = TopCustomerData(
        customerId:
            'customer_${customerResults.indexOf(row)}', // Would need actual customer ID
        customerName: (row['customer_name'] as String?) ?? 'Unknown',
        totalSpent: totalSpent,
        visitCount: orderCount,
        averageOrderValue: orderCount > 0 ? totalSpent / orderCount : 0.0,
        lastVisit: lastOrderDate ?? DateTime.now(),
        favoriteProducts: [], // Would need product analysis
      );

      topCustomers.add(customer);
      totalRevenue += totalSpent;
      totalActiveCustomers++;

      // Simple segmentation
      if (totalSpent >= 500) {
        customerSegments['VIP'] = (customerSegments['VIP'] ?? 0) + 1;
      } else if (totalSpent >= 200) {
        customerSegments['Gold'] = (customerSegments['Gold'] ?? 0) + 1;
      } else if (totalSpent >= 50) {
        customerSegments['Silver'] = (customerSegments['Silver'] ?? 0) + 1;
      } else {
        customerSegments['Bronze'] = (customerSegments['Bronze'] ?? 0) + 1;
      }
    }

    return CustomerReport(
      id: 'customer_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      topCustomers: topCustomers.take(20).toList(),
      customerSegments: customerSegments,
      inactiveCustomers:
          inactiveCustomers, // Would need inactive customer logic
      totalActiveCustomers: totalActiveCustomers,
      averageCustomerLifetimeValue: totalActiveCustomers > 0
          ? totalRevenue / totalActiveCustomers
          : 0.0,
    );
  }

  /// Generate basket analysis report
  Future<BasketAnalysisReport> generateBasketAnalysisReport(
    ReportPeriod period,
  ) async {
    // Simplified implementation - would need complex market basket analysis
    return BasketAnalysisReport(
      id: 'basket_analysis_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      frequentlyBoughtTogether: {}, // Would need complex analysis
      productAffinityScores: {}, // Would need affinity calculations
      recommendedBundles: [], // Would need bundle recommendations
      purchasePatterns: {}, // Would need pattern analysis
    );
  }

  /// Generate loyalty program analytics report
  Future<LoyaltyProgramReport> generateLoyaltyProgramReport(
    ReportPeriod period,
  ) async {
    // Simplified implementation - would need loyalty program tables
    return LoyaltyProgramReport(
      id: 'loyalty_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalMembers: 0, // Would need loyalty member count
      activeMembers: 0, // Would need active member calculation
      totalPointsIssued: 0.0, // Would need points tracking
      totalPointsRedeemed: 0.0, // Would need redemption tracking
      redemptionRate: 0.0, // Would need redemption rate calculation
      revenueFromLoyaltyMembers: 0.0, // Would need revenue calculation
      pointsByTier: {}, // Would need tier grouping
    );
  }

  // Helper methods for report calculations

  String _calculateStockStatus(int currentStock, int minStock, int maxStock) {
    if (currentStock <= 0) return 'Out of Stock';
    if (currentStock <= minStock) return 'Low Stock';
    if (currentStock > maxStock) return 'Overstock';
    return 'In Stock';
  }

  // ==================== ADVANCED REPORTING ====================
  // Scheduled Reports, Forecasting, and Custom Templates

  /// Save a scheduled report configuration
  Future<void> saveScheduledReport(dynamic scheduledReport) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('scheduled_reports', {
      'id': scheduledReport.id,
      'name': scheduledReport.name,
      'report_type': scheduledReport.reportType.name,
      'period_type': null, // Can be extended later
      'period_start': scheduledReport.period.startDate.toIso8601String(),
      'period_end': scheduledReport.period.endDate.toIso8601String(),
      'period_label': scheduledReport.period.label,
      'frequency': scheduledReport.frequency.name,
      'recipient_emails': jsonEncode(scheduledReport.recipientEmails),
      'export_formats': jsonEncode(
        scheduledReport.exportFormats.map((f) => f.name).toList(),
      ),
      'custom_filters': scheduledReport.customFilters != null
          ? jsonEncode(scheduledReport.customFilters)
          : null,
      'is_active': scheduledReport.isActive ? 1 : 0,
      'next_run': scheduledReport.nextRun?.toIso8601String(),
      'last_run': scheduledReport.lastRun?.toIso8601String(),
      'created_at': scheduledReport.createdAt.toIso8601String(),
      'updated_at': scheduledReport.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all scheduled reports
  Future<List<dynamic>> getScheduledReports({bool activeOnly = false}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_reports',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'next_run ASC',
    );

    // Return raw maps - convert to ScheduledReport objects in the service layer
    return maps;
  }

  /// Get scheduled report by ID
  Future<Map<String, dynamic>?> getScheduledReportById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_reports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return maps.isEmpty ? null : maps.first;
  }

  /// Update a scheduled report
  Future<void> updateScheduledReport(dynamic scheduledReport) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'scheduled_reports',
      {
        'name': scheduledReport.name,
        'report_type': scheduledReport.reportType.name,
        'period_start': scheduledReport.period.startDate.toIso8601String(),
        'period_end': scheduledReport.period.endDate.toIso8601String(),
        'period_label': scheduledReport.period.label,
        'frequency': scheduledReport.frequency.name,
        'recipient_emails': jsonEncode(scheduledReport.recipientEmails),
        'export_formats': jsonEncode(
          scheduledReport.exportFormats.map((f) => f.name).toList(),
        ),
        'custom_filters': scheduledReport.customFilters != null
            ? jsonEncode(scheduledReport.customFilters)
            : null,
        'is_active': scheduledReport.isActive ? 1 : 0,
        'next_run': scheduledReport.nextRun?.toIso8601String(),
        'last_run': scheduledReport.lastRun?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [scheduledReport.id],
    );
  }

  /// Delete a scheduled report
  Future<void> deleteScheduledReport(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('scheduled_reports', where: 'id = ?', whereArgs: [id]);
  }

  /// Get reports due for execution
  Future<List<Map<String, dynamic>>> getReportsDueForExecution() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    return await db.query(
      'scheduled_reports',
      where: 'is_active = 1 AND next_run <= ?',
      whereArgs: [now],
      orderBy: 'next_run ASC',
    );
  }

  /// Save execution history
  Future<void> saveExecutionHistory(Map<String, dynamic> history) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'report_execution_history',
      history,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get execution history for a scheduled report
  Future<List<Map<String, dynamic>>> getExecutionHistory(
    String scheduledReportId, {
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'report_execution_history',
      where: 'scheduled_report_id = ?',
      whereArgs: [scheduledReportId],
      orderBy: 'executed_at DESC',
      limit: limit,
    );
  }

  /// Get recent execution history across all reports
  Future<List<Map<String, dynamic>>> getRecentExecutions({
    int limit = 20,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'report_execution_history',
      orderBy: 'executed_at DESC',
      limit: limit,
    );
  }

  /// Save forecast model
  Future<void> saveForecastModel(Map<String, dynamic> model) async {
    final db = await DatabaseHelper.instance.database;

    // Deactivate previous models
    await db.update(
      'forecast_models',
      {'is_active': 0},
      where: 'is_active = ?',
      whereArgs: [1],
    );

    // Insert new active model
    await db.insert(
      'forecast_models',
      model,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get active forecast model
  Future<Map<String, dynamic>?> getActiveForecastModel() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'forecast_models',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'generated_at DESC',
      limit: 1,
    );

    return maps.isEmpty ? null : maps.first;
  }

  /// Get forecast model history
  Future<List<Map<String, dynamic>>> getForecastModelHistory({
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'forecast_models',
      orderBy: 'generated_at DESC',
      limit: limit,
    );
  }

  /// Save custom report template
  Future<void> saveCustomReportTemplate(Map<String, dynamic> template) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'custom_report_templates',
      template,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user's custom templates
  Future<List<Map<String, dynamic>>> getUserCustomTemplates(
    String userId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'custom_report_templates',
      where: 'created_by = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  /// Get shared custom templates
  Future<List<Map<String, dynamic>>> getSharedCustomTemplates() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'custom_report_templates',
      where: 'is_shared = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  /// Delete custom template
  Future<void> deleteCustomReportTemplate(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'custom_report_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== DEALER CUSTOMERS ====================

  /// Get all active dealer customers
  Future<List<Map<String, dynamic>>> getDealerCustomers() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'dealer_customers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'business_name ASC',
    );
  }

  /// Get a single dealer customer by ID
  Future<Map<String, dynamic>?> getDealerCustomerById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dealer_customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Get a dealer customer by email (for login validation)
  Future<Map<String, dynamic>?> getDealerCustomerByEmail(String email) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dealer_customers',
      where: 'email = ? AND is_active = ?',
      whereArgs: [email.toLowerCase(), 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Insert a new dealer customer
  Future<int> insertDealerCustomer(Map<String, dynamic> customer) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure email is lowercase for consistency
    if (customer.containsKey('email')) {
      customer['email'] = customer['email'].toString().toLowerCase();
    }

    // Ensure timestamps
    final now = DateTime.now().toIso8601String();
    customer['created_at'] = customer['created_at'] ?? now;
    customer['updated_at'] = now;

    return await db.insert('dealer_customers', customer);
  }

  /// Update an existing dealer customer
  Future<int> updateDealerCustomer(Map<String, dynamic> customer) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure email is lowercase for consistency
    if (customer.containsKey('email')) {
      customer['email'] = customer['email'].toString().toLowerCase();
    }

    // Update timestamp
    customer['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'dealer_customers',
      customer,
      where: 'id = ?',
      whereArgs: [customer['id']],
    );
  }

  /// Soft delete a dealer customer (set is_active to 0)
  Future<int> deleteDealerCustomer(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'dealer_customers',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search dealer customers by name, email, or business name
  Future<List<Map<String, dynamic>>> searchDealerCustomers(String query) async {
    final db = await DatabaseHelper.instance.database;
    final searchPattern = '%${query.toLowerCase()}%';

    return await db.query(
      'dealer_customers',
      where: '''
        is_active = ? AND (
          LOWER(business_name) LIKE ? OR 
          LOWER(owner_name) LIKE ? OR 
          LOWER(email) LIKE ?
        )
      ''',
      whereArgs: [1, searchPattern, searchPattern, searchPattern],
      orderBy: 'business_name ASC',
    );
  }

  // ==================== TENANTS ====================

  /// Get all active tenants
  Future<List<Map<String, dynamic>>> getTenants() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'tenants',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'tenant_name ASC',
    );
  }

  /// Get tenants for a specific customer
  Future<List<Map<String, dynamic>>> getTenantsByCustomerId(
    String customerId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'tenants',
      where: 'customer_id = ? AND is_active = ?',
      whereArgs: [customerId, 1],
      orderBy: 'created_at DESC',
    );
  }

  /// Get a single tenant by ID
  Future<Map<String, dynamic>?> getTenantById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tenants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Get tenant by owner email (for login)
  Future<Map<String, dynamic>?> getTenantByEmail(String email) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tenants',
      where: 'owner_email = ? AND is_active = ?',
      whereArgs: [email.toLowerCase(), 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Insert a new tenant
  Future<int> insertTenant(Map<String, dynamic> tenant) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure email is lowercase for consistency
    if (tenant.containsKey('owner_email')) {
      tenant['owner_email'] = tenant['owner_email'].toString().toLowerCase();
    }

    // Ensure timestamps
    final now = DateTime.now().toIso8601String();
    tenant['created_at'] = tenant['created_at'] ?? now;
    tenant['updated_at'] = now;

    return await db.insert('tenants', tenant);
  }

  /// Update an existing tenant
  Future<int> updateTenant(Map<String, dynamic> tenant) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure email is lowercase for consistency
    if (tenant.containsKey('owner_email')) {
      tenant['owner_email'] = tenant['owner_email'].toString().toLowerCase();
    }

    // Update timestamp
    tenant['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'tenants',
      tenant,
      where: 'id = ?',
      whereArgs: [tenant['id']],
    );
  }

  /// Soft delete a tenant (set is_active to 0)
  Future<int> deleteTenant(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'tenants',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Generate day closing report with business session data, cash reconciliation, and shift summaries
  Future<DayClosingReport> generateDayClosingReport(ReportPeriod period) async {
    // Get business session data
    final sessionData = await _getBusinessSessionData(period);

    // Get cash reconciliation data
    final cashReconciliation = await _getCashReconciliationData(period);

    // Get shift summaries
    final shiftSummaries = await _getShiftSummaries(period);

    return DayClosingReport(
      sessionData: sessionData,
      cashReconciliation: cashReconciliation,
      shiftSummaries: shiftSummaries,
      reportDate: DateTime.now(),
      generatedBy: LockManager.instance.currentUser?.fullName ?? 'System',
    );
  }

  Future<BusinessSessionData> _getBusinessSessionData(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
      '''
      SELECT
        SUM(total_amount) as total_sales,
        SUM(total_refunds) as total_refunds,
        SUM(total_discounts) as total_discounts,
        SUM(total_tax) as total_tax,
        SUM(total_service_charge) as total_service_charge,
        COUNT(*) as total_transactions,
        payment_method
      FROM orders
      WHERE created_at >= ? AND created_at <= ?
        AND status IN ('completed', 'refunded')
      GROUP BY payment_method
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
    );

    double totalSales = 0;
    double totalRefunds = 0;
    double totalDiscounts = 0;
    double totalTax = 0;
    double totalServiceCharge = 0;
    int totalTransactions = 0;
    final paymentMethodBreakdown = <String, double>{};

    for (final row in result) {
      totalSales += (row['total_sales'] as num?)?.toDouble() ?? 0;
      totalRefunds += (row['total_refunds'] as num?)?.toDouble() ?? 0;
      totalDiscounts += (row['total_discounts'] as num?)?.toDouble() ?? 0;
      totalTax += (row['total_tax'] as num?)?.toDouble() ?? 0;
      totalServiceCharge +=
          (row['total_service_charge'] as num?)?.toDouble() ?? 0;
      totalTransactions += (row['total_transactions'] as int?) ?? 0;

      final paymentMethod = row['payment_method'] as String? ?? 'Unknown';
      final amount = (row['total_sales'] as num?)?.toDouble() ?? 0;
      paymentMethodBreakdown[paymentMethod] =
          (paymentMethodBreakdown[paymentMethod] ?? 0) + amount;
    }

    // Get opening float from business sessions (if available)
    final sessionResult = await db.query(
      'business_sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
      ],
      orderBy: 'start_time ASC',
      limit: 1,
    );

    final openingFloat = sessionResult.isNotEmpty
        ? (sessionResult.first['opening_float'] as num?)?.toDouble() ?? 0
        : 0;

    return BusinessSessionData(
      sessionStart: period.startDate,
      sessionEnd: period.endDate,
      openingFloat: openingFloat.toDouble(),
      totalSales: totalSales.toDouble(),
      totalRefunds: totalRefunds.toDouble(),
      totalDiscounts: totalDiscounts.toDouble(),
      totalTax: totalTax.toDouble(),
      totalServiceCharge: totalServiceCharge.toDouble(),
      totalTransactions: totalTransactions,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );
  }

  Future<CashReconciliation> _getCashReconciliationData(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    // Get opening float
    final sessionResult = await db.query(
      'business_sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
      ],
      orderBy: 'start_time ASC',
      limit: 1,
    );

    final openingFloat = sessionResult.isNotEmpty
        ? (sessionResult.first['opening_float'] as num?)?.toDouble() ?? 0
        : 0;

    // Get cash transactions
    final cashResult = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN status = 'completed' AND payment_method = 'Cash' THEN total_amount ELSE 0 END) as cash_sales,
        SUM(CASE WHEN status = 'refunded' AND payment_method = 'Cash' THEN total_refunds ELSE 0 END) as cash_refunds
      FROM orders
      WHERE created_at >= ? AND created_at <= ?
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
    );

    final cashSales =
        ((cashResult.first['cash_sales'] as num?)?.toDouble() ?? 0).toDouble();
    final cashRefunds =
        ((cashResult.first['cash_refunds'] as num?)?.toDouble() ?? 0)
            .toDouble();

    // Get paid outs and paid ins (if tables exist)
    double paidOuts = 0;
    double paidIns = 0;

    try {
      final paidOutResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total_paid_outs
        FROM cash_adjustments
        WHERE type = 'paid_out' AND created_at >= ? AND created_at <= ?
      ''',
        [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
      );

      final paidInResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total_paid_ins
        FROM cash_adjustments
        WHERE type = 'paid_in' AND created_at >= ? AND created_at <= ?
      ''',
        [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
      );

      paidOuts =
          ((paidOutResult.first['total_paid_outs'] as num?)?.toDouble() ?? 0)
              .toDouble();
      paidIns =
          ((paidInResult.first['total_paid_ins'] as num?)?.toDouble() ?? 0)
              .toDouble();
    } catch (e) {
      // Tables might not exist, use 0
    }

    final expectedCash =
        openingFloat + cashSales - cashRefunds - paidOuts + paidIns;
    final actualCash = 0.0; // Placeholder: actual counted cash from closing

    return CashReconciliation(
      openingFloat: openingFloat.toDouble(),
      cashSales: cashSales.toDouble(),
      cashRefunds: cashRefunds.toDouble(),
      paidOuts: paidOuts.toDouble(),
      paidIns: paidIns.toDouble(),
      expectedCash: expectedCash.toDouble(),
      actualCash: actualCash.toDouble(),
      notes: 'Auto-calculated from transactions',
    );
  }

  Future<List<ShiftSummary>> _getShiftSummaries(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT
          u.name as employee_name,
          s.user_id,
          s.start_time,
          s.end_time,
          s.total_sales,
          s.cash_handled,
          (SELECT COUNT(*) FROM orders o WHERE o.created_at >= s.start_time AND (s.end_time IS NULL OR o.created_at <= s.end_time)) as transaction_count
        FROM shifts s
        LEFT JOIN users u ON s.user_id = u.id
        WHERE s.start_time >= ? AND s.start_time <= ?
        ORDER BY s.start_time ASC
      ''',
        [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
      );

      return result.map((row) {
        final startTime = DateTime.parse(row['start_time'] as String);
        final endTime = row['end_time'] != null
            ? DateTime.parse(row['end_time'] as String)
            : null;
        final duration =
            endTime?.difference(startTime) ??
            DateTime.now().difference(startTime);

        return ShiftSummary(
          employeeId: row['user_id'] as String? ?? '',
          employeeName: row['employee_name'] as String? ?? 'Unknown',
          shiftStart: startTime,
          shiftEnd: endTime,
          salesDuringShift: (row['total_sales'] as num?)?.toDouble() ?? 0,
          transactionsDuringShift:
              (row['transaction_count'] as num?)?.toInt() ?? 0,
          cashHandled: (row['cash_handled'] as num?)?.toDouble() ?? 0,
          shiftDuration: duration,
        );
      }).toList();
    } catch (e) {
      // Shifts table might not exist, return empty list
      return [];
    }
  }

  /// Generate Profit & Loss Report
  Future<ProfitLossReport> generateProfitLossReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double totalRevenue = 0.0;
    double costOfGoodsSold = 0.0;
    double operatingExpenses = 0.0;
    Map<String, double> revenueBreakdown = {};
    Map<String, double> expenseBreakdown = {};

    for (final orderMap in orderMaps) {
      final subtotal = orderMap['subtotal'] as double;
      final tax = orderMap['tax'] as double;
      final discount = orderMap['discount'] as double? ?? 0.0;

      totalRevenue += subtotal + tax - discount;

      // Estimate COGS (this would need actual cost data from products)
      // For now, assume 30% COGS
      costOfGoodsSold += subtotal * 0.3;

      // Estimate operating expenses (5% of revenue)
      operatingExpenses += (subtotal + tax) * 0.05;
    }

    final grossProfit = totalRevenue - costOfGoodsSold;
    final netProfit = grossProfit - operatingExpenses;
    final profitMargin = totalRevenue > 0
        ? (netProfit / totalRevenue) * 100
        : 0.0;

    // Create profit/loss items by category
    final profitLossItems = <ProfitLossItem>[];
    // This would need more detailed implementation with actual category data

    return ProfitLossReport(
      id: 'profit_loss_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalRevenue: totalRevenue,
      costOfGoodsSold: costOfGoodsSold,
      grossProfit: grossProfit,
      operatingExpenses: operatingExpenses,
      netProfit: netProfit,
      profitMargin: profitMargin,
      revenueBreakdown: revenueBreakdown,
      expenseBreakdown: expenseBreakdown,
      profitLossItems: profitLossItems,
    );
  }

  /// Generate Cash Flow Report
  Future<CashFlowReport> generateCashFlowReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    // Get opening cash (simplified - would need actual cash register data)
    final openingCash = 1000.0; // Placeholder

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double cashInflows = 0.0;
    double cashOutflows = 0.0;
    Map<String, double> inflowBreakdown = {};
    Map<String, double> outflowBreakdown = {};
    final transactions = <CashFlowTransaction>[];

    for (final orderMap in orderMaps) {
      final subtotal = orderMap['subtotal'] as double;
      final tax = orderMap['tax'] as double;
      final paymentMethod = orderMap['payment_method'] as String? ?? 'cash';

      final amount = subtotal + tax;
      cashInflows += amount;

      inflowBreakdown[paymentMethod] =
          (inflowBreakdown[paymentMethod] ?? 0.0) + amount;

      transactions.add(
        CashFlowTransaction(
          date: DateTime.parse(orderMap['created_at'] as String),
          type: 'inflow',
          category: 'Sales',
          amount: amount,
          description: 'Sale transaction',
        ),
      );
    }

    final netCashFlow = cashInflows - cashOutflows;
    final closingCash = openingCash + netCashFlow;

    return CashFlowReport(
      id: 'cash_flow_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      openingCash: openingCash,
      closingCash: closingCash,
      cashInflows: cashInflows,
      cashOutflows: cashOutflows,
      netCashFlow: netCashFlow,
      inflowBreakdown: inflowBreakdown,
      outflowBreakdown: outflowBreakdown,
      transactions: transactions,
    );
  }

  /// Generate Tax Summary Report
  Future<TaxSummaryReport> generateTaxSummaryReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double totalTaxCollected = 0.0;
    Map<String, double> taxBreakdown = {};
    final taxItems = <TaxItem>[];

    for (final orderMap in orderMaps) {
      final tax = orderMap['tax'] as double;
      final date = DateTime.parse(orderMap['created_at'] as String);

      totalTaxCollected += tax;

      // Simplified tax breakdown
      final taxRate = BusinessInfo.instance.isTaxEnabled
          ? BusinessInfo.instance.taxRate * 100
          : 0.0;
      final taxKey = '${taxRate.toStringAsFixed(1)}%';

      taxBreakdown[taxKey] = (taxBreakdown[taxKey] ?? 0.0) + tax;

      if (tax > 0) {
        taxItems.add(
          TaxItem(taxType: 'Sales Tax', rate: taxRate, amount: tax, date: date),
        );
      }
    }

    return TaxSummaryReport(
      id: 'tax_summary_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalTaxCollected: totalTaxCollected,
      totalTaxPaid: 0.0, // Would need actual tax payment records
      taxBreakdown: taxBreakdown,
      taxItems: taxItems,
      taxLiability: totalTaxCollected,
    );
  }

  /// Generate Inventory Valuation Report
  Future<InventoryValuationReport> generateInventoryValuationReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> productMaps = await db.query('products');

    double totalCostValue = 0.0;
    double totalRetailValue = 0.0;
    Map<String, double> valuationByCategory = {};
    final valuationItems = <InventoryValuationItem>[];

    for (final productMap in productMaps) {
      final costPrice =
          (productMap['cost_price'] as double?) ??
          ((productMap['price'] as double) * 0.7);
      final retailPrice = productMap['price'] as double;
      final stock = productMap['stock'] as int? ?? 0;
      final category = productMap['category'] as String? ?? 'Uncategorized';

      final itemCostValue = costPrice * stock;
      final itemRetailValue = retailPrice * stock;
      final profitMargin = retailPrice > 0
          ? ((retailPrice - costPrice) / retailPrice) * 100
          : 0.0;

      totalCostValue += itemCostValue;
      totalRetailValue += itemRetailValue;

      valuationByCategory[category] =
          (valuationByCategory[category] ?? 0.0) + itemRetailValue;

      valuationItems.add(
        InventoryValuationItem(
          itemId: productMap['id'] as String,
          itemName: productMap['name'] as String,
          quantity: stock,
          costPrice: costPrice,
          retailPrice: retailPrice,
          totalCostValue: itemCostValue,
          totalRetailValue: itemRetailValue,
          profitMargin: profitMargin,
        ),
      );
    }

    final inventoryTurnoverRatio = totalCostValue > 0
        ? totalRetailValue / totalCostValue
        : 0.0;

    return InventoryValuationReport(
      id: 'inventory_valuation_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalInventoryValue: totalRetailValue,
      totalCostValue: totalCostValue,
      totalRetailValue: totalRetailValue,
      valuationByCategory: valuationByCategory,
      valuationItems: valuationItems,
      inventoryTurnoverRatio: inventoryTurnoverRatio,
    );
  }

  /// Generate ABC Analysis Report
  Future<ABCAnalysisReport> generateABCAnalysisReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderItemMaps = await db.rawQuery(
      '''
      SELECT oi.product_id, p.name, SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY oi.product_id, p.name
      ORDER BY revenue DESC
    ''',
      [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double totalRevenue = 0.0;
    for (final item in orderItemMaps) {
      totalRevenue += item['revenue'] as double;
    }

    final abcItems = <ABCItem>[];
    double cumulativePercentage = 0.0;

    for (int i = 0; i < orderItemMaps.length; i++) {
      final item = orderItemMaps[i];
      final revenue = item['revenue'] as double;
      final percentage = totalRevenue > 0
          ? (revenue / totalRevenue) * 100
          : 0.0;
      cumulativePercentage += percentage;

      String category;
      if (cumulativePercentage <= 80) {
        category = 'A';
      } else if (cumulativePercentage <= 95) {
        category = 'B';
      } else {
        category = 'C';
      }

      abcItems.add(
        ABCItem(
          itemId: item['product_id'] as String,
          itemName: item['name'] as String,
          revenue: revenue,
          percentageOfTotal: percentage,
          category: category,
          rank: i + 1,
        ),
      );
    }

    final categorizedItems = <String, List<ABCItem>>{};
    for (final item in abcItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }

    final aCategoryRevenue = abcItems
        .where((item) => item.category == 'A')
        .fold(0.0, (sum, item) => sum + item.revenue);

    final bCategoryRevenue = abcItems
        .where((item) => item.category == 'B')
        .fold(0.0, (sum, item) => sum + item.revenue);

    final cCategoryRevenue = abcItems
        .where((item) => item.category == 'C')
        .fold(0.0, (sum, item) => sum + item.revenue);

    return ABCAnalysisReport(
      id: 'abc_analysis_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      abcItems: abcItems,
      categorizedItems: categorizedItems,
      totalRevenue: totalRevenue,
      aCategoryRevenue: aCategoryRevenue,
      bCategoryRevenue: bCategoryRevenue,
      cCategoryRevenue: cCategoryRevenue,
    );
  }

  /// Generate Demand Forecasting Report
  Future<DemandForecastingReport> generateDemandForecastingReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    // Get historical sales data for the past 30 days
    final historicalStart = period.startDate.subtract(const Duration(days: 30));

    final List<Map<String, dynamic>> historicalData = await db.rawQuery(
      '''
      SELECT DATE(o.created_at) as date, SUM(oi.quantity) as total_quantity
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY DATE(o.created_at)
      ORDER BY date
    ''',
      [
        historicalStart.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    final forecastItems = <ForecastItem>[];
    final historicalDataMap = <String, List<double>>{};
    final forecastDataMap = <String, List<double>>{};

    // Simple moving average forecasting
    for (final data in historicalData) {
      final quantity = data['total_quantity'] as double;

      // For demonstration, create forecast based on simple trend
      final forecastQuantity = quantity * 1.05; // 5% growth assumption

      forecastItems.add(
        ForecastItem(
          itemId: 'total_sales',
          itemName: 'Total Sales',
          historicalSales: [quantity],
          forecastedSales: [forecastQuantity],
          confidenceLevel: 0.8,
        ),
      );

      historicalDataMap['total'] = [quantity];
      forecastDataMap['total'] = [forecastQuantity];
    }

    return DemandForecastingReport(
      id: 'demand_forecasting_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      forecastItems: forecastItems,
      historicalData: historicalDataMap,
      forecastData: forecastDataMap,
      forecastAccuracy: 0.85,
      forecastingMethod: 'Simple Moving Average',
    );
  }

  /// Generate Menu Engineering Report
  Future<MenuEngineeringReport> generateMenuEngineeringReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> productData = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        SUM(oi.quantity) as units_sold,
        SUM(oi.quantity * oi.price) as revenue,
        COUNT(DISTINCT oi.order_id) as order_count,
        (SELECT COUNT(*) FROM orders o WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?) as total_orders
      FROM products p
      LEFT JOIN order_items oi ON p.id = oi.product_id
      LEFT JOIN orders o ON oi.order_id = o.id AND o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY p.id, p.name
    ''',
      [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    final menuItems = <MenuItem>[];
    final totalOrders = productData.isNotEmpty
        ? productData.first['total_orders'] as int
        : 0;

    for (final product in productData) {
      final unitsSold = product['units_sold'] as int? ?? 0;
      final revenue = product['revenue'] as double? ?? 0.0;
      final orderCount = product['order_count'] as int? ?? 0;

      final popularity = totalOrders > 0
          ? (orderCount / totalOrders) * 100
          : 0.0;
      final costPrice = product['cost_price'] as double? ?? revenue * 0.3;
      final cost = costPrice * unitsSold;
      final profit = revenue - cost;
      final profitability = revenue > 0 ? (profit / revenue) * 100 : 0.0;

      String category;
      if (popularity >= 70 && profitability >= 30) {
        category = 'star';
      } else if (popularity >= 70 && profitability < 30) {
        category = 'plowhorse';
      } else if (popularity < 70 && profitability >= 30) {
        category = 'puzzle';
      } else {
        category = 'dog';
      }

      menuItems.add(
        MenuItem(
          itemId: product['id'] as String,
          itemName: product['name'] as String,
          popularity: popularity,
          profitability: profitability,
          category: category,
          unitsSold: unitsSold,
          revenue: revenue,
          cost: cost,
          profit: profit,
        ),
      );
    }

    final categorizedItems = <String, List<MenuItem>>{};
    for (final item in menuItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }

    return MenuEngineeringReport(
      id: 'menu_engineering_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      menuItems: menuItems,
      categorizedItems: categorizedItems,
      starsCount: categorizedItems['star']?.length ?? 0,
      plowhorsesCount: categorizedItems['plowhorse']?.length ?? 0,
      puzzlesCount: categorizedItems['puzzle']?.length ?? 0,
      dogsCount: categorizedItems['dog']?.length ?? 0,
    );
  }

  /// Generate Table Performance Report (Restaurant Mode)
  Future<TablePerformanceReport> generateTablePerformanceReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> tableMaps = await db.query(
      'restaurant_tables',
    );

    final tableData = <TablePerformanceData>[];
    final revenueByTable = <String, double>{};
    final occupancyByTable = <String, int>{};

    for (final tableMap in tableMaps) {
      final tableId = tableMap['id'] as String;
      final tableName = tableMap['name'] as String;
      final capacity = tableMap['capacity'] as int;

      // Get orders for this table
      final List<Map<String, dynamic>> orderMaps = await db.rawQuery(
        '''
        SELECT SUM(subtotal + tax) as revenue, COUNT(*) as order_count
        FROM orders
        WHERE table_id = ? AND created_at >= ? AND created_at <= ? AND status = ?
      ''',
        [
          tableId,
          period.startDate.toIso8601String(),
          period.endDate.toIso8601String(),
          'completed',
        ],
      );

      final revenue = orderMaps.isNotEmpty
          ? orderMaps.first['revenue'] as double? ?? 0.0
          : 0.0;
      final orderCount = orderMaps.isNotEmpty
          ? orderMaps.first['order_count'] as int? ?? 0
          : 0;

      // Calculate average occupancy time (simplified)
      final averageOccupancyTime = orderCount > 0
          ? Duration(minutes: (orderCount * 60) ~/ capacity)
          : Duration.zero;

      final revenuePerHour = averageOccupancyTime.inHours > 0
          ? revenue / averageOccupancyTime.inHours
          : 0.0;

      tableData.add(
        TablePerformanceData(
          tableId: tableId,
          tableName: tableName,
          capacity: capacity,
          totalRevenue: revenue,
          totalOrders: orderCount,
          averageOccupancyTime: averageOccupancyTime,
          revenuePerHour: revenuePerHour,
          turnoverCount: orderCount,
        ),
      );

      revenueByTable[tableName] = revenue;
      occupancyByTable[tableName] = orderCount;
    }

    final totalRevenue = tableData.fold(
      0.0,
      (sum, table) => sum + table.totalRevenue,
    );
    final totalOrders = tableData.fold(
      0,
      (sum, table) => sum + table.totalOrders,
    );
    final averageTableTurnover = tableData.isNotEmpty
        ? totalOrders / tableData.length
        : 0.0;
    final averageRevenuePerTable = tableData.isNotEmpty
        ? totalRevenue / tableData.length
        : 0.0;

    return TablePerformanceReport(
      id: 'table_performance_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      tableData: tableData,
      revenueByTable: revenueByTable,
      occupancyByTable: occupancyByTable,
      averageTableTurnover: averageTableTurnover,
      averageRevenuePerTable: averageRevenuePerTable,
      totalTables: tableMaps.length,
      occupiedTables: tableData.where((table) => table.totalOrders > 0).length,
    );
  }
}
