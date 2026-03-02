part of '../mock_database_service.dart';

extension RestaurantMockData on MockDatabaseService {
  Future<void> restoreRestaurantMockData() async {
    await _clearAllData();
    await _insertRestaurantCategories();
    await _insertRestaurantItems();
    await _insertRestaurantModifierGroups();
    await _insertRestaurantModifierItems();
    await _insertRestaurantTables();
    await _insertRestaurantUsers();
    await _insertRestaurantPaymentMethods();
    await _insertRestaurantPrinters();
  }

  Future<void> _insertRestaurantCategories() async {
    final categories = [
      Category(
        id: 'rest_cat_1',
        name: 'Appetizers',
        description: 'Starters and small plates',
        icon: Icons.restaurant_menu,
        color: const Color(0xFF4CAF50),
        sortOrder: 1,
      ),
      Category(
        id: 'rest_cat_2',
        name: 'Main Courses',
        description: 'Entrees and main dishes',
        icon: Icons.dinner_dining,
        color: const Color(0xFFFF6B35),
        sortOrder: 2,
      ),
      Category(
        id: 'rest_cat_3',
        name: 'Beverages',
        description: 'Drinks and refreshments',
        icon: Icons.local_bar,
        color: const Color(0xFF2196F3),
        sortOrder: 3,
      ),
      Category(
        id: 'rest_cat_4',
        name: 'Desserts',
        description: 'Sweet endings',
        icon: Icons.cake,
        color: const Color(0xFFE91E63),
        sortOrder: 4,
      ),
    ];

    for (final category in categories) {
      await DatabaseService.instance.insertCategory(category);
    }
  }

  Future<void> _insertRestaurantItems() async {
    final items = [
      // Appetizers
      Item(
        id: 'rest_item_1',
        name: 'Caesar Salad',
        description: 'Crisp romaine lettuce with caesar dressing and croutons',
        categoryId: 'rest_cat_1',
        price: 12.99,
        icon: Icons.restaurant_menu,
        color: const Color(0xFF4CAF50),
        stock: 100,
        isFeatured: true,
        trackStock: false,
        sortOrder: 1,
      ),
      Item(
        id: 'rest_item_2',
        name: 'Buffalo Wings',
        description: 'Crispy chicken wings with buffalo sauce',
        categoryId: 'rest_cat_1',
        price: 14.99,
        icon: Icons.fastfood,
        color: const Color(0xFFFF5722),
        stock: 80,
        isFeatured: true,
        trackStock: true,
        sortOrder: 2,
      ),
      Item(
        id: 'rest_item_3',
        name: 'Mozzarella Sticks',
        description: 'Breaded mozzarella cheese sticks with marinara sauce',
        categoryId: 'rest_cat_1',
        price: 10.99,
        icon: Icons.restaurant_menu,
        color: const Color(0xFFFFC107),
        stock: 60,
        isFeatured: false,
        trackStock: true,
        sortOrder: 3,
      ),

      // Main Courses
      Item(
        id: 'rest_item_4',
        name: 'Grilled Salmon',
        description: 'Fresh Atlantic salmon with lemon herb butter',
        categoryId: 'rest_cat_2',
        price: 28.99,
        icon: Icons.dinner_dining,
        color: const Color(0xFF2196F3),
        stock: 25,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'rest_item_5',
        name: 'Ribeye Steak',
        description: '12oz prime ribeye steak with garlic mashed potatoes',
        categoryId: 'rest_cat_2',
        price: 42.99,
        icon: Icons.dinner_dining,
        color: const Color(0xFF795548),
        stock: 15,
        isFeatured: true,
        trackStock: true,
        sortOrder: 2,
      ),
      Item(
        id: 'rest_item_6',
        name: 'Chicken Parmesan',
        description: 'Breaded chicken breast with marinara and mozzarella',
        categoryId: 'rest_cat_2',
        price: 24.99,
        icon: Icons.dinner_dining,
        color: const Color(0xFFFF6B35),
        stock: 30,
        isFeatured: false,
        trackStock: true,
        sortOrder: 3,
      ),
      Item(
        id: 'rest_item_7',
        name: 'Pasta Carbonara',
        description: 'Spaghetti with pancetta, egg, and parmesan cream sauce',
        categoryId: 'rest_cat_2',
        price: 22.99,
        icon: Icons.dinner_dining,
        color: const Color(0xFFFFEB3B),
        stock: 40,
        isFeatured: false,
        trackStock: true,
        sortOrder: 4,
      ),

      // Beverages
      Item(
        id: 'rest_item_8',
        name: 'House Wine',
        description: 'Red or white wine by the glass',
        categoryId: 'rest_cat_3',
        price: 8.99,
        icon: Icons.wine_bar,
        color: const Color(0xFF9C27B0),
        stock: 200,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'rest_item_9',
        name: 'Craft Beer',
        description: 'Local craft beer on tap',
        categoryId: 'rest_cat_3',
        price: 6.99,
        icon: Icons.local_bar,
        color: const Color(0xFFFF9800),
        stock: 150,
        isFeatured: true,
        trackStock: true,
        sortOrder: 2,
      ),
      Item(
        id: 'rest_item_10',
        name: 'Signature Cocktail',
        description: 'House special mixed drink',
        categoryId: 'rest_cat_3',
        price: 12.99,
        icon: Icons.local_bar,
        color: const Color(0xFFE91E63),
        stock: 100,
        isFeatured: false,
        trackStock: false,
        sortOrder: 3,
      ),

      // Desserts
      Item(
        id: 'rest_item_11',
        name: 'Tiramisu',
        description: 'Classic Italian dessert with coffee and mascarpone',
        categoryId: 'rest_cat_4',
        price: 9.99,
        icon: Icons.cake,
        color: const Color(0xFF8D6E63),
        stock: 20,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'rest_item_12',
        name: 'Chocolate Lava Cake',
        description: 'Warm chocolate cake with molten center',
        categoryId: 'rest_cat_4',
        price: 11.99,
        icon: Icons.cake,
        color: const Color(0xFF3E2723),
        stock: 15,
        isFeatured: true,
        trackStock: true,
        sortOrder: 2,
      ),
    ];

    for (final item in items) {
      await DatabaseService.instance.insertItem(item);
    }
  }

