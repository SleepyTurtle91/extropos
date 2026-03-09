import 'dart:developer';

import 'package:extropos/helpers/einvoice_helper.dart';
import 'package:extropos/models/einvoice/einvoice_document.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// E-Invoice Submission Screen - Submit pending orders as e-invoices
class EInvoiceSubmissionScreen extends StatefulWidget {
  const EInvoiceSubmissionScreen({super.key});

  @override
  State<EInvoiceSubmissionScreen> createState() => _EInvoiceSubmissionScreenState();
}

class _EInvoiceSubmissionScreenState extends State<EInvoiceSubmissionScreen> {
  List<Map<String, dynamic>> _pendingOrders = [];
  final Set<String> _selectedOrderIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  Future<void> _loadPendingOrders() async {
    setState(() => _isLoading = true);

    try {
      // Load orders that haven't been submitted as e-invoices yet
      final orders = await DatabaseService.instance.getSalesHistory(
        limit: 50, // Limit for performance
      );

      // Filter for orders that don't have e-invoice UUIDs
      _pendingOrders = orders.where((order) {
        // Check if order has been submitted (you might need to add a field to track this)
        return order['einvoice_uuid'] == null || order['einvoice_uuid'].toString().isEmpty;
      }).toList();
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to load pending orders');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitSelectedOrders() async {
    if (_selectedOrderIds.isEmpty) {
      ToastHelper.showToast(context, 'Please select orders to submit');
      return;
    }

    if (!EInvoiceService.instance.isConfigured) {
      ToastHelper.showToast(context, 'E-Invoice not configured. Please configure first.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get selected orders
      final selectedOrders = _pendingOrders
          .where((order) => _selectedOrderIds.contains(order['id']))
          .toList();

      // Convert orders to e-invoice documents
      final documents = <EInvoiceDocument>[];
      for (final order in selectedOrders) {
        try {
          final document = await EInvoiceHelper.convertOrderToEInvoice(order);
          documents.add(document);
        } catch (e) {
          log('Failed to convert order ${order['id']} to e-invoice: $e');
          continue; // Skip this order
        }
      }

      if (documents.isEmpty) {
        ToastHelper.showToast(context, 'No valid orders to submit');
        return;
      }

      // Submit documents
      final result = await EInvoiceService.instance.submitDocuments(documents);

      // Update orders with submission UUIDs
      for (int i = 0; i < documents.length && i < result['documents']?.length; i++) {
        final docResult = result['documents'][i];
        final orderId = selectedOrders[i]['id'];
        final uuid = docResult['uuid'];

        if (uuid != null) {
          await DatabaseService.instance.updateOrderEInvoiceStatus(orderId, uuid);
        }
      }

      ToastHelper.showToast(context, 'Successfully submitted ${documents.length} e-invoice(s)');

      // Refresh the list
      await _loadPendingOrders();
      _selectedOrderIds.clear();

    } catch (e) {
      ToastHelper.showToast(context, 'Submission failed: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _selectAllOrders() {
    setState(() {
      if (_selectedOrderIds.length == _pendingOrders.length) {
        _selectedOrderIds.clear();
      } else {
        _selectedOrderIds.addAll(_pendingOrders.map((order) => order['id'] as String));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Invoice Submission'),
        actions: [
          if (_pendingOrders.isNotEmpty)
            TextButton(
              onPressed: _selectAllOrders,
              child: Text(
                _selectedOrderIds.length == _pendingOrders.length ? 'Deselect All' : 'Select All',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status and info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(
                  EInvoiceService.instance.isConfigured ? Icons.check_circle : Icons.warning,
                  color: EInvoiceService.instance.isConfigured ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    EInvoiceService.instance.isConfigured
                        ? 'E-Invoice configured and ready'
                        : 'E-Invoice not configured. Please configure first.',
                    style: TextStyle(
                      color: EInvoiceService.instance.isConfigured ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Submit button
          if (_selectedOrderIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitSelectedOrders,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text('Submit ${_selectedOrderIds.length} E-Invoice(s)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingOrders.isEmpty
                    ? const Center(
                        child: Text('No pending orders to submit'),
                      )
                    : ListView.builder(
                        itemCount: _pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = _pendingOrders[index];
                          final orderId = order['id'] as String;
                          final isSelected = _selectedOrderIds.contains(orderId);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) => _toggleOrderSelection(orderId),
                            title: Text('Order #${order['order_number'] ?? orderId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer: ${order['customer_name'] ?? 'Walk-in'}',
                                ),
                                Text(
                                  'Total: RM ${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                                ),
                                Text(
                                  'Date: ${order['date'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(order['date']) : 'Unknown'}',
                                ),
                              ],
                            ),
                            secondary: Text(
                              'RM ${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}