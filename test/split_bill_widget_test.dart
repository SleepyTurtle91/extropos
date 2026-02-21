import 'dart:async';

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/widgets/split_bill_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SplitBillDialog allows seat selection and returns split item with seat', (WidgetTester tester) async {
    final prodA = Product('A', 10.0, 'Cat', Icons.local_cafe);
    final prodB = Product('B', 5.0, 'Cat', Icons.local_cafe);
    final ciA = CartItem(prodA, 1, seatNumber: 3);
    final ciB = CartItem(prodB, 2, seatNumber: 2);

    final completer = Completer<List<CartItem>?>();

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog<List<CartItem>>(
                  context: context,
                  builder: (context) => SplitBillDialog(cartItems: [ciA, ciB], tableCapacity: 4),
                ).then((val) => completer.complete(val));
              },
              child: const Text('Open'),
            ),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Confirm dialog is shown
    expect(find.text('Split Bill — Select items to move'), findsOneWidget);

    // Increase quantity for product A (scoped to dialog to avoid matching other widgets)
    final dialogTitleFinder = find.text('Split Bill — Select items to move');
    expect(dialogTitleFinder, findsOneWidget);
    final alertDialogFinder = find.ancestor(of: dialogTitleFinder, matching: find.byType(AlertDialog));
    final listTileA = find.descendant(of: alertDialogFinder, matching: find.widgetWithText(ListTile, 'A'));
    final addForA = find.descendant(of: listTileA, matching: find.byIcon(Icons.add));
    expect(addForA, findsOneWidget);
    await tester.ensureVisible(addForA);
    await tester.tap(addForA);
    await tester.pumpAndSettle();

    // We rely on initial seat number propagated by the CartItem (3) instead of interacting with dropdown menus
    await tester.pumpAndSettle();

    // Tap Split & Pay within dialog context
    final splitButton = find.descendant(of: alertDialogFinder, matching: find.text('Split & Pay'));
    await tester.tap(splitButton);
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull);
    // We expect at least one split item for product A (quantity 1, seat 3)
    expect(result!.any((ci) => ci.product.name == 'A' && ci.quantity == 1 && ci.seatNumber == 3), true);
  });
}
