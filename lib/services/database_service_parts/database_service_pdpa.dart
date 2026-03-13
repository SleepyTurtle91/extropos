part of '../database_service.dart';

extension DatabaseServicePDPA on DatabaseService {
  /// Save audit log entry
  Future<void> saveAuditLog(AuditLog log) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('audit_log', {
      'id': log.id,
      'user_id': log.userId,
      'action': log.action,
      'entity_type': 'customer', // Default for PDPA logs
      'entity_id': log.customerId,
      'new_values': jsonEncode(log.details),
      'ip_address': log.ipAddress,
      'created_at': log.timestamp.toIso8601String(),
    });
  }

  /// Record customer consent
  Future<void> saveConsent(String customerId, String type, bool granted) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('customer_consents', {
      'id': const Uuid().v4(),
      'customer_id': customerId,
      'consent_type': type,
      'granted': granted ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all consents for a customer
  Future<Map<String, bool>> getConsents(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_consents',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    final Map<String, bool> results = {};
    for (final map in maps) {
      results[map['consent_type'] as String] = (map['granted'] as int) == 1;
    }
    return results;
  }

  /// Create a data deletion request
  Future<void> createDeletionRequest(String customerId, String reason) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('data_deletion_requests', {
      'id': const Uuid().v4(),
      'customer_id': customerId,
      'status': 'pending',
      'requested_at': DateTime.now().toIso8601String(),
      'reason': reason,
    });
  }

  /// Get audit logs from database
  Future<List<AuditLog>> getAuditLogsFromDb({
    DateTime? start,
    DateTime? end,
    String? userId,
    String? customerId,
    String? action,
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (start != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(end.toIso8601String());
    }
    if (userId != null) {
      whereClauses.add('user_id = ?');
      whereArgs.add(userId);
    }
    if (customerId != null) {
      whereClauses.add('entity_id = ?');
      whereArgs.add(customerId);
    }
    if (action != null) {
      whereClauses.add('action = ?');
      whereArgs.add(action);
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM audit_log $whereString ORDER BY created_at DESC',
      whereArgs,
    );

    return maps.map((m) => AuditLog(
      id: m['id'] as String,
      userId: m['user_id'] as String? ?? 'unknown',
      action: m['action'] as String,
      details: jsonDecode(m['new_values'] as String? ?? '{}') as Map<String, dynamic>,
      customerId: m['entity_id'] as String?,
      ipAddress: m['ip_address'] as String? ?? 'unknown',
      timestamp: DateTime.parse(m['created_at'] as String),
    )).toList();
  }

  /// Perform actual data deletion/anonymization
  Future<void> performCustomerDataDeletion(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Anonymize customer in orders
      await txn.update('orders', {
        'customer_name': 'ANONYMIZED',
        'customer_phone': null,
        'customer_email': null,
        'special_instructions': null,
      }, where: 'customer_phone = (SELECT phone FROM customers WHERE id = ?)', 
         whereArgs: [customerId]);

      // 2. Delete from customer_consents
      await txn.delete('customer_consents', where: 'customer_id = ?', whereArgs: [customerId]);

      // 3. Mark deletion request as completed
      await txn.update('data_deletion_requests', {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }, where: 'customer_id = ? AND status = ?', whereArgs: [customerId, 'pending']);

      // 4. Delete the customer record itself
      await txn.delete('customers', where: 'id = ?', whereArgs: [customerId]);
    });
  }
}
