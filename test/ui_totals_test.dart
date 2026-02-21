import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TotalsView extends StatelessWidget {
  final List<CartItem> items;
  final double discount;

  const TotalsView({super.key, required this.items, this.discount = 0.0});

  @override
  Widget build(BuildContext context) {
    final info = BusinessInfo.instance;
    final currency = info.currencySymbol;
    final subtotal = Pricing.subtotal(items);
    final tax = discount == 0.0
        ? Pricing.taxAmount(items)
        : Pricing.taxAmountWithDiscount(items, discount);
    final svc = discount == 0.0
        ? Pricing.serviceChargeAmount(items)
        : Pricing.serviceChargeAmountWithDiscount(items, discount);
    final total = discount == 0.0
        ? Pricing.total(items)
        : Pricing.totalWithDiscount(items, discount);

    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subtotal: $currency${subtotal.toStringAsFixed(2)}', key: const Key('subtotal')),
              Text('Tax: $currency${tax.toStringAsFixed(2)}', key: const Key('tax')),
              Text('Service: $currency${svc.toStringAsFixed(2)}', key: const Key('service')),
              Text('Total: $currency${total.toStringAsFixed(2)}', key: const Key('total')),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('UI Totals rendering', () {
    testWidgets('Tax on, service off', (tester) async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: true,
        taxRate: 0.10,
        isServiceChargeEnabled: false,
        serviceChargeRate: 0.05,
        currencySymbol: 'RM',
      );
      await BusinessInfo.updateInstance(info);

      final p1 = Product('Coffee', 10.0, 'Beverages', Icons.local_cafe);
      final p2 = Product('Cake', 15.0, 'Desserts', Icons.cake);
      final items = [CartItem(p1, 2), CartItem(p2, 1)];

      await tester.pumpWidget(TotalsView(items: items));

      expect(find.byKey(const Key('subtotal')), findsOneWidget);
      expect(find.text('Subtotal: RM35.00'), findsOneWidget);
      expect(find.text('Tax: RM3.50'), findsOneWidget);
      expect(find.text('Service: RM0.00'), findsOneWidget);
      expect(find.text('Total: RM38.50'), findsOneWidget);
    });

    testWidgets('Tax off, service on', (tester) async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: false,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.10,
        currencySymbol: 'RM',
      );
      await BusinessInfo.updateInstance(info);

      final p = Product('Burger', 12.0, 'Food', Icons.fastfood);
      final items = [CartItem(p, 3)]; // 36.0

      await tester.pumpWidget(TotalsView(items: items));

      expect(find.text('Subtotal: RM36.00'), findsOneWidget);
      expect(find.text('Tax: RM0.00'), findsOneWidget);
      expect(find.text('Service: RM3.60'), findsOneWidget);
      expect(find.text('Total: RM39.60'), findsOneWidget);
    });

    testWidgets('Discount-aware totals', (tester) async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: true,
        taxRate: 0.06,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.04,
        currencySymbol: 'RM',
      );
      await BusinessInfo.updateInstance(info);

      final p = Product('Pizza', 20.0, 'Food', Icons.local_pizza);
      final items = [CartItem(p, 2)]; // subtotal = 40

      await tester.pumpWidget(TotalsView(items: items, discount: 2.0));

      // Net base = 38.0, tax=2.28, svc=1.52, total=41.8
      expect(find.text('Subtotal: RM40.00'), findsOneWidget);
      expect(find.text('Tax: RM2.28'), findsOneWidget);
      expect(find.text('Service: RM1.52'), findsOneWidget);
      expect(find.text('Total: RM41.80'), findsOneWidget);
    });
  });
}
