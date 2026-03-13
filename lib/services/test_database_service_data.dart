part of 'test_database_service.dart';

extension TestDatabaseServiceData on TestDatabaseService {
  /// Insert sample categories
  Future<void> _insertSampleCategories() async {
    final categories = [
      {'id': 'test_cat_beverages', 'name': 'Beverages', 'description': 'Hot and cold drinks', 'icon_code_point': Icons.local_cafe.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFF8B4513).value, 'sort_order': 1, 'is_active': 1},
      {'id': 'test_cat_food', 'name': 'Food', 'description': 'Meals and main courses', 'icon_code_point': Icons.restaurant.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFFFF6B35).value, 'sort_order': 2, 'is_active': 1},
      {'id': 'test_cat_desserts', 'name': 'Desserts', 'description': 'Sweet treats and desserts', 'icon_code_point': Icons.cake.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFFF72585).value, 'sort_order': 3, 'is_active': 1},
      {'id': 'test_cat_appetizers', 'name': 'Appetizers', 'description': 'Starters and small plates', 'icon_code_point': Icons.restaurant_menu.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFF4CC9F0).value, 'sort_order': 4, 'is_active': 1},
      {'id': 'test_cat_merchandise', 'name': 'Merchandise', 'description': 'Retail products and merchandise', 'icon_code_point': Icons.shopping_bag.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFF4361EE).value, 'sort_order': 5, 'is_active': 1},
    ];
    for (final category in categories) { await _testDatabase!.insert('categories', category); }
  }

  /// Insert sample items
  Future<void> _insertSampleItems() async {
    final items = [
      {'id': 'test_item_espresso', 'name': 'Espresso', 'description': 'Strong coffee shot', 'category_id': 'test_cat_beverages', 'price': 3.50, 'cost': 0.80, 'sku': 'BEV-ESP-001', 'icon_code_point': Icons.coffee.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFF8B4513).value, 'stock': 100, 'is_available': 1, 'is_featured': 1, 'track_stock': 0, 'sort_order': 1},
      {'id': 'test_item_cappuccino', 'name': 'Cappuccino', 'description': 'Espresso with steamed milk foam', 'category_id': 'test_cat_beverages', 'price': 4.50, 'cost': 1.20, 'sku': 'BEV-CAP-001', 'icon_code_point': Icons.coffee.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFF8B4513).value, 'stock': 100, 'is_available': 1, 'is_featured': 1, 'track_stock': 0, 'sort_order': 2},
      {'id': 'test_item_latte', 'name': 'Latte', 'description': 'Espresso with steamed milk', 'category_id': 'test_cat_beverages', 'price': 4.75, 'cost': 1.50, 'sku': 'BEV-LAT-001', 'icon_code_point': Icons.coffee.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFF8B4513).value, 'stock': 100, 'is_available': 1, 'is_featured': 0, 'track_stock': 0, 'sort_order': 3},
      {'id': 'test_item_iced_tea', 'name': 'Iced Tea', 'description': 'Refreshing iced tea', 'category_id': 'test_cat_beverages', 'price': 2.50, 'cost': 0.50, 'sku': 'BEV-ITE-001', 'icon_code_point': Icons.local_drink.codePoint, 'icon_font_family': 'MaterialIcons', 'color_value': const Color(0xFF4CAF50).value, 'stock': 50, 'is_available': 1, 'is_featured': 0, 'track_stock': 1, 'sort_order': 4},
    ];
    for (final item in items) { await _testDatabase!.insert('items', item); }
  }

  /// Insert sample users
  Future<void> _insertSampleUsers() async {
    final users = [
      {'id': 'test_user_admin', 'username': 'admin', 'full_name': 'Administrator', 'email': 'admin@test.com', 'role': 'admin', 'pin': '1234', 'status': 'active', 'last_login_at': DateTime.now().toIso8601String(), 'phone_number': null},
      {'id': 'test_user_manager', 'username': 'manager', 'full_name': 'Manager', 'email': 'manager@test.com', 'role': 'manager', 'pin': '5678', 'status': 'active', 'last_login_at': null, 'phone_number': null},
      {'id': 'test_user_cashier1', 'username': 'cashier1', 'full_name': 'Cashier One', 'email': 'cashier1@test.com', 'role': 'cashier', 'pin': '1111', 'status': 'active', 'last_login_at': null, 'phone_number': null},
      {'id': 'test_user_cashier2', 'username': 'cashier2', 'full_name': 'Cashier Two', 'email': 'cashier2@test.com', 'role': 'cashier', 'pin': '2222', 'status': 'active', 'last_login_at': null, 'phone_number': null},
    ];
    for (final user in users) { await _testDatabase!.insert('users', user); }
  }

  /// Insert sample tables
  Future<void> _insertSampleTables() async {
    final tables = [
      {'id': 'test_table_1', 'name': 'Table 1', 'capacity': 2, 'status': 'available', 'occupied_since': null, 'customer_name': null},
      {'id': 'test_table_2', 'name': 'Table 2', 'capacity': 4, 'status': 'available', 'occupied_since': null, 'customer_name': null},
      {'id': 'test_table_3', 'name': 'Table 3', 'capacity': 6, 'status': 'available', 'occupied_since': null, 'customer_name': null},
      {'id': 'test_table_4', 'name': 'Table 4', 'capacity': 2, 'status': 'available', 'occupied_since': null, 'customer_name': null},
      {'id': 'test_table_5', 'name': 'Bar Counter', 'capacity': 8, 'status': 'available', 'occupied_since': null, 'customer_name': null},
    ];
    for (final table in tables) { await _testDatabase!.insert('tables', table); }
  }

  /// Insert sample payment methods
  Future<void> _insertSamplePaymentMethods() async {
    final paymentMethods = [
      {'id': 'test_pm_cash', 'name': 'Cash', 'status': 'active', 'is_default': 1},
      {'id': 'test_pm_card', 'name': 'Credit Card', 'status': 'active', 'is_default': 0},
      {'id': 'test_pm_wallet', 'name': 'Digital Wallet', 'status': 'active', 'is_default': 0},
    ];
    for (final pm in paymentMethods) { await _testDatabase!.insert('payment_methods', pm); }
  }

  /// Insert sample printers
  Future<void> _insertSamplePrinters() async {
    final now = DateTime.now().toIso8601String();
    final printers = [
      {'id': 'test_printer_receipt', 'name': 'Receipt Printer', 'type': 'receipt', 'connection_type': 'usb', 'ip_address': null, 'port': null, 'device_id': 'USB001', 'device_name': 'EPSON TM-T88V', 'is_default': 1, 'is_active': 1, 'paper_size': 'mm58', 'status': 'offline', 'has_permission': 1, 'categories': '[]', 'created_at': now, 'updated_at': now},
      {'id': 'test_printer_kitchen', 'name': 'Kitchen Printer', 'type': 'kitchen', 'connection_type': 'network', 'ip_address': '192.168.1.100', 'port': 9100, 'device_id': null, 'device_name': 'Star Micronics TSP100', 'is_default': 0, 'is_active': 1, 'paper_size': 'mm80', 'status': 'offline', 'has_permission': 1, 'categories': '["food","beverages"]', 'created_at': now, 'updated_at': now},
    ];
    for (final printer in printers) { await _testDatabase!.insert('printers', printer); }
  }

  /// Insert sample customer displays
  Future<void> _insertSampleCustomerDisplays() async {
    final displays = [{'id': 'test_display_main', 'name': 'Main Customer Display', 'connection_type': 'network', 'ip_address': '192.168.1.101', 'port': 8080, 'status': 'offline', 'is_default': 1, 'is_active': 1, 'has_permission': 1},];
    for (final display in displays) { await _testDatabase!.insert('customer_displays', display); }
  }

  /// Insert sample business info
  Future<void> _insertSampleBusinessInfo() async {
    final businessInfo = {'id': 1, 'business_name': 'FlutterPOS Test Restaurant', 'owner_name': 'Test Owner', 'email': 'test@flutterpos.com', 'phone': '+1 (555) 123-4567', 'address': '123 Test Street', 'city': 'Test City', 'state': 'Test State', 'postcode': '12345', 'country': 'Malaysia', 'registration_number': 'REG123456789', 'tax_number': 'TAX123456789', 'tax_rate': 0.06, 'is_tax_enabled': 1, 'currency_symbol': 'RM', 'is_service_charge_enabled': 1, 'service_charge_rate': 0.10, 'logo_path': null,};
    await _testDatabase!.insert('business_info', businessInfo);
  }
}
