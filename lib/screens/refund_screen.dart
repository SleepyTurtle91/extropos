import 'package:extropos/features/auth/services/user_session_service.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Refund/Return Screen - Process customer refunds and returns
class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _refundAmountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  Map<String, dynamic>? _selectedTransaction;

  bool _isLoading = false;
  bool _isProcessingRefund = false;
  PaymentMethod? _selectedRefundMethod;

  @override
  void dispose() {
    _transactionIdController.dispose();
    _refundAmountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _searchTransaction() async {
    final transactionId = _transactionIdController.text.trim();
    if (transactionId.isEmpty) {
      ToastHelper.showToast(context, 'Please enter a transaction ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Search for order by order number
      final transaction = await DatabaseService.instance.getOrderByOrderNumber(transactionId);

      if (transaction != null) {
        _selectedTransaction = transaction;
        _refundAmountController.text = transaction['total'].toStringAsFixed(2);
      } else {
        ToastHelper.showToast(context, 'Transaction not found');
        _selectedTransaction = null;
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Error searching transaction');
      _selectedTransaction = null;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processRefund() async {
    if (_selectedTransaction == null) {
      ToastHelper.showToast(context, 'No transaction selected');
      return;
    }

    final refundAmount = double.tryParse(_refundAmountController.text);
    if (refundAmount == null || refundAmount <= 0) {
      ToastHelper.showToast(context, 'Please enter a valid refund amount');
      return;
    }

    final originalAmount = _selectedTransaction!['total'] as double;
    if (refundAmount > originalAmount) {
      ToastHelper.showToast(context, 'Refund amount cannot exceed original transaction');
      return;
    }

    if (_selectedRefundMethod == null) {
      ToastHelper.showToast(context, 'Please select a refund method');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ToastHelper.showToast(context, 'Please provide a reason for the refund');
      return;
    }

    // Get current user
    final currentUser = UserSessionService().currentActiveUser;
    if (currentUser == null) {
      ToastHelper.showToast(context, 'No user signed in');
      return;
    }

    setState(() => _isProcessingRefund = true);

    try {
      // Process refund in database
      final success = await DatabaseService.instance.processRefund(
        orderId: _selectedTransaction!['order_id'] as String,
        refundAmount: refundAmount,
        refundMethodId: _selectedRefundMethod!.id,
        reason: reason,
        userId: currentUser.id,
      );

      if (success) {
        if (mounted) {
          ToastHelper.showToast(context, 'Refund processed successfully');
          _clearForm();
        }
      } else {
        if (mounted) {
          ToastHelper.showToast(context, 'Failed to process refund');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error processing refund');
      }
    }

    if (mounted) {
      setState(() => _isProcessingRefund = false);
    }
  }

  void _clearForm() {
    _transactionIdController.clear();
    _refundAmountController.clear();
    _reasonController.clear();
    _selectedTransaction = null;
    _selectedRefundMethod = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refunds & Returns'),
        actions: [
          if (_selectedTransaction != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearForm,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Search
            _buildTransactionSearch(),

            const SizedBox(height: 24),

            // Transaction Details
            if (_selectedTransaction != null) ...[
              _buildTransactionDetails(),
              const SizedBox(height: 24),
              _buildRefundForm(),
            ] else if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSearch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find Transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _transactionIdController,
              decoration: const InputDecoration(
                labelText: 'Order Number',
                hintText: 'Enter order number (e.g., RETAIL-001, CAFE-001)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchTransaction(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchTransaction,
                icon: const Icon(Icons.search),
                label: const Text('Search Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails() {
    final transaction = _selectedTransaction!;
    final date = transaction['date'] as DateTime;
    final total = transaction['total'] as double;
    final paymentMethod = transaction['payment_method'] as String;
    final customerName = transaction['customer_name'] as String?;
    final items = transaction['items'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction ${transaction['id']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Refundable',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  'RM${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (customerName != null && customerName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Customer: $customerName',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Payment: $paymentMethod',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item['quantity']}x ${item['name']}'),
                  Text('RM${(item['total'] as double).toStringAsFixed(2)}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Refund Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Refund Amount
            TextField(
              controller: _refundAmountController,
              decoration: const InputDecoration(
                labelText: 'Refund Amount (RM)',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Refund Method
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedRefundMethod,
              decoration: const InputDecoration(
                labelText: 'Refund Method',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: PaymentMethod(id: 'cash', name: 'Cash'),
                  child: const Text('Cash'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod(id: 'card', name: 'Original Card'),
                  child: const Text('Original Card'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod(id: 'store_credit', name: 'Store Credit'),
                  child: const Text('Store Credit'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedRefundMethod = value);
              },
            ),
            const SizedBox(height: 16),

            // Reason
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Refund',
                hintText: 'e.g., Customer request, wrong item, quality issue',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Process Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessingRefund ? null : _processRefund,
                icon: _isProcessingRefund
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.undo),
                label: Text(_isProcessingRefund ? 'Processing...' : 'Process Refund'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}