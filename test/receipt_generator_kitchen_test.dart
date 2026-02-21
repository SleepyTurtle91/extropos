import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kitchen docket format', () {
    final data = {
      'order_number': 'Hyp-K-BE00006',
      'order_type': 'restaurant',
      'table': 'Table 1',
      'customer_name': 'Anurag Ghosh',
      'timestamp': '2016-08-04T18:13:00',
      'items': [
        {'name': 'Corona', 'quantity': 1, 'modifiers': ''},
        {'name': 'Diet Pepsi', 'quantity': 1, 'modifiers': ''},
        {
          'name': 'Passion Fruit Caprioska Zero',
          'quantity': 1,
          'modifiers': '',
        },
      ],
    };

    final settings = ReceiptSettings(
      kitchenHeaderText: 'KOT',
      kitchenShowDateTime: true,
      kitchenShowTable: true,
      kitchenShowOrderNumber: true,
    );

    final charWidth = 48;
    // Simulate printer setting header override
    data['order_header'] = 'Kitchen Order';
    final result = generateKitchenOrderText(
      data: data,
      charWidth: charWidth,
      settings: settings,
    );

    // Should use the data override header (Kitchen Order) instead of KOT
    expect(result.contains('KITCHEN ORDER'), true);
    expect(result.contains('Sl.No'), true);
    expect(result.contains('Item Name'), true);
    expect(result.contains('Qty.'), true);
    expect(result.contains('Total Items :'), true);
    expect(result.contains('Hyp-K-BE00006'), true);
    expect(result.contains('Anurag Ghosh'), true);
    expect(result.contains('Table No. : Table 1'), true);
  });

  test('Bar docket header override uses Bar Order', () {
    final data = {
      'order_number': 'BAR-001',
      'order_type': 'bar',
      'table': 'Bar 1',
      'customer_name': 'Jane Doe',
      'timestamp': '2016-08-04T18:13:00',
      'items': [
        {'name': 'Whiskey', 'quantity': 1, 'modifiers': ''},
      ],
      'order_header': 'Bar Order',
      'kitchen_template_style': 'standard',
    };

    final settings = ReceiptSettings(
      kitchenHeaderText: 'KOT',
      kitchenShowDateTime: true,
      kitchenShowTable: true,
      kitchenShowOrderNumber: true,
    );

    final charWidth = 48;
    final result = generateKitchenOrderText(
      data: data,
      charWidth: charWidth,
      settings: settings,
    );
    expect(result.contains('BAR ORDER'), true);
    expect(result.contains('Sl.No'), true);
    expect(result.contains('Whiskey'), true);
  });
}
