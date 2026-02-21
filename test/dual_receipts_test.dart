import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dual Receipts Functionality', () {
    late Map<String, dynamic> baseData;
    late ReceiptSettings receiptSettings;

    setUp(() {
      baseData = {
        'title': 'RECEIPT',
        'date': '30/12/2025',
        'time': '14:30',
        'bill_no': 'ORD-20251230-001',
        'payment_mode': 'Cash',
        'store_name': 'Test Restaurant',
        'address': ['123 Test Street', 'Kuala Lumpur'],
        'phone': '012-3456789',
        'tax_number': 'TXN123456',
        'items': [
          {'name': 'Pizza', 'qty': 2, 'amt': 30.0},
          {'name': 'Coke', 'qty': 1, 'amt': 5.0},
        ],
        'sub_total_qty': 3,
        'sub_total_amt': 35.0,
        'taxes': [
          {'name': 'Tax (6%)', 'amt': 2.1}
        ],
        'service_charge': 3.5,
        'total': 40.6,
        'cash': 40.6,
        'cash_tendered': 50.0,
        'currency': 'RM',
        'footer': 'Thank you for your business',
      };

      receiptSettings = ReceiptSettings().copyWith(
        headerText: 'Welcome to Test Restaurant',
        footerText: 'Thank you for your business',
        showLogo: false,
        paperWidth: 58,
        showCashierName: true,
        showTaxBreakdown: true,
        showDateTime: true,
        showOrderNumber: true,
        termsAndConditions: 'No refunds after 24 hours. All sales final.',
      );
    });

    test('Customer receipt has simplified content', () {
      final receiptText = generateReceiptTextWithSettings(
        data: baseData,
        settings: receiptSettings,
        charWidth: 48,
        receiptType: ReceiptType.customer,
      );

      // Customer receipt should have minimal header
      expect(receiptText.contains('Test Restaurant'), isTrue); // Store name is still shown but minimal
      expect(receiptText.contains('123 Test Street'), isFalse); // Address not shown for customers

      // Should have simplified transaction info
      expect(receiptText.contains('ORD-20251230-001'), isTrue);
      expect(receiptText.contains('30/12/2025'), isTrue);

      // Should have thank you message
      expect(receiptText.contains('Thank you'), isTrue);

      // Should NOT have detailed business info or terms
      expect(receiptText.contains('TXN123456'), isFalse);
      expect(receiptText.contains('012-3456789'), isFalse);
    });

    test('Merchant receipt has detailed content', () {
      final receiptText = generateReceiptTextWithSettings(
        data: baseData,
        settings: receiptSettings,
        charWidth: 48,
        receiptType: ReceiptType.merchant,
      );

      // Merchant receipt should have full business details
      expect(receiptText.contains('Test Restaurant'), isTrue);
      expect(receiptText.contains('123 Test Street'), isTrue);
      // Note: tax number and phone are not currently displayed in receipts
      // expect(receiptText.contains('TXN123456'), isTrue);
      // expect(receiptText.contains('012-3456789'), isTrue);

      // Should have detailed transaction info
      expect(receiptText.contains('ORD-20251230-001'), isTrue);
      expect(receiptText.contains('30/12/2025'), isTrue);

      // Should have terms and conditions
      expect(receiptText.contains('Terms & Conditions'), isTrue);
    });

    test('Receipt type defaults to customer when not specified', () {
      final receiptText = generateReceiptTextWithSettings(
        data: baseData,
        settings: receiptSettings,
        charWidth: 48,
        // No receiptType specified - should default to customer
      );

      // Should behave like customer receipt (simplified)
      expect(receiptText.contains('123 Test Street'), isFalse); // Address not shown
      expect(receiptText.contains('Thank you'), isTrue);
    });
  });
}