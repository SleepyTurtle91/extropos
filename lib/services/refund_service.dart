import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:intl/intl.dart';

/// Types of refund operations
enum RefundType {
  /// Full bill refund/void
  fullBill,

  /// Partial refund for specific items
  itemLevel,
}

/// Result of a refund operation
class RefundResult {
  final bool success;
  final String? refundId;
  final String? refundNumber;
  final double refundAmount;
  final RefundType refundType;
  final String? errorMessage;
  final bool receiptPrinted;

  RefundResult({
    required this.success,
    this.refundId,
    this.refundNumber,
    required this.refundAmount,
    required this.refundType,
    this.errorMessage,
    this.receiptPrinted = false,
  });

  factory RefundResult.success({
    required String refundId,
    required String refundNumber,
    required double refundAmount,
    required RefundType refundType,
    required bool receiptPrinted,
  }) {
    return RefundResult(
      success: true,
      refundId: refundId,
      refundNumber: refundNumber,
      refundAmount: refundAmount,
      refundType: refundType,
      receiptPrinted: receiptPrinted,
    );
  }

  factory RefundResult.failure({
    required String errorMessage,
    required double refundAmount,
    required RefundType refundType,
  }) {
    return RefundResult(
      success: false,
      errorMessage: errorMessage,
      refundAmount: refundAmount,
      refundType: refundType,
      receiptPrinted: false,
    );
  }
}

/// Service for handling refund/void operations with printer integration
class RefundService {
  static final RefundService instance = RefundService._init();
  RefundService._init();

  /// Process a full bill refund/void
  /// Returns the entire order and prints a void receipt
  Future<RefundResult> processFullBillRefund({
    required String orderId,
    required String orderNumber,
    required double originalTotal,
    required List<CartItem> originalItems,
    required PaymentMethod refundMethod,
    required String reason,
    String? userId,
    String? managerApprovalCode,
  }) async {
    try {
      developer.log(
        'Processing full bill refund for order: $orderNumber, amount: $originalTotal',
      );

      // Validate refund amount
      if (originalTotal <= 0) {
        return RefundResult.failure(
          errorMessage: 'Invalid refund amount',
          refundAmount: originalTotal,
          refundType: RefundType.fullBill,
        );
      }

      // Check if in training mode
      if (TrainingModeService.instance.isTrainingMode) {
        final refundNumber =
            'VOID-TRAIN-${DateTime.now().millisecondsSinceEpoch}';
        developer.log('TRAINING MODE: Full bill void processed: $refundNumber');

        return RefundResult.success(
          refundId: refundNumber,
          refundNumber: refundNumber,
          refundAmount: originalTotal,
          refundType: RefundType.fullBill,
          receiptPrinted: false,
        );
      }

      // Process refund in database
      final success = await DatabaseService.instance.refundOrder(
        orderId: orderId,
        refundAmount: originalTotal,
        paymentMethodId: refundMethod.id,
        reason: 'FULL VOID: $reason',
        userId: userId,
      );

      if (!success) {
        return RefundResult.failure(
          errorMessage: 'Failed to process void in database',
          refundAmount: originalTotal,
          refundType: RefundType.fullBill,
        );
      }

      // Restore stock for all items
      await _restoreStockForItems(originalItems);

      // Generate refund number
      final refundNumber = 'VOID-${DateTime.now().millisecondsSinceEpoch}';

      // Print void receipt
      bool receiptPrinted = false;
      try {
        receiptPrinted = await _printVoidReceipt(
          originalOrderNumber: orderNumber,
          refundNumber: refundNumber,
          originalItems: originalItems,
          originalTotal: originalTotal,
          refundAmount: originalTotal,
          refundMethod: refundMethod,
          reason: reason,
          refundType: RefundType.fullBill,
          userId: userId,
        );
      } catch (e) {
        developer.log('Failed to print void receipt: $e');
        // Don't fail the refund if printing fails
      }

      developer.log(
        'Full bill void processed successfully: $refundNumber, receipt printed: $receiptPrinted',
      );

      return RefundResult.success(
        refundId: orderId,
        refundNumber: refundNumber,
        refundAmount: originalTotal,
        refundType: RefundType.fullBill,
        receiptPrinted: receiptPrinted,
      );
    } catch (e) {
      developer.log('Error processing full bill refund: $e');
      return RefundResult.failure(
        errorMessage: 'Refund processing failed: ${e.toString()}',
        refundAmount: originalTotal,
        refundType: RefundType.fullBill,
      );
    }
  }

