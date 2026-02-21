import 'package:extropos/data/pos_seed.dart';
import 'package:extropos/services/database_helper.dart';
// product model only used via sampleProducts import

class PosSeedService {
  /// Seed sample products into the local DB if items table is empty.
  static Future<void> seedIfNeeded() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final countRows = await db.rawQuery('SELECT COUNT(*) as c FROM items');
      final count = (countRows.isNotEmpty ? (countRows.first['c'] as int?) : null) ?? 0;
      if (count > 0) return;

      // Insert categories first
      final categories = <String>{};
      for (final p in sampleProducts) {
        categories.add(p.category);
      }

      final now = DateTime.now().toIso8601String();
      for (final cat in categories) {
        final catId = 'cat_${cat.replaceAll(' ', '_').toLowerCase()}';
        await db.insert('categories', {
          'id': catId,
          'name': cat,
          'description': null,
          'icon_code_point': 0,
          'icon_font_family': 'MaterialIcons',
          'color_value': 0,
          'sort_order': 0,
          'is_active': 1,
          'tax_rate': 0.0,
          'created_at': now,
          'updated_at': now,
        });
      }

      // Insert items
      int idx = 0;
      for (final p in sampleProducts) {
        final itemId = 'item_${DateTime.now().millisecondsSinceEpoch}_$idx';
        final catId = 'cat_${p.category.replaceAll(' ', '_').toLowerCase()}';
        await db.insert('items', {
          'id': itemId,
          'name': p.name,
          'description': null,
          'price': p.price,
          'category_id': catId,
          'sku': null,
          'barcode': null,
          'icon_code_point': p.icon.codePoint,
          'icon_font_family': p.icon.fontFamily ?? 'MaterialIcons',
          'color_value': 0,
          'is_available': 1,
          'is_featured': 0,
          'stock': 9999,
          'track_stock': 0,
          'low_stock_threshold': 5,
          'cost': null,
          'image_url': p.imagePath,
          'tags': null,
          'merchant_prices': '{}',
          'sort_order': 0,
          'printer_override': null,
          'created_at': now,
          'updated_at': now,
        });
        idx++;
      }
    } catch (e) {
      print('⚠️ PosSeedService.seedIfNeeded failed: $e');
    }
  }
}
