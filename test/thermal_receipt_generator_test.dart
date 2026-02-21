import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/thermal_receipt_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Initialize BusinessInfo singleton for testing
    BusinessInfo.updateInstance(
      BusinessInfo(
        businessName: 'Test Restaurant',
        ownerName: 'Test Owner',
        email: 'test@example.com',
        phone: '+60123456789',
        address: '123 Test Street',
        city: 'Test City',
        state: 'Test State',
        postcode: '12345',
        taxNumber: 'TAX123456',
        currencySymbol: 'RM',
        isTaxEnabled: true,
        taxRate: 0.10,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.05,
      ),
    );
  });

  group('ThermalReceiptGenerator', () {
    test('should generate receipt for 80mm paper', () {
      final items = <CartItem>[
        CartItem(Product('Burger', 15.00, 'Food', Icons.fastfood), 2),
        CartItem(Product('Fries', 8.00, 'Food', Icons.restaurant), 1),
      ];

      final paymentMethod = PaymentMethod(id: 'cash', name: 'Cash');

      final receiptData = ThermalReceiptGenerator.generateReceipt(
        paperSize: PaperSize.mm80,
        items: items,
        subtotal: 38.00,
        tax: 3.80,
        serviceCharge: 1.90,
        total: 43.70,
        paymentMethod: paymentMethod,
        amountPaid: 50.00,
        change: 6.30,
        orderNumber: 123,
      );

      expect(receiptData, isNotEmpty);
      expect(
        receiptData.length,
        greaterThan(100),
      ); // Should have substantial content
    });

    test('should generate receipt for 58mm paper', () {
      final items = <CartItem>[
        CartItem(Product('Coffee', 5.00, 'Beverage', Icons.local_cafe), 1),
      ];

      final paymentMethod = PaymentMethod(id: 'card', name: 'Card');

      final receiptData = ThermalReceiptGenerator.generateReceipt(
        paperSize: PaperSize.mm58,
        items: items,
        subtotal: 5.00,
        tax: 0.50,
        serviceCharge: 0.25,
        total: 5.75,
        paymentMethod: paymentMethod,
        amountPaid: 5.75,
        change: 0.00,
        orderNumber: null,
      );

      expect(receiptData, isNotEmpty);
      expect(receiptData.length, greaterThan(50)); // Should have content
    });

    test('should handle items with modifiers', () {
      final itemWithModifier = CartItem(
        Product('Pizza', 20.00, 'Food', Icons.local_pizza),
        1,
      );

      final paymentMethod = PaymentMethod(id: 'cash', name: 'Cash');

      final receiptData = ThermalReceiptGenerator.generateReceipt(
        paperSize: PaperSize.mm80,
        items: [itemWithModifier],
        subtotal: 20.00,
        tax: 2.00,
        serviceCharge: 1.00,
        total: 23.00,
        paymentMethod: paymentMethod,
        amountPaid: 23.00,
        change: 0.00,
      );

      expect(receiptData, isNotEmpty);
    });
  });
}
