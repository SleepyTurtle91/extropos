part of '../mock_database_service.dart';

extension RetailMockData on MockDatabaseService {
  Future<void> restoreRetailMockData() async {
    await _clearAllData();
    await _insertRetailCategories();
    await _insertRetailItems();
    await _insertRetailModifierGroups();
    await _insertRetailModifierItems();
    await _insertRetailTables();
    await _insertRetailUsers();
    await _insertRetailPaymentMethods();
    await _insertRetailPrinters();
  }

  Future<void> _insertRetailCategories() async {
    final categories = [
      Category(
        id: 'retail_cat_1',
        name: 'Food',
        description: 'Hot meals and main dishes',
        icon: Icons.restaurant,
        color: const Color(0xFFFF6B35),
        sortOrder: 1,
      ),
      Category(
        id: 'retail_cat_2',
        name: 'Beverages',
        description: 'Hot and cold drinks',
        icon: Icons.local_cafe,
        color: const Color(0xFF8B4513),
        sortOrder: 2,
      ),
      Category(
        id: 'retail_cat_3',
        name: 'Snacks',
        description: 'Light bites and appetizers',
        icon: Icons.fastfood,
        color: const Color(0xFFFFA500),
        sortOrder: 3,
      ),
      Category(
        id: 'retail_cat_4',
        name: 'Desserts',
        description: 'Sweet treats and desserts',
        icon: Icons.cake,
        color: const Color(0xFFF72585),
        sortOrder: 4,
      ),
    ];

    for (final category in categories) {
      await DatabaseService.instance.insertCategory(category);
    }
  }

  Future<void> _insertRetailItems() async {
    final items = [
      // Food items
      Item(
        id: 'retail_item_1',
        name: 'Chicken Burger',
        description: 'Grilled chicken burger with lettuce and tomato',
        categoryId: 'retail_cat_1',
        price: 12.99,
        icon: Icons.lunch_dining,
        color: const Color(0xFFFF6B35),
        stock: 50,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'retail_item_2',
        name: 'Beef Burger',
        description: 'Classic beef burger with cheese and bacon',
        categoryId: 'retail_cat_1',
        price: 15.99,
        icon: Icons.lunch_dining,
        color: const Color(0xFFFF6B35),
        stock: 45,
        isFeatured: true,
        trackStock: true,
        sortOrder: 2,
      ),
      Item(
        id: 'retail_item_3',
        name: 'Margherita Pizza',
        description: 'Classic pizza with tomato sauce, mozzarella, and basil',
        categoryId: 'retail_cat_1',
        price: 18.99,
        icon: Icons.local_pizza,
        color: const Color(0xFFFF6B35),
        stock: 30,
        isFeatured: false,
        trackStock: true,
        sortOrder: 3,
      ),
      Item(
        id: 'retail_item_4',
        name: 'Chicken Wings',
        description: 'Crispy fried chicken wings with buffalo sauce',
        categoryId: 'retail_cat_1',
        price: 14.99,
        icon: Icons.fastfood,
        color: const Color(0xFFFF6B35),
        stock: 40,
        isFeatured: false,
        trackStock: true,
        sortOrder: 4,
      ),

      // Beverage items
      Item(
        id: 'retail_item_5',
        name: 'Americano',
        description: 'Espresso with hot water',
        categoryId: 'retail_cat_2',
        price: 4.50,
        icon: Icons.coffee,
        color: const Color(0xFF8B4513),
        stock: 100,
        isFeatured: true,
        trackStock: false,
        sortOrder: 1,
      ),
      Item(
        id: 'retail_item_6',
        name: 'Cappuccino',
        description: 'Espresso with steamed milk and foam',
        categoryId: 'retail_cat_2',
        price: 5.50,
        icon: Icons.coffee,
        color: const Color(0xFF8B4513),
        stock: 100,
        isFeatured: true,
        trackStock: false,
        sortOrder: 2,
      ),
      Item(
        id: 'retail_item_7',
        name: 'Orange Juice',
        description: 'Freshly squeezed orange juice',
        categoryId: 'retail_cat_2',
        price: 6.99,
        icon: Icons.local_drink,
        color: const Color(0xFFFFA500),
        stock: 25,
        isFeatured: false,
        trackStock: true,
        sortOrder: 3,
      ),
      Item(
        id: 'retail_item_8',
        name: 'Soda',
        description: 'Carbonated soft drink',
        categoryId: 'retail_cat_2',
        price: 3.99,
        icon: Icons.local_drink,
        color: const Color(0xFF4169E1),
        stock: 80,
        isFeatured: false,
        trackStock: true,
        sortOrder: 4,
      ),

      // Snack items
      Item(
        id: 'retail_item_9',
        name: 'French Fries',
        description: 'Crispy golden french fries',
        categoryId: 'retail_cat_3',
        price: 7.99,
        icon: Icons.fastfood,
        color: const Color(0xFFFFD700),
        stock: 60,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'retail_item_10',
        name: 'Onion Rings',
        description: 'Crispy battered onion rings',
        categoryId: 'retail_cat_3',
        price: 8.99,
        icon: Icons.fastfood,
        color: const Color(0xFFFFD700),
        stock: 35,
        isFeatured: false,
        trackStock: true,
        sortOrder: 2,
      ),

      // Dessert items
      Item(
        id: 'retail_item_11',
        name: 'Chocolate Cake',
        description: 'Rich chocolate cake with frosting',
        categoryId: 'retail_cat_4',
        price: 9.99,
        icon: Icons.cake,
        color: const Color(0xFF8B4513),
        stock: 20,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'retail_item_12',
        name: 'Ice Cream Sundae',
        description: 'Vanilla ice cream with chocolate syrup and nuts',
        categoryId: 'retail_cat_4',
        price: 7.99,
        icon: Icons.icecream,
        color: const Color(0xFF87CEEB),
        stock: 30,
        isFeatured: false,
        trackStock: true,
        sortOrder: 2,
      ),
    ];

    for (final item in items) {
      await DatabaseService.instance.insertItem(item);
    }
  }

