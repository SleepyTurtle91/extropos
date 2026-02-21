import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateReceiptTextWithSettings', () {
    final baseData = {
      'store_name': 'Test Shop',
      'address': ['Line 1', 'Line 2'],
      'title': 'RECEIPT',
      'date': '2025-11-18',
      'time': '10:00 AM',
      'customer': 'John',
      'bill_no': 'B123',
      'payment_mode': 'Cash',
      'dr_ref': 'REF1',
      'items': [
        {'name': 'Item 1', 'qty': 1, 'amt': 1.0},
      ],
      'sub_total_qty': 1,
      'sub_total_amt': 1.0,
      'discount': 0.0,
      'taxes': [
        {'name': 'Tax', 'amt': 0.1}
      ],
      'service_charge': 0.0,
      'total': 1.1,
      'cash': 1.1,
      'cash_tendered': 1.1,
      'currency': 'RM',
      'footer': 'Footer',
    };

    test('respects showDateTime setting', () {
      final settings = ReceiptSettings().copyWith(showDateTime: false);
      final result = generateReceiptTextWithSettings(data: baseData, settings: settings, charWidth: 48);
      expect(result.contains('Date :'), false, reason: 'Date should not be present when showDateTime is false');
    });

    test('respects showTaxBreakdown setting', () {
      final settings = ReceiptSettings().copyWith(showTaxBreakdown: true);
      final result = generateReceiptTextWithSettings(data: baseData, settings: settings, charWidth: 48);
      expect(result.contains('Tax'), true, reason: 'Tax should be present when showTaxBreakdown is true');
    });
  });
}
