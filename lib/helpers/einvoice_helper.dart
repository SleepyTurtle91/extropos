import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/einvoice/einvoice_document.dart';
import 'package:extropos/services/einvoice_service.dart';

/// Helper class to convert POS transactions to e-Invoice format
class EInvoiceHelper {
  /// Convert POS checkout data to e-Invoice document
  static EInvoiceDocument convertToEInvoice({
    required String invoiceNumber,
    required List<CartItem> cartItems,
    required double subtotal,
    required double taxAmount,
    required double serviceChargeAmount,
    required double grandTotal,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerTin,
    String? customerAddress,
    String? customerIdType,
    String? customerIdValue,
  }) {
    final config = EInvoiceService.instance.config;
    if (config == null || !config.isConfigured) {
      throw Exception('e-Invoice not configured');
    }

    final businessInfo = BusinessInfo.instance;
    final now = DateTime.now();

    // Build line items from cart
    final lineItems = <EInvoiceLineItem>[];
    for (int i = 0; i < cartItems.length; i++) {
      final cartItem = cartItems[i];
      final itemSubtotal = cartItem.product.price * cartItem.quantity;

      // Calculate tax for this line item proportionally
      final itemTaxAmount = taxAmount > 0
          ? (itemSubtotal / subtotal) * taxAmount
          : 0.0;

      lineItems.add(
        EInvoiceLineItem(
          lineNumber: i + 1,
          itemName: cartItem.product.name,
          itemDescription: cartItem.product.name,
          quantity: cartItem.quantity.toDouble(),
          unitPrice: cartItem.product.price,
          lineExtensionAmount: itemSubtotal,
          taxTotal: businessInfo.isTaxEnabled && itemTaxAmount > 0
              ? EInvoiceLineTax(
                  taxAmount: itemTaxAmount,
                  taxCategoryCode: 'S', // Standard rated
                  taxPercent:
                      businessInfo.taxRate * 100, // Convert to percentage
                )
              : null,
          classificationCode: cartItem.product.category.isNotEmpty
              ? cartItem.product.category
              : null,
        ),
      );
    }

    // Build tax totals
    final taxSubtotals = <EInvoiceTaxSubtotal>[];
    if (businessInfo.isTaxEnabled && taxAmount > 0) {
      taxSubtotals.add(
        EInvoiceTaxSubtotal(
          taxableAmount: subtotal,
          taxAmount: taxAmount,
          taxCategoryCode: 'S',
          taxPercent: businessInfo.taxRate * 100, // Convert to percentage
        ),
      );
    }

    // Service charge is typically not taxed in Malaysia
    if (businessInfo.isServiceChargeEnabled && serviceChargeAmount > 0) {
      taxSubtotals.add(
        EInvoiceTaxSubtotal(
          taxableAmount: subtotal,
          taxAmount: serviceChargeAmount,
          taxCategoryCode: 'E', // Exempt
          taxPercent: 0.0,
        ),
      );
    }

    final totalTaxAndCharges = taxAmount + serviceChargeAmount;

    return EInvoiceDocument(
      invoiceCodeNumber: invoiceNumber,
      issueDate: now,
      issueTime: now,
      supplier: EInvoiceSupplier(
        tin: config.tin,
        name: config.businessName,
        addressLine1: config.businessAddress,
        city: 'Kuala Lumpur', // Can be configured later
        state: '14', // Default to Federal Territory KL
        postalCode: '50000', // Can be configured later
        phone: config.businessPhone,
        email: config.businessEmail,
      ),
      customer: EInvoiceCustomer(
        tin: customerTin,
        name: customerName ?? 'Walk-in Customer',
        addressLine1: customerAddress,
        city: 'Kuala Lumpur',
        state: '14',
        postalCode: '50000',
        phone: customerPhone,
        email: customerEmail,
        idType: customerIdType,
        idValue: customerIdValue,
      ),
      lineItems: lineItems,
      taxTotal: EInvoiceTaxTotal(
        totalTaxAmount: totalTaxAndCharges,
        subtotals: taxSubtotals,
      ),
      legalMonetaryTotal: EInvoiceLegalMonetaryTotal(
        lineExtensionAmount: subtotal,
        taxExclusiveAmount: subtotal,
        taxInclusiveAmount: grandTotal,
        payableAmount: grandTotal,
      ),
    );
  }

  /// Submit e-Invoice automatically after checkout
  static Future<Map<String, dynamic>?> submitAfterCheckout({
    required String invoiceNumber,
    required List<CartItem> cartItems,
    required double subtotal,
    required double taxAmount,
    required double serviceChargeAmount,
    required double grandTotal,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerTin,
  }) async {
    final einvoiceService = EInvoiceService.instance;

    // Check if e-Invoice is enabled
    if (!einvoiceService.isEnabled) {
      return null;
    }

    try {
      // Convert to e-Invoice format
      final document = convertToEInvoice(
        invoiceNumber: invoiceNumber,
        cartItems: cartItems,
        subtotal: subtotal,
        taxAmount: taxAmount,
        serviceChargeAmount: serviceChargeAmount,
        grandTotal: grandTotal,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        customerTin: customerTin,
      );

      // Submit to MyInvois
      final result = await einvoiceService.submitDocuments([document]);
      return result;
    } catch (e) {
      // Log error but don't block checkout
      print('e-Invoice submission failed: $e');
      return null;
    }
  }

  /// Get Malaysian state codes for e-Invoice
  static Map<String, String> get malaysianStateCodes => {
    '01': 'Johor',
    '02': 'Kedah',
    '03': 'Kelantan',
    '04': 'Melaka',
    '05': 'Negeri Sembilan',
    '06': 'Pahang',
    '07': 'Pulau Pinang',
    '08': 'Perak',
    '09': 'Perlis',
    '10': 'Selangor',
    '11': 'Terengganu',
    '12': 'Sabah',
    '13': 'Sarawak',
    '14': 'Wilayah Persekutuan Kuala Lumpur',
    '15': 'Wilayah Persekutuan Labuan',
    '16': 'Wilayah Persekutuan Putrajaya',
  };

  /// Get tax category codes for e-Invoice
  static Map<String, String> get taxCategoryCodes => {
    'S': 'Standard rated (6%)',
    'Z': 'Zero rated (0%)',
    'E': 'Exempt from tax',
    'O': 'Out of scope',
  };

  /// Validate TIN format (Malaysian Tax Identification Number)
  static bool isValidTin(String tin) {
    // TIN format: C + 10 digits or C + 9 digits + letter
    final regex = RegExp(r'^C\d{10}$|^C\d{9}[A-Z]$');
    return regex.hasMatch(tin);
  }
}
