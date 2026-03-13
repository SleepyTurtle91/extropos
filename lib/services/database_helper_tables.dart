part of 'database_helper.dart';


extension DatabaseHelperTables on DatabaseHelper {
  Future<void> _createDB(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await _insertDefaultData(db);
    await _seedDefaultPaymentMethods(db);
  }

  // ─── Table creation ───────────────────────────────────────────────────────

  Future<void> _createTables(Database db) async {
    // Config domain: business info, receipt settings, payment methods,
    // printers, customer displays, restaurant tables.
    for (final sql in ConfigSchema.allTables) {
      await db.execute(sql);
    }

    // Catalog domain: categories, items, modifiers, discounts.
    for (final sql in CatalogSchema.allTables) {
      await db.execute(sql);
    }

    // User / staff domain: users, customers, shifts, activity log, audit log.
    for (final sql in UsersSchema.allTables) {
      await db.execute(sql);
    }

    // Orders / sales domain: orders, order_items, transactions, splits, inventory.
    for (final sql in OrdersSchema.allTables) {
      await db.execute(sql);
    }

    // Session domain: cash_sessions, business_sessions.
    for (final sql in SessionSchema.allTables) {
      await db.execute(sql);
    }

    // Multi-tenant / dealer domain: dealer_customers, tenants.
    for (final sql in TenantSchema.allTables) {
      await db.execute(sql);
    }

    // Inventory domain
    for (final sql in InventorySchema.allTables) {
      await db.execute(sql);
    }
  }

  // ─── Index creation ───────────────────────────────────────────────────────

  Future<void> _createIndexes(Database db) async {
    final allIndexes = [
      ...ConfigSchema.indexes,
      ...CatalogSchema.indexes,
      ...UsersSchema.indexes,
      ...OrdersSchema.indexes,
      ...SessionSchema.indexes,
      ...TenantSchema.indexes,
      ...InventorySchema.indexes,
    ];
    for (final sql in allIndexes) {
      await db.execute(sql);
    }
  }

  // ─── Seed data ────────────────────────────────────────────────────────────

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'business_info',
      ConfigSchema.defaultBusinessInfo(now),
    );

    await db.insert(
      'receipt_settings',
      ConfigSchema.defaultReceiptSettings(now),
    );

    await db.insert(
      'users',
      UsersSchema.defaultAdminUser(now),
    );
  }

  Future<void> _seedDefaultPaymentMethods(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final method in ConfigSchema.defaultPaymentMethods(now)) {
      await db.insert(
        'payment_methods',
        method,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
