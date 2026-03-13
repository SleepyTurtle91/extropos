import 'package:extropos/services/payment/duitnow_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DuitNowService.generateDynamicQr', () {
    test('generates EMV payload with dynamic POI and amount', () {
      final payload = DuitNowService.generateDynamicQr(
        merchantId: 'M123456789',
        amount: 25.00,
        merchantName: 'ExtroPOS Mart',
        merchantCity: 'Kuala Lumpur',
      );

      expect(payload.startsWith('000201'), isTrue);
      expect(payload.contains('010212'), isTrue); // dynamic POI
      expect(payload.contains('5303458'), isTrue); // MYR currency
      expect(payload.contains('540525.00'), isTrue); // amount field
      expect(payload.contains('5802MY'), isTrue);
      expect(payload.contains('6304'), isTrue); // CRC field id
    });

    test('applies BNM rounding before embedding amount', () {
      final payload = DuitNowService.generateDynamicQr(
        merchantId: 'M123456789',
        amount: 10.03, // rounds to 10.05
      );

      expect(payload.contains('540510.05'), isTrue);
    });

    test('includes optional reference in additional data template', () {
      final payload = DuitNowService.generateDynamicQr(
        merchantId: 'M123456789',
        amount: 50.00,
        reference: 'INV-1001',
      );

      // 62 (additional data) should include 01 + len + value
      expect(payload.contains('0108INV-1001'), isTrue);
      expect(payload.contains('62'), isTrue);
    });

    test('throws for empty merchant id', () {
      expect(
        () => DuitNowService.generateDynamicQr(
          merchantId: '   ',
          amount: 1.00,
        ),
        throwsArgumentError,
      );
    });

    test('throws for non-positive amount', () {
      expect(
        () => DuitNowService.generateDynamicQr(
          merchantId: 'M123456789',
          amount: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('DuitNowService.generateStaticQr', () {
    test('generates static POI payload without amount field', () {
      final payload = DuitNowService.generateStaticQr(
        merchantId: 'M123456789',
      );

      expect(payload.contains('010211'), isTrue); // static POI
      expect(RegExp(r'54\d{2}').hasMatch(payload), isFalse); // no amount TLV
    });
  });

  group('DuitNowService.isValidPayload', () {
    test('returns true for generated payload', () {
      final payload = DuitNowService.generateDynamicQr(
        merchantId: 'M123456789',
        amount: 12.50,
      );

      expect(DuitNowService.isValidPayload(payload), isTrue);
    });

    test('returns false for tampered payload', () {
      final payload = DuitNowService.generateDynamicQr(
        merchantId: 'M123456789',
        amount: 12.50,
      );

      // Tamper one character before CRC.
      final tampered = '${payload.substring(0, payload.length - 10)}9${payload.substring(payload.length - 9)}';
      expect(DuitNowService.isValidPayload(tampered), isFalse);
    });
  });
}
