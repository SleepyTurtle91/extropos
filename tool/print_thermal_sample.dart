import 'dart:io';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/thermal_receipt_generator.dart';
import 'package:flutter/material.dart';

Future<void> main(List<String> args) async {
  final printerIp = args.isNotEmpty ? args.first : '192.168.0.115';
  const printerPort = 9100; // standard RAW port for network thermal printers

  // Configure business info with proper constructor
  BusinessInfo.updateInstance(
    BusinessInfo.instance.copyWith(
      businessName: 'FlutterPOS Test Cafe',
      ownerName: 'Test Owner',
      address: '12345 Long Street',
      city: 'Kuala Lumpur',
      state: 'Federal Territory',
      postcode: '123456',
      country: 'Malaysia',
      taxNumber: 'SST-123456789',
    ),
  );

  final items = <CartItem>[
    CartItem(
      Product('Latte Grande', 12.50, 'Beverages', Icons.local_cafe),
      2,
    ),
    CartItem(
      Product('Blueberry Muffin', 7.00, 'Pastries', Icons.bakery_dining),
      1,
    ),
    CartItem(
      Product('Sandwich Club XXL', 18.40, 'Food', Icons.lunch_dining),
      1,
    ),
  ];

  final bytes = ThermalReceiptGenerator.generateReceipt(
    paperSize: PaperSize.mm80, // change to mm58 to test 58mm wrapping
    items: items,
    subtotal: 50.40,
    tax: 3.20,
    serviceCharge: 1.60,
    total: 55.20,
    paymentMethod: PaymentMethod(id: 'cash', name: 'Cash'),
    amountPaid: 60.00,
    change: 4.80,
    orderNumber: 42,
    showLogo: false,
  );

  final socket = await Socket.connect(printerIp, printerPort, timeout: const Duration(seconds: 5));
  stdout.writeln('Connected to printer at $printerIp:$printerPort');
  socket.add(bytes);
  await socket.flush();
  await socket.close();
  stdout.writeln('Sent ${bytes.length} bytes. Check the printout for wrapped header.');
}