  /// Process item-level refund/return
  /// Returns only selected items and prints a refund receipt
  Future<RefundResult> processItemRefund({
    required String orderId,
    required String orderNumber,
    required double originalTotal,
    required List<CartItem> refundItems,
    required PaymentMethod refundMethod,
    required String reason,
    String? userId,
    String? managerApprovalCode,
  }) async {
    try {
      // Calculate refund amount from selected items
      final refundAmount = refundItems.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      developer.log(
        'Processing item-level refund for order: $orderNumber, amount: $refundAmount',
      );

      // Validate refund amount
      if (refundAmount <= 0) {
        return RefundResult.failure(
          errorMessage: 'Invalid refund amount',
          refundAmount: refundAmount,
          refundType: RefundType.itemLevel,
        );
      }

      if (refundAmount > originalTotal) {
        return RefundResult.failure(
          errorMessage: 'Refund amount exceeds original total',
          refundAmount: refundAmount,
          refundType: RefundType.itemLevel,
        );
      }

      // Check if in training mode
      if (TrainingModeService.instance.isTrainingMode) {
        final refundNumber =
            'RETURN-TRAIN-${DateTime.now().millisecondsSinceEpoch}';
        developer.log(
          'TRAINING MODE: Item-level return processed: $refundNumber',
        );

        return RefundResult.success(
          refundId: refundNumber,
          refundNumber: refundNumber,
          refundAmount: refundAmount,
          refundType: RefundType.itemLevel,
          receiptPrinted: false,
        );
      }

      // Determine if this is a partial or full refund
      final isPartial = refundAmount < originalTotal;

      // Process refund in database
      final success = await DatabaseService.instance.refundOrder(
        orderId: orderId,
        refundAmount: refundAmount,
        paymentMethodId: refundMethod.id,
        reason: isPartial ? 'PARTIAL RETURN: $reason' : 'FULL RETURN: $reason',
        userId: userId,
      );

      if (!success) {
        return RefundResult.failure(
          errorMessage: 'Failed to process return in database',
          refundAmount: refundAmount,
          refundType: RefundType.itemLevel,
        );
      }

      // Restore stock for refunded items
      await _restoreStockForItems(refundItems);

      // Generate refund number
      final refundNumber = 'RETURN-${DateTime.now().millisecondsSinceEpoch}';

      // Print refund receipt
      bool receiptPrinted = false;
      try {
        receiptPrinted = await _printVoidReceipt(
          originalOrderNumber: orderNumber,
          refundNumber: refundNumber,
          originalItems: [],
          originalTotal: originalTotal,
          refundItems: refundItems,
          refundAmount: refundAmount,
          refundMethod: refundMethod,
          reason: reason,
          refundType: RefundType.itemLevel,
          userId: userId,
        );
      } catch (e) {
        developer.log('Failed to print refund receipt: $e');
        // Don't fail the refund if printing fails
      }

      developer.log(
        'Item-level return processed successfully: $refundNumber, receipt printed: $receiptPrinted',
      );

      return RefundResult.success(
        refundId: orderId,
        refundNumber: refundNumber,
        refundAmount: refundAmount,
        refundType: RefundType.itemLevel,
        receiptPrinted: receiptPrinted,
      );
    } catch (e) {
      developer.log('Error processing item-level refund: $e');
      return RefundResult.failure(
        errorMessage: 'Return processing failed: ${e.toString()}',
        refundAmount: 0.0,
        refundType: RefundType.itemLevel,
      );
    }
  }

  /// Restore stock for refunded items
  Future<void> _restoreStockForItems(List<CartItem> items) async {
    try {
      for (final cartItem in items) {
        // Find the corresponding Item in database by name
        final allItems = await DatabaseService.instance.getItems();
        Item? matchingItem;
        try {
          matchingItem = allItems.firstWhere(
            (item) => item.name == cartItem.product.name,
          );
        } catch (e) {
          matchingItem = null;
        }

        if (matchingItem != null && matchingItem.trackStock) {
          final newStock = matchingItem.stock + cartItem.quantity;
          final updatedItem = matchingItem.copyWith(stock: newStock);
          await DatabaseService.instance.updateItem(updatedItem);
          developer.log(
            'Restored ${cartItem.quantity} to ${matchingItem.name} stock. New stock: $newStock',
          );
        }
      }
    } catch (e) {
      developer.log('Error restoring stock: $e');
      // Don't fail the refund if stock restoration fails
    }
  }

