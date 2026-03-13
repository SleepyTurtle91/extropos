import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// MyInvois Queue Screen - View submitted e-invoices and their status
class MyInvoisQueueScreen extends StatefulWidget {
  const MyInvoisQueueScreen({super.key});

  @override
  State<MyInvoisQueueScreen> createState() => _MyInvoisQueueScreenState();
}

class _MyInvoisQueueScreenState extends State<MyInvoisQueueScreen> {
  List<Map<String, dynamic>> _submittedInvoices = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSubmittedInvoices();
  }

  Future<void> _loadSubmittedInvoices() async {
    setState(() => _isLoading = true);

    try {
      // Load orders that have been submitted as e-invoices
      final orders = await DatabaseService.instance.getSalesHistory(
        limit: 100, // Show recent submissions
      );

      // Filter for orders that have e-invoice UUIDs
      _submittedInvoices = orders.where((order) {
        return order['einvoice_uuid'] != null && order['einvoice_uuid'].toString().isNotEmpty;
      }).toList();

      // Sort by submission date (most recent first)
      _submittedInvoices.sort((a, b) {
        final aDate = a['date'] as DateTime?;
        final bDate = b['date'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

    } catch (e) {
      ToastHelper.showToast(context, 'Failed to load submitted invoices');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStatuses() async {
    if (!EInvoiceService.instance.isConfigured) {
      ToastHelper.showToast(context, 'E-Invoice not configured');
      return;
    }

    setState(() => _isRefreshing = true);

    try {
      int updated = 0;
      for (final invoice in _submittedInvoices) {
        final uuid = invoice['einvoice_uuid'];
        if (uuid != null && uuid.toString().isNotEmpty) {
          try {
            // Check submission status
            await EInvoiceService.instance.getSubmission(uuid);
            // Update local status if needed
            // This would require adding status tracking to the database
            updated++;
          } catch (e) {
            // Continue with other invoices
            continue;
          }
        }
      }

      if (updated > 0) {
        ToastHelper.showToast(context, 'Updated status for $updated invoice(s)');
        await _loadSubmittedInvoices(); // Refresh the list
      } else {
        ToastHelper.showToast(context, 'All statuses are up to date');
      }

    } catch (e) {
      ToastHelper.showToast(context, 'Failed to refresh statuses');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _viewInvoiceDetails(Map<String, dynamic> invoice) async {
    final uuid = invoice['einvoice_uuid'];
    if (uuid == null || uuid.toString().isEmpty) {
      ToastHelper.showToast(context, 'No e-invoice UUID available');
      return;
    }

    if (!EInvoiceService.instance.isConfigured) {
      ToastHelper.showToast(context, 'E-Invoice not configured');
      return;
    }

    try {
      final details = await EInvoiceService.instance.getSubmission(uuid);

      // Show details dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('E-Invoice Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Order: ${invoice['order_number'] ?? invoice['id']}'),
                  Text('UUID: $uuid'),
                  Text('Status: ${details['status'] ?? 'Unknown'}'),
                  Text('Submitted: ${details['submittedAt'] ?? 'Unknown'}'),
                  if (details['documents'] != null && details['documents'].isNotEmpty)
                    Text('Documents: ${details['documents'].length}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      ToastHelper.showToast(context, 'Failed to load invoice details');
    }
  }

  String _getStatusText(Map<String, dynamic> invoice) {
    // In a real implementation, you'd check the actual status from MyInvois
    // For now, we'll show a generic status
    return 'Submitted';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'valid':
        return Colors.green;
      case 'rejected':
      case 'invalid':
        return Colors.red;
      case 'pending':
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyInvois Queue'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshStatuses,
            icon: _isRefreshing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Statuses',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status summary
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
                        ? '${_submittedInvoices.length} e-invoice(s) submitted'
                        : 'E-Invoice not configured',
                    style: TextStyle(
                      color: EInvoiceService.instance.isConfigured ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Invoice list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _submittedInvoices.isEmpty
                    ? const Center(
                        child: Text('No submitted e-invoices found'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSubmittedInvoices,
                        child: ListView.builder(
                          itemCount: _submittedInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _submittedInvoices[index];
                            final status = _getStatusText(invoice);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text('Order #${invoice['order_number'] ?? invoice['id']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer: ${invoice['customer_name'] ?? 'Walk-in'}',
                                    ),
                                    Text(
                                      'Total: RM ${invoice['total']?.toStringAsFixed(2) ?? '0.00'}',
                                    ),
                                    Text(
                                      'Submitted: ${invoice['date'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(invoice['date']) : 'Unknown'}',
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'RM ${invoice['total']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _viewInvoiceDetails(invoice),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}