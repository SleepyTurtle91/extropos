 
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/merchant_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double total;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;
  final int? orderNumber;
  final String? merchantId;

  const ReceiptPreviewScreen({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    this.orderNumber,
    this.merchantId,
  });

  @override
  Widget build(BuildContext context) {
    final info = BusinessInfo.instance;
    final currency = info.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final currentContext = context; // Capture before async
              developer.log(
                'RECEIPT PREVIEW: Print button pressed',
                name: 'receipt_preview',
              );

              try {
                // Load configured printer from database
                final dbService = DatabaseService.instance;
                final printers = await dbService.getPrinters();
                final defaultPrinter = printers.firstWhere(
                  (p) => p.isDefault,
                  orElse: () => printers.isNotEmpty
                      ? printers.first
                      : throw Exception('No printer configured'),
                );

                developer.log(
                  'RECEIPT PREVIEW: Found printer: ${defaultPrinter.name} (${defaultPrinter.type})',
                  name: 'receipt_preview',
                );

                // Build receipt data
                final info = BusinessInfo.instance;
                final receiptData = {
                  'businessName': info.businessName,
                  'address': info.fullAddress,
                  'taxNumber': info.taxNumber ?? '',
                  'orderNumber': orderNumber?.toString().padLeft(3, '0') ?? '',
                  'dateTime': DateTime.now().toIso8601String(),
                  'items': items
                      .map(
                        (item) => {
                          'name': item.product.name,
                          'quantity': item.quantity,
                          'price': item.product.price,
                          'total': item.totalPrice,
                          'modifiers': item.modifiers
                              .map(
                                (m) => {
                                  'name': m.name,
                                  'priceAdjustment': m.priceAdjustment,
                                },
                              )
                              .toList(),
                        },
                      )
                      .toList(),
                  'subtotal': subtotal,
                  'tax': tax,
                  'serviceCharge': serviceCharge,
                  'total': total,
                  'paymentMethod': paymentMethod.name,
                  'amountPaid': amountPaid,
                  'change': change,
                  'currency': info.currencySymbol,
                };

                developer.log(
                  'RECEIPT PREVIEW: Attempting to print receipt',
                  name: 'receipt_preview',
                );

                // Print using configured printer
                final printerService = PrinterService();
                await printerService.printReceipt(defaultPrinter, receiptData);

                developer.log(
                  'RECEIPT PREVIEW: Print successful',
                  name: 'receipt_preview',
                );
                ToastHelper.showToast(currentContext, 'Printed receipt successfully');
              } catch (e) {
                developer.log(
                  'RECEIPT PREVIEW: Print failed: $e',
                  name: 'receipt_preview',
                );
                ToastHelper.showToast(currentContext, 'Print failed: $e');
              }
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Print', style: TextStyle(color: Colors.white)),
          ),
          // PDF export disabled - using thermal receipt generator as single source
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            info.businessName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            info.fullAddress,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (info.taxNumber != null &&
                              info.taxNumber!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Tax No: ${info.taxNumber}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (merchantId != null && merchantId!.isNotEmpty && merchantId != 'none') ...[
                            Text(
                              'Merchant: ${MerchantHelper.displayName(merchantId)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          Text(
                            orderNumber != null
                                ? 'Order #${orderNumber.toString().padLeft(3, '0')}'
                                : 'Order',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _formatDateTime(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),

                    // Items
                    ...items.map((ci) {
                      final mods = ci.modifiers;
                      final hasMods = mods.isNotEmpty;
                      final modsText = hasMods
                          ? mods
                                .map(
                                  (m) => m.priceAdjustment == 0
                                      ? m.name
                                      : '${m.name} (${m.getPriceAdjustmentDisplay()})',
                                )
                                .join(', ')
                          : '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                            child: Text(
                                              ci.seatNumber != null ? '${ci.product.name} (Seat ${ci.seatNumber})' : ci.product.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'x${ci.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasMods) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      modsText,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currency ${ci.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '@ $currency ${ci.finalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                if (ci.discountPerUnit > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Discount: $currency ${ci.discountPerUnit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const Divider(height: 24),

                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('$currency ${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (tax > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tax (${info.taxRatePercentage})'),
                          Text('$currency ${tax.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    if (serviceCharge > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Service Charge (${info.serviceChargeRatePercentage})',
                          ),
                          Text('$currency ${serviceCharge.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$currency ${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Payment info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method'),
                        Text(paymentMethod.name),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid'),
                        Text('$currency ${amountPaid.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (change > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Change'),
                          Text('$currency ${change.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Thank you!',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
