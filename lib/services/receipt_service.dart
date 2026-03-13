import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/e_wallet_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/services/printer_service.dart';

/// Pure business logic for receipt generation and printing
/// No Flutter imports, handles receipt data preparation
class ReceiptService {
  /// Get current receipt settings
  static Future<ReceiptSettings> getSettings() async {
    return await DatabaseService.instance.getReceiptSettings();
  }

  /// Save receipt settings
  static Future<void> saveSettings(ReceiptSettings settings) async {
    await DatabaseService.instance.saveReceiptSettings(settings);
  }

  /// Prepare receipt data for printing
  static Future<Map<String, dynamic>> prepareReceiptData(
    List<CartItem> items,
    double subtotal,
    double tax,
    double serviceCharge,
    double total,
    PaymentResult paymentResult,
  ) async {
    final info = BusinessInfo.instance;
    final currency = info.currencySymbol;
    final now = DateTime.now();

    // Handle payment mode display for split payments
    String paymentMode;
    if (paymentResult.paymentSplits.length == 1) {
      paymentMode = paymentResult.paymentSplits.first.paymentMethod.name;
    } else {
      // Multiple payment methods - show summary
      final methods = paymentResult.paymentSplits
          .map((split) => split.paymentMethod.name)
          .toSet() // Remove duplicates
          .join('/');
      paymentMode = 'Split ($methods)';
    }

    final receiptNumber =
        paymentResult.receiptNumber ??
        now.millisecondsSinceEpoch.toString().substring(7);

    // E-Wallet metadata (if any split uses e-wallet)
    String? ewalletProvider;
    String? ewalletMerchantId;
    String? ewalletQR;
    if (paymentResult.paymentSplits.any(
      (s) =>
          s.paymentMethod.id == 'ewallet' ||
          s.paymentMethod.name.toLowerCase().contains('wallet'),
    )) {
      final settings = await EWalletService.instance.getSettings();
      ewalletProvider = (settings['provider'] as String?) ?? 'duitnow';
      ewalletMerchantId = (settings['merchant_id'] as String?) ?? '';
      ewalletQR = EWalletService.instance.buildDuitNowQR(
        amount: total,
        referenceId: receiptNumber,
        merchantId: ewalletMerchantId,
      );
    }

    return {
      'store_name': info.businessName,
      'address': [
        info.fullAddress,
        if (info.taxNumber != null && info.taxNumber!.isNotEmpty)
          'Tax No: ${info.taxNumber}',
      ],
      'title': 'RECEIPT',
      'date':
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
      'customer': 'Walk-in Customer',
      'bill_no': receiptNumber,
      'payment_mode': paymentMode,
      'dr_ref': '',
      'currency': currency,
      if (ewalletProvider != null) 'ewallet_provider': ewalletProvider,
      if (ewalletMerchantId != null) 'ewallet_merchant_id': ewalletMerchantId,
      if (ewalletQR != null) 'ewallet_qr': ewalletQR,
      if (ewalletQR != null) 'ewallet_reference': receiptNumber,
      'items': items
          .map(
            (item) => {
              'name': item.product.name,
              'qty': item.quantity,
              'amt': item.totalPrice,
            },
          )
          .toList(),
      'sub_total_qty': items.fold(0, (sum, item) => sum + item.quantity),
      'sub_total_amt': subtotal,
      'discount': 0.0,
      'taxes': tax > 0
          ? [
              {'name': 'Tax', 'amt': tax},
            ]
          : [],
      'service_charge': serviceCharge,
      'total': total,
      'amount_paid': paymentResult.amountPaid,
      'change': paymentResult.change,
      'payment_splits': paymentResult.paymentSplits
          .map(
            (split) => {
              'method': split.paymentMethod.name,
              'amount': split.amount,
              'reference': split.reference ?? '',
            },
          )
          .toList(),
    };
  }

  /// Print receipt using prepared data
  static Future<void> printReceipt(Map<String, dynamic> receiptData) async {
    try {
      final printers = await DatabaseService.instance.getPrinters();
      final receiptPrinter = printers
          .where((p) => p.type == PrinterType.receipt)
          .firstOrNull;

      if (receiptPrinter != null) {
        await PrinterService().printReceipt(receiptPrinter, receiptData);
        developer.log('Receipt printed successfully');
      } else {
        developer.log('No receipt printer configured');
      }
    } catch (e) {
      developer.log('Receipt printing failed: $e');
      rethrow;
    }
  }
}