import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/payment_split_model.dart';
import 'package:extropos/utils/payment_result_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentResultParser', () {
    test('returns null for non-success result', () {
      final parsed = PaymentResultParser.parse(
        {'success': false},
        fallbackAmount: 10.0,
      );

      expect(parsed, isNull);
    });

    test('parses payment method and amounts', () {
      final parsed = PaymentResultParser.parse(
        {
          'success': true,
          'paymentMethod': PaymentMethod(id: 'cash', name: 'Cash'),
          'amountPaid': 20.0,
          'change': 2.5,
          'receiptNumber': 'R-1001',
        },
        fallbackAmount: 17.5,
      );

      expect(parsed, isNotNull);
      expect(parsed!.paymentMethod.id, 'cash');
      expect(parsed.amountPaid, 20.0);
      expect(parsed.change, 2.5);
      expect(parsed.receiptNumber, 'R-1001');
    });

    test('parses payment split list when provided', () {
      final split = PaymentSplit(
        paymentMethod: PaymentMethod(id: 'card', name: 'Card'),
        amount: 50.0,
        reference: 'TXN-1',
      );

      final parsed = PaymentResultParser.parse(
        {
          'success': true,
          'paymentMethod': PaymentMethod(id: 'card', name: 'Card'),
          'amountPaid': 50.0,
          'change': 0.0,
          'paymentSplits': [split],
        },
        fallbackAmount: 50.0,
      );

      expect(parsed, isNotNull);
      expect(parsed!.paymentSplits.length, 1);
      expect(parsed.paymentSplits.first.paymentMethod.id, 'card');
      expect(parsed.paymentSplits.first.amount, 50.0);
      expect(parsed.paymentSplits.first.reference, 'TXN-1');
    });
  });
}
