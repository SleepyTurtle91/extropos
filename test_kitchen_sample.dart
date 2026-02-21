import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/receipt_generator.dart';

void main() {
  final data = {
    'order_number': 'KOT-001',
    'order_type': 'restaurant',
    'table': 'Table 5',
    'customer_name': 'John Doe',
    'special_instructions': 'Extra spicy, no onions',
    'items': [
      {'name': 'Chicken Burger', 'quantity': 2, 'modifiers': 'Extra cheese, Well done'},
      {'name': 'French Fries', 'quantity': 1, 'modifiers': 'Large'},
      {'name': 'Coca Cola', 'quantity': 3, 'modifiers': ''},
    ],
  };

  final settings = ReceiptSettings(
    kitchenHeaderText: 'KITCHEN ORDER',
    kitchenShowDateTime: true,
    kitchenShowTable: true,
    kitchenShowOrderNumber: true,
    kitchenShowModifiers: true,
  );

  final result = generateKitchenOrderText(
    data: data,
    charWidth: 32,
    settings: settings,
  );

  print('=== CURRENT KITCHEN DOCKET FORMAT ===');
  print(result);
  print('=====================================');
}