  Future<void> _insertRestaurantModifierGroups() async {
    final modifierGroups = [
      ModifierGroup(
        id: 'rest_mod_group_1',
        name: 'Cooking Temperature',
        description: 'How would you like your meat cooked?',
        categoryIds: ['rest_cat_2'], // Main courses
        minSelection: 1,
        maxSelection: 1,
        isRequired: true,
        sortOrder: 1,
      ),
      ModifierGroup(
        id: 'rest_mod_group_2',
        name: 'Salad Dressing',
        description: 'Choose your dressing',
        categoryIds: ['rest_cat_1'], // Appetizers
        minSelection: 1,
        maxSelection: 1,
        isRequired: true,
        sortOrder: 1,
      ),
      ModifierGroup(
        id: 'rest_mod_group_3',
        name: 'Extra Toppings',
        description: 'Additional ingredients',
        categoryIds: ['rest_cat_2'], // Main courses
        minSelection: 0,
        maxSelection: 4,
        isRequired: false,
        sortOrder: 2,
      ),
    ];

    for (final group in modifierGroups) {
      await DatabaseService.instance.insertModifierGroup(group);
    }
  }

  Future<void> _insertRestaurantModifierItems() async {
    final modifierItems = [
      // Cooking temperatures
      ModifierItem(
        id: 'rest_mod_item_1',
        name: 'Rare',
        description: 'Red center, warm outside',
        modifierGroupId: 'rest_mod_group_1',
        priceAdjustment: 0.00,
        sortOrder: 1,
      ),
      ModifierItem(
        id: 'rest_mod_item_2',
        name: 'Medium Rare',
        description: 'Pink center, warm outside',
        modifierGroupId: 'rest_mod_group_1',
        priceAdjustment: 0.00,
        sortOrder: 2,
      ),
      ModifierItem(
        id: 'rest_mod_item_3',
        name: 'Medium',
        description: 'Pink center, hot outside',
        modifierGroupId: 'rest_mod_group_1',
        priceAdjustment: 0.00,
        sortOrder: 3,
      ),
      ModifierItem(
        id: 'rest_mod_item_4',
        name: 'Medium Well',
        description: 'Slightly pink center',
        modifierGroupId: 'rest_mod_group_1',
        priceAdjustment: 0.00,
        sortOrder: 4,
      ),
      ModifierItem(
        id: 'rest_mod_item_5',
        name: 'Well Done',
        description: 'No pink, fully cooked',
        modifierGroupId: 'rest_mod_group_1',
        priceAdjustment: 0.00,
        sortOrder: 5,
      ),

      // Salad dressings
      ModifierItem(
        id: 'rest_mod_item_6',
        name: 'Ranch',
        description: 'Creamy ranch dressing',
        modifierGroupId: 'rest_mod_group_2',
        priceAdjustment: 0.00,
        sortOrder: 1,
      ),
      ModifierItem(
        id: 'rest_mod_item_7',
        name: 'Caesar',
        description: 'Classic caesar dressing',
        modifierGroupId: 'rest_mod_group_2',
        priceAdjustment: 0.00,
        sortOrder: 2,
      ),
      ModifierItem(
        id: 'rest_mod_item_8',
        name: 'Balsamic Vinaigrette',
        description: 'Tangy balsamic dressing',
        modifierGroupId: 'rest_mod_group_2',
        priceAdjustment: 0.00,
        sortOrder: 3,
      ),

      // Extra toppings
      ModifierItem(
        id: 'rest_mod_item_9',
        name: 'Extra Cheese',
        description: 'Add extra cheese',
        modifierGroupId: 'rest_mod_group_3',
        priceAdjustment: 2.50,
        sortOrder: 1,
      ),
      ModifierItem(
        id: 'rest_mod_item_10',
        name: 'Bacon',
        description: 'Add crispy bacon',
        modifierGroupId: 'rest_mod_group_3',
        priceAdjustment: 3.00,
        sortOrder: 2,
      ),
      ModifierItem(
        id: 'rest_mod_item_11',
        name: 'Mushrooms',
        description: 'Add sautéed mushrooms',
        modifierGroupId: 'rest_mod_group_3',
        priceAdjustment: 1.50,
        sortOrder: 3,
      ),
      ModifierItem(
        id: 'rest_mod_item_12',
        name: 'Truffle Oil',
        description: 'Add truffle oil drizzle',
        modifierGroupId: 'rest_mod_group_3',
        priceAdjustment: 4.00,
        sortOrder: 4,
      ),
    ];

    for (final item in modifierItems) {
      await DatabaseService.instance.insertModifierItem(item);
    }
  }

