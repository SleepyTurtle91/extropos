import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:flutter/material.dart';

/// Cart panel widget for RetailPOSScreenTemplate
/// Displays cart items, payment details, and checkout button
class RetailPOSCartPanel extends StatelessWidget {
  final CartService cartService;
 final Customer? selectedCustomer;
  final String? customerName;
  final bool hasCustomerDetails;
  final bool canShowPaymentValues;
  final VoidCallback onProceedToPayment;
  final VoidCallback onOpenCustomerDialog;
  
  // Color constants matching the template
  static const Color primaryBg = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color accent = Color(0xFF6C5CE7);
  
  const RetailPOSCartPanel({
    super.key,
    required this.cartService,
    required this.selectedCustomer,
    required this.customerName,
    required this.hasCustomerDetails,
    required this.canShowPaymentValues,
    required this.onProceedToPayment,
    required this.onOpenCustomerDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Items Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: primaryBg, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {},
                    color: textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, size: 20),
                    onPressed: () {},
                    color: textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Items List
        Expanded(
          child: cartService.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No items in cart',
                        style: TextStyle(color: textSecondary.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Column Headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Order ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Items
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartService.items.length,
                        itemBuilder: (context, index) {
                          final item = cartService.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '#${(index + 8124).toString()}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'RM${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        
        // Payment Details (with scrollable wrapper for overflow protection)
        Flexible(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBg.withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: primaryBg, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.credit_card, size: 18),
                            onPressed: () {},
                            color: textSecondary,
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, size: 18),
                            onPressed: () {},
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onOpenCustomerDialog,
                      icon: Icon(
                        hasCustomerDetails ? Icons.edit : Icons.person_add,
                        size: 16,
                        color: textSecondary,
                      ),
                      label: Text(
                        hasCustomerDetails ? 'Edit customer' : 'Add customer',
                        style: const TextStyle(color: textSecondary),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildPaymentRow(
                    'Buyer Name',
                    canShowPaymentValues
                        ? (selectedCustomer?.name ?? customerName ?? '')
                        : '',
                  ),
                  const SizedBox(height: 8),
                  () {
                    final subtotal = cartService.getSubtotal();
                    final value = canShowPaymentValues
                        ? 'RM${subtotal.toStringAsFixed(2)}'
                        : '';
                    return _buildPaymentRow('Sub cost', value);
                  }(),
                  const SizedBox(height: 8),
                  () {
                    final info = BusinessInfo.instance;
                    final subtotal = cartService.getSubtotal();
                    final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
                    final value = canShowPaymentValues
                        ? 'RM${tax.toStringAsFixed(2)}'
                        : '';
                    return _buildPaymentRow('Tax', value);
                  }(),
                  
                  const Divider(height: 24),
                  
                  () {
                    final info = BusinessInfo.instance;
                    final subtotal = cartService.getSubtotal();
                    final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
                    final serviceCharge = info.isServiceChargeEnabled ? subtotal * info.serviceChargeRate : 0.0;
                    final total = subtotal + tax + serviceCharge;
                    return _buildPaymentRow(
                      'Total',
                      canShowPaymentValues ? 'RM${total.toStringAsFixed(2)}' : '',
                      isBold: true,
                    );
                  }(),
                  
                  const SizedBox(height: 16),
                  
                  // Proceed Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: cartService.items.isEmpty ? null : onProceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Proceed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
