part of '../database_service.dart';

final Map<int, IconData> _materialIconMap = {
  Icons.category.codePoint: Icons.category,
  Icons.shopping_bag.codePoint: Icons.shopping_bag,
  Icons.local_cafe.codePoint: Icons.local_cafe,
  Icons.restaurant.codePoint: Icons.restaurant,
  Icons.cake.codePoint: Icons.cake,
  Icons.restaurant_menu.codePoint: Icons.restaurant_menu,
  Icons.coffee.codePoint: Icons.coffee,
  Icons.local_drink.codePoint: Icons.local_drink,
};

IconData _iconFromDb(int? codePoint, String? fontFamily) {
  if (codePoint == null) return Icons.shopping_bag;

  if (fontFamily != null &&
      fontFamily.isNotEmpty &&
      fontFamily != 'MaterialIcons') {
    return Icons.shopping_bag;
  }

  return _materialIconMap[codePoint] ?? Icons.shopping_bag;
}

Color _colorFromDb(int? colorValue) {
  if (colorValue == null) return Colors.blue;
  return Color(colorValue);
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

String _escapeCsv(String input) {
  final s = input.replaceAll('\r', '').replaceAll('\n', ' ');
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
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

  switch (connectionType) {
    case PrinterConnectionType.network:
      return Printer.network(
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
    case PrinterConnectionType.usb:
      return Printer.usb(
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
    case PrinterConnectionType.bluetooth:
      return Printer.bluetooth(
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
    case PrinterConnectionType.posmac:
      return Printer.posmac(
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
  }
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

extension DatabaseServiceProductsCategories on DatabaseService {
  Future<List<cat_model.Category>> getCategories() async {
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
        return cat_model.Category(
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
      developer.log(
        'Database error in getCategories: $e',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.high,
        category: ErrorCategory.database,
        message: 'Failed to load categories from database',
      );
      return [];
    }
  }

  Future<cat_model.Category?> getCategoryById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return cat_model.Category(
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

  Future<int> insertCategory(cat_model.Category category) async {
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

  Future<int> updateCategory(cat_model.Category category) async {
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

  Future<int> deleteCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'categories',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> permanentlyDeleteCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