  Future<void> _insertRestaurantTables() async {
    final tables = [
      RestaurantTable(
        id: 'rest_table_1',
        name: 'Table 1',
        capacity: 2,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_2',
        name: 'Table 2',
        capacity: 2,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_3',
        name: 'Table 3',
        capacity: 4,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_4',
        name: 'Table 4',
        capacity: 4,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_5',
        name: 'Table 5',
        capacity: 6,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_6',
        name: 'Table 6',
        capacity: 6,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_7',
        name: 'Booth A',
        capacity: 4,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_8',
        name: 'Booth B',
        capacity: 4,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_9',
        name: 'Bar Seat 1',
        capacity: 1,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'rest_table_10',
        name: 'Bar Seat 2',
        capacity: 1,
        status: TableStatus.available,
      ),
    ];

    for (final table in tables) {
      await DatabaseService.instance.insertTable(table);
    }
  }

  Future<void> _insertRestaurantUsers() async {
    final users = [
      User(
        id: 'rest_user_1',
        username: 'maria_manager',
        fullName: 'Maria Manager',
        email: 'manager@restaurant.com',
        pin: '1111',
        role: UserRole.manager,
        status: UserStatus.active,
      ),
      User(
        id: 'rest_user_2',
        username: 'carlos_server',
        fullName: 'Carlos Server',
        email: 'server1@restaurant.com',
        pin: '2222',
        role: UserRole.waiter,
        status: UserStatus.active,
      ),
      User(
        id: 'rest_user_3',
        username: 'ana_server',
        fullName: 'Ana Server',
        email: 'server2@restaurant.com',
        pin: '3333',
        role: UserRole.waiter,
        status: UserStatus.active,
      ),
      User(
        id: 'rest_user_4',
        username: 'luis_bartender',
        fullName: 'Luis Bartender',
        email: 'bartender@restaurant.com',
        pin: '4444',
        role: UserRole.cashier,
        status: UserStatus.active,
      ),
    ];

    for (final user in users) {
      await DatabaseService.instance.insertUser(user);
    }
  }

  Future<void> _insertRestaurantPaymentMethods() async {
    final paymentMethods = [
      PaymentMethod(id: 'rest_pm_1', name: 'Cash', isDefault: true),
      PaymentMethod(id: 'rest_pm_2', name: 'Credit Card', isDefault: false),
      PaymentMethod(id: 'rest_pm_3', name: 'Debit Card', isDefault: false),
      PaymentMethod(id: 'rest_pm_4', name: 'Mobile Payment', isDefault: false),
      PaymentMethod(id: 'rest_pm_5', name: 'Restaurant Tab', isDefault: false),
    ];

    for (final pm in paymentMethods) {
      await DatabaseService.instance.insertPaymentMethod(pm);
    }
  }

  Future<void> _insertRestaurantPrinters() async {
    final printers = [
      Printer(
        id: 'rest_printer_1',
        name: 'Kitchen Printer',
        type: PrinterType.kitchen,
        connectionType: PrinterConnectionType.network,
        ipAddress: '192.168.1.200',
        port: 9100,
        isDefault: true,
      ),
      Printer(
        id: 'rest_printer_2',
        name: 'Bar Printer',
        type: PrinterType.bar,
        connectionType: PrinterConnectionType.network,
        ipAddress: '192.168.1.201',
        port: 9100,
        isDefault: false,
      ),
      Printer(
        id: 'rest_printer_3',
        name: 'Receipt Printer',
        type: PrinterType.receipt,
        connectionType: PrinterConnectionType.network,
        ipAddress: '192.168.1.202',
        port: 9100,
        isDefault: false,
      ),
    ];

    for (final printer in printers) {
      await DatabaseService.instance.savePrinter(printer);
    }
  }

}