  Future<void> _insertRetailModifierGroups() async {
    final modifierGroups = [
      ModifierGroup(
        id: 'retail_mod_group_1',
        name: 'Burger Toppings',
        description: 'Additional toppings for burgers',
        categoryIds: ['retail_cat_1'], // Food category
        minSelection: 0,
        maxSelection: 3,
        isRequired: false,
        sortOrder: 1,
      ),
      ModifierGroup(
        id: 'retail_mod_group_2',
        name: 'Pizza Toppings',
        description: 'Additional toppings for pizza',
        categoryIds: ['retail_cat_1'], // Food category
        minSelection: 0,
        maxSelection: 5,
        isRequired: false,
        sortOrder: 2,
      ),
      ModifierGroup(
        id: 'retail_mod_group_3',
        name: 'Drink Size',
        description: 'Choose drink size',
        categoryIds: ['retail_cat_2'], // Beverages category
        minSelection: 1,
        maxSelection: 1,
        isRequired: true,
        sortOrder: 1,
      ),
    ];

    for (final group in modifierGroups) {
      await DatabaseService.instance.insertModifierGroup(group);
    }
  }

  Future<void> _insertRetailModifierItems() async {
    final modifierItems = [
      // Burger toppings
      ModifierItem(
        id: 'retail_mod_item_1',
        name: 'Extra Cheese',
        description: 'Add extra cheese',
        modifierGroupId: 'retail_mod_group_1',
        priceAdjustment: 1.50,
        sortOrder: 1,
      ),
      ModifierItem(
        id: 'retail_mod_item_2',
        name: 'Bacon',
        description: 'Add crispy bacon',
        modifierGroupId: 'retail_mod_group_1',
        priceAdjustment: 2.00,
        sortOrder: 2,
      ),
      ModifierItem(
        id: 'retail_mod_item_3',
        name: 'Avocado',
        description: 'Add fresh avocado',
        modifierGroupId: 'retail_mod_group_1',
        priceAdjustment: 1.75,
        sortOrder: 3,
      ),

      // Pizza toppings
      ModifierItem(
        id: 'retail_mod_item_4',
        name: 'Pepperoni',
        description: 'Add pepperoni slices',
        modifierGroupId: 'retail_mod_group_2',
        priceAdjustment: 2.50,
        sortOrder: 1,
      ),
      ModifierItem(
        id: 'retail_mod_item_5',
        name: 'Mushrooms',
        description: 'Add fresh mushrooms',
        modifierGroupId: 'retail_mod_group_2',
        priceAdjustment: 1.25,
        sortOrder: 2,
      ),
      ModifierItem(
        id: 'retail_mod_item_6',
        name: 'Olives',
        description: 'Add black olives',
        modifierGroupId: 'retail_mod_group_2',
        priceAdjustment: 1.00,
        sortOrder: 3,
      ),

      // Drink sizes
      ModifierItem(
        id: 'retail_mod_item_7',
        name: 'Small',
        description: '8oz serving',
        modifierGroupId: 'retail_mod_group_3',
        priceAdjustment: 0.00,
        sortOrder: 1,
      ),
      ModifierItem(
        id: 'retail_mod_item_8',
        name: 'Medium',
        description: '12oz serving',
        modifierGroupId: 'retail_mod_group_3',
        priceAdjustment: 0.50,
        sortOrder: 2,
      ),
      ModifierItem(
        id: 'retail_mod_item_9',
        name: 'Large',
        description: '16oz serving',
        modifierGroupId: 'retail_mod_group_3',
        priceAdjustment: 1.00,
        sortOrder: 3,
      ),
    ];

    for (final item in modifierItems) {
      await DatabaseService.instance.insertModifierItem(item);
    }
  }

