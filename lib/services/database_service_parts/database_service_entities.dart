part of '../database_service.dart';

/// Entities domain: Users, Dealers, Customers, Payment Methods
extension DatabaseServiceEntities on DatabaseService {
  // ==================== USERS ====================

  Future<List<User>> getUsers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      final id = maps[i]['id'].toString();
      final pinFromStore = PinStore.instance.getPinForUser(id);
      final pinFromDb = maps[i]['pin'] as String? ?? '';
      final pin = pinFromStore ?? pinFromDb;

      debugPrint(
        '🔐 getUsers() - User: $id, PinStore: $pinFromStore, DB: "$pinFromDb", Final: "$pin"',
      );

      return User(
        id: id,
        username: maps[i]['username'] as String? ?? '',
        fullName: maps[i]['name'] as String,
        email: maps[i]['email'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == (maps[i]['role'] as String),
          orElse: () => UserRole.cashier,
        ),
        pin: pin,
        status: (maps[i]['is_active'] as int) == 1
            ? UserStatus.active
            : UserStatus.inactive,
        lastLoginAt: maps[i]['last_login_at'] != null
            ? DateTime.parse(maps[i]['last_login_at'] as String)
            : null,
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
        phoneNumber: maps[i]['phone_number'] as String?,
      );
    });
  }

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
    final pin =
        PinStore.instance.getPinForUser(idStr) ?? (map['pin'] as String? ?? '');
    return User(
      id: idStr,
      username: map['username'] as String? ?? '',
      fullName: map['name'] as String,
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (map['role'] as String),
        orElse: () => UserRole.cashier,
      ),
      pin: pin,
      status: (map['is_active'] as int) == 1
          ? UserStatus.active
          : UserStatus.inactive,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      phoneNumber: map['phone_number'] as String?,
    );
  }

  Future<User?> findUserByPin(String pin) async {
    final users = await getUsers();
    try {
      return users.firstWhere((user) => user.pin == pin);
    } catch (e) {
      return null;
    }
  }

  Future<int> insertUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    bool pinStoredInHive = false;
    try {
      await PinStore.instance.setPinForUser(user.id, user.pin);
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

    return await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'name': user.fullName,
      'email': user.email,
      'phone_number': user.phoneNumber,
      'role': user.role.name,
      'is_active': user.status == UserStatus.active ? 1 : 0,
      'pin': pinToStore,
      'last_login_at': user.lastLoginAt?.toIso8601String(),
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    bool pinStoredInHive = false;
    try {
      await PinStore.instance.setPinForUser(user.id, user.pin);
      final storedPin = PinStore.instance.getPinForUser(user.id);
      if (storedPin != null && storedPin == user.pin) {
        pinStoredInHive = true;
      }
    } catch (e) {
      debugPrint('PinStore failed during update: $e');
    }

    return await db.update(
      'users',
      {
        'username': user.username,
        'name': user.fullName,
        'email': user.email,
        'phone_number': user.phoneNumber,
        'role': user.role.name,
        'is_active': user.status == UserStatus.active ? 1 : 0,
        'pin': pinStoredInHive ? '' : user.pin,
        'last_login_at': user.lastLoginAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

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

  // ==================== DEALERS & TENANTS ====================

  Future<List<Map<String, dynamic>>> getDealerCustomers() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'dealer_customers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'business_name ASC',
    );
  }

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

  Future<int> insertDealerCustomer(Map<String, dynamic> customer) async {
    final db = await DatabaseHelper.instance.database;

    if (customer.containsKey('email')) {
      customer['email'] = customer['email'].toString().toLowerCase();
    }

    final now = DateTime.now().toIso8601String();
    customer['created_at'] = customer['created_at'] ?? now;
    customer['updated_at'] = now;

    return await db.insert('dealer_customers', customer);
  }

  Future<int> updateDealerCustomer(Map<String, dynamic> customer) async {
    final db = await DatabaseHelper.instance.database;

    if (customer.containsKey('email')) {
      customer['email'] = customer['email'].toString().toLowerCase();
    }

    customer['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'dealer_customers',
      customer,
      where: 'id = ?',
      whereArgs: [customer['id']],
    );
  }

  Future<int> deleteDealerCustomer(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'dealer_customers',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<List<Map<String, dynamic>>> getTenants() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'tenants',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'tenant_name ASC',
    );
  }

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

  Future<int> insertTenant(Map<String, dynamic> tenant) async {
    final db = await DatabaseHelper.instance.database;

    if (tenant.containsKey('owner_email')) {
      tenant['owner_email'] = tenant['owner_email'].toString().toLowerCase();
    }

    final now = DateTime.now().toIso8601String();
    tenant['created_at'] = tenant['created_at'] ?? now;
    tenant['updated_at'] = now;

    return await db.insert('tenants', tenant);
  }

  Future<int> updateTenant(Map<String, dynamic> tenant) async {
    final db = await DatabaseHelper.instance.database;

    if (tenant.containsKey('owner_email')) {
      tenant['owner_email'] = tenant['owner_email'].toString().toLowerCase();
    }

    tenant['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'tenants',
      tenant,
      where: 'id = ?',
      whereArgs: [tenant['id']],
    );
  }

  Future<int> deleteTenant(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'tenants',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CUSTOMERS ====================

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

  Future<void> insertCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('customers', customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

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

  Future<void> deleteCustomer(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'customers',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  // ==================== PAYMENT METHODS ====================

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

  Future<int> deletePaymentMethod(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== BULK DELETIONS ====================

  Future<void> deleteAllSales() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions');
    await db.delete('order_items');
    await db.delete('orders');
  }

  Future<void> deleteAllModifierItems() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('item_modifiers');
    await db.delete('modifier_items');
  }

  Future<void> deleteAllModifierGroups() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_groups');
  }

  Future<void> deleteAllItems() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('items');
  }

  Future<void> deleteAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories');
  }

  Future<void> deleteAllTables() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tables');
  }

  Future<void> deleteAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('users');
  }

  Future<void> deleteAllPaymentMethods() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('payment_methods');
  }

  Future<void> deleteAllPrinters() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('printers');
  }
}