  /// Print a void/refund receipt
  Future<bool> _printVoidReceipt({
    required String originalOrderNumber,
    required String refundNumber,
    required List<CartItem> originalItems,
    required double originalTotal,
    List<CartItem>? refundItems,
    required double refundAmount,
    required PaymentMethod refundMethod,
    required String reason,
    required RefundType refundType,
    String? userId,
  }) async {
    try {
      // Get receipt settings
      final settings = await DatabaseService.instance.getReceiptSettings();

      // Prepare receipt data
      final receiptData = _generateRefundReceiptData(
        originalOrderNumber: originalOrderNumber,
        refundNumber: refundNumber,
        originalItems: originalItems,
        originalTotal: originalTotal,
        refundItems: refundItems,
        refundAmount: refundAmount,
        refundMethod: refundMethod,
        reason: reason,
        refundType: refundType,
        settings: settings,
        userId: userId,
      );

      // Print receipt using the raw receipt data (not formatted text)
      final printerService = PrinterService();
      final printers = await DatabaseService.instance.getPrinters();

      // Find a receipt printer that's online
      final receiptPrinter = printers.firstWhere(
        (p) =>
            p.type == PrinterType.receipt && p.status == PrinterStatus.online,
        orElse: () => printers.isNotEmpty
            ? printers.first
            : throw Exception('No printer available'),
      );

      final success = await printerService.printReceipt(
        receiptPrinter,
        receiptData,
      );

      if (success) {
        developer.log('Refund receipt printed successfully');
      } else {
        developer.log('Failed to print refund receipt');
      }

      return success;
    } catch (e) {
      developer.log('Error printing refund receipt: $e');
      return false;
    }
  }

  /// Generate receipt data for refund/void
  Map<String, dynamic> _generateRefundReceiptData({
    required String originalOrderNumber,
    required String refundNumber,
    required List<CartItem> originalItems,
    required double originalTotal,
    List<CartItem>? refundItems,
    required double refundAmount,
    required PaymentMethod refundMethod,
    required String reason,
    required RefundType refundType,
    required ReceiptSettings settings,
    String? userId,
  }) {
    final info = BusinessInfo.instance;
    final now = DateTime.now();
    final itemsToShow = refundType == RefundType.fullBill
        ? originalItems
        : (refundItems ?? []);

    return {
      'store_name': info.businessName,
      'address': [
        if (info.address.isNotEmpty) info.address,
        if (info.phone.isNotEmpty) 'Tel: ${info.phone}',
        if (info.taxNumber != null && info.taxNumber!.isNotEmpty)
          'Tax ID: ${info.taxNumber}',
      ],
      'title': refundType == RefundType.fullBill
          ? 'VOID RECEIPT'
          : 'REFUND RECEIPT',
      'refund_type': refundType == RefundType.fullBill
          ? 'FULL VOID'
          : 'PARTIAL RETURN',
      'original_order': originalOrderNumber,
      'refund_number': refundNumber,
      'date': DateFormat('yyyy-MM-dd').format(now),
      'time': DateFormat('HH:mm:ss').format(now),
      'reason': reason,
      'items': itemsToShow.map((item) {
        return {
          'name': item.product.name,
          'qty': item.quantity,
          'price': item.product.price,
          'amt': item.totalPrice,
        };
      }).toList(),
      'original_total': originalTotal,
      'refund_amount': refundAmount,
      'refund_method': refundMethod.name,
      'currency': info.currencySymbol,
      'header_text': settings.headerText,
      'footer_text': settings.footerText,
      'show_logo': settings.showLogo,
      'user_id': userId ?? 'SYSTEM',
    };
  }
}