  Future<void> _insertRetailTables() async {
    // Retail mode doesn't use tables, but we'll add a few for completeness
    final tables = [
      RestaurantTable(
        id: 'retail_table_1',
        name: 'Counter 1',
        capacity: 1,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'retail_table_2',
        name: 'Counter 2',
        capacity: 1,
        status: TableStatus.available,
      ),
    ];

    for (final table in tables) {
      await DatabaseService.instance.insertTable(table);
    }
  }

  Future<void> _insertRetailUsers() async {
    final users = [
      User(
        id: 'retail_user_1',
        username: 'john_manager',
        fullName: 'John Manager',
        email: 'manager@retailstore.com',
        pin: '1234',
        role: UserRole.manager,
        status: UserStatus.active,
      ),
      User(
        id: 'retail_user_2',
        username: 'sarah_cashier',
        fullName: 'Sarah Cashier',
        email: 'cashier@retailstore.com',
        pin: '5678',
        role: UserRole.cashier,
        status: UserStatus.active,
      ),
    ];

    for (final user in users) {
      await DatabaseService.instance.insertUser(user);
    }
  }

  Future<void> _insertRetailPaymentMethods() async {
    final paymentMethods = [
      PaymentMethod(id: 'retail_pm_1', name: 'Cash', isDefault: true),
      PaymentMethod(id: 'retail_pm_2', name: 'Credit Card', isDefault: false),
      PaymentMethod(id: 'retail_pm_3', name: 'Debit Card', isDefault: false),
      PaymentMethod(
        id: 'retail_pm_4',
        name: 'Mobile Payment',
        isDefault: false,
      ),
    ];

    for (final pm in paymentMethods) {
      await DatabaseService.instance.insertPaymentMethod(pm);
    }
  }

  Future<void> _insertRetailPrinters() async {
    final printers = [
      Printer(
        id: 'retail_printer_1',
        name: 'Kitchen Printer',
        type: PrinterType.kitchen,
        connectionType: PrinterConnectionType.network,
        ipAddress: '192.168.1.100',
        port: 9100,
        isDefault: true,
      ),
      Printer(
        id: 'retail_printer_2',
        name: 'Receipt Printer',
        type: PrinterType.receipt,
        connectionType: PrinterConnectionType.network,
        ipAddress: '192.168.1.101',
        port: 9100,
        isDefault: false,
      ),
    ];

    for (final printer in printers) {
      await DatabaseService.instance.savePrinter(printer);
    }
  }

}
