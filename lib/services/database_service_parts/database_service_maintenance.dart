part of '../database_service.dart';

extension DatabaseServiceMaintenance on DatabaseService {
  /// Process a refund for an order
  Future<bool> processRefund({
    required String orderId,
    required double refundAmount,
    required String refundMethodId,
    required String reason,
    required String userId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        final nowIso = DateTime.now().toIso8601String();
        final refundId = const Uuid().v4();
        await txn.insert('transactions', {
          'id': refundId,
          'order_id': orderId,
          'payment_method_id': refundMethodId,
          'amount': -refundAmount,
          'change_amount': 0.0,
          'transaction_date': nowIso,
          'receipt_number': 'REFUND-${orderId.substring(0, 8)}',
          'created_at': nowIso,
        });
        await txn.update('orders', {'status': 'refunded', 'notes': reason, 'updated_at': nowIso}, where: 'id = ?', whereArgs: [orderId]);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get database statistics for maintenance screen
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await DatabaseHelper.instance.database;
    final stats = <String, dynamic>{};
    for (final table in ['orders', 'order_items', 'transactions', 'products', 'categories']) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats['${table}_count'] = result.first['count'] as int? ?? 0;
    }
    try {
      final file = File(await DatabaseHelper.instance.getDatabasePath());
      if (await file.exists()) stats['database_size_mb'] = (await file.length()) / (1024 * 1024);
    } catch (_) { stats['database_size_mb'] = 0.0; }
    return stats;
  }

  Future<void> clearCache() async {}
  Future<void> optimizeDatabase() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('VACUUM');
    await db.execute('ANALYZE');
  }
  Future<String> exportLogs() async => 'Log export not implemented yet';
  Future<void> resetSettings() async {}
}