/// Generate refund/void receipt text
String generateRefundReceiptText({
  required Map<String, dynamic> data,
  required ReceiptSettings settings,
  required int charWidth,
}) {
  final buffer = StringBuffer();

  // Helper functions for alignment
  String center(String text) =>
      text.padLeft((charWidth + text.length) ~/ 2).padRight(charWidth);
  String left(String text) => text.padRight(charWidth);
  String divider() => '=' * charWidth;
  String lineSeparator() => '-' * charWidth;

  // 1. Header
  if (settings.showLogo) {
    final logoPath = BusinessInfo.instance.logo;
    if (logoPath != null && logoPath.isNotEmpty) {
      buffer.writeln(center('[LOGO]'));
      buffer.writeln();
    }
  }

  if (settings.headerText.isNotEmpty) {
    buffer.writeln(center(settings.headerText));
  }

  buffer.writeln(center(data['store_name']));
  for (String line in data['address']) {
    buffer.writeln(center(line));
  }

  buffer.writeln();
  buffer.writeln(divider());
  buffer.writeln(center(data['title'])); // VOID RECEIPT or REFUND RECEIPT
  buffer.writeln(center(data['refund_type'])); // FULL VOID or PARTIAL RETURN
  buffer.writeln(divider());
  buffer.writeln();

  // 2. Transaction details
  buffer.writeln(left('Date: ${data['date']} ${data['time']}'));
  buffer.writeln(left('Original Order: ${data['original_order']}'));
  buffer.writeln(left('Refund Number: ${data['refund_number']}'));
  buffer.writeln(left('Refund Method: ${data['refund_method']}'));
  buffer.writeln(left('Reason: ${data['reason']}'));
  buffer.writeln(left('Processed By: ${data['user_id']}'));
  buffer.writeln();
  buffer.writeln(lineSeparator());

  // 3. Items
  if (data['items'] != null && (data['items'] as List).isNotEmpty) {
    buffer.writeln(left('REFUNDED ITEMS:'));
    buffer.writeln();

    final itemWidth = (charWidth * 0.5).floor();
    final qtyWidth = (charWidth * 0.15).floor();
    final priceWidth = (charWidth * 0.15).floor();
    final amtWidth = charWidth - itemWidth - qtyWidth - priceWidth;

    // Header
    final itemHeader = 'Item'.padRight(itemWidth);
    final qtyHeader = 'Qty'.padLeft(qtyWidth);
    final priceHeader = 'Price'.padLeft(priceWidth);
    final amtHeader = 'Total'.padLeft(amtWidth);
    buffer.writeln('$itemHeader$qtyHeader$priceHeader$amtHeader');
    buffer.writeln(lineSeparator());

    // Item rows
    for (Map<String, dynamic> item in data['items']) {
      final itemName = (item['name'].toString().length > itemWidth - 2)
          ? '${item['name'].toString().substring(0, itemWidth - 5)}...'
          : item['name'].toString();
      final itemNamePadded = itemName.padRight(itemWidth);
      final qty = item['qty'].toString().padLeft(qtyWidth);
      final price = (item['price'] as num)
          .toStringAsFixed(2)
          .padLeft(priceWidth);
      final amt = (item['amt'] as num).toStringAsFixed(2).padLeft(amtWidth);
      buffer.writeln('$itemNamePadded$qty$price$amt');
    }

    buffer.writeln(lineSeparator());
  }

  // 4. Totals
  final currency = data['currency'] ?? 'RM';

  if (data['original_total'] != null) {
    final originalLabel = 'Original Total:'.padRight(charWidth - 15);
    final originalAmt =
        '$currency ${(data['original_total'] as num).toStringAsFixed(2)}'
            .padLeft(15);
    buffer.writeln('$originalLabel$originalAmt');
  }

  buffer.writeln();
  buffer.writeln(divider());
  final refundLabel = 'REFUND AMOUNT:'.padRight(charWidth - 15);
  final refundAmt =
      '$currency ${(data['refund_amount'] as num).toStringAsFixed(2)}'.padLeft(
        15,
      );
  buffer.writeln('$refundLabel$refundAmt');
  buffer.writeln(divider());

  // 5. Footer
  buffer.writeln();
  buffer.writeln(center('*** REFUND PROCESSED ***'));
  buffer.writeln();

  if (settings.footerText.isNotEmpty) {
    buffer.writeln(center(settings.footerText));
  }

  buffer.writeln(center('Thank you for your understanding'));
  buffer.writeln();
  buffer.writeln();
  buffer.writeln();

  return buffer.toString();
}
