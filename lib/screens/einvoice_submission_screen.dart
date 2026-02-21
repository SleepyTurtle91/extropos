import 'dart:developer';

import 'package:extropos/models/einvoice/einvoice_document.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// e-Invoice Submission Screen
/// Allows manual submission and viewing of e-Invoices
class EInvoiceSubmissionScreen extends StatefulWidget {
  const EInvoiceSubmissionScreen({super.key});

  @override
  State<EInvoiceSubmissionScreen> createState() =>
      _EInvoiceSubmissionScreenState();
}

class _EInvoiceSubmissionScreenState extends State<EInvoiceSubmissionScreen> {
  final _einvoiceService = EInvoiceService.instance;
  List<Map<String, dynamic>> _recentDocuments = [];
  bool _isLoading = false;
  bool _isLoadingDocs = false;

  @override
  void initState() {
    super.initState();
    _loadRecentDocuments();
  }

  Future<void> _loadRecentDocuments() async {
    if (!_einvoiceService.isEnabled) return;

    setState(() => _isLoadingDocs = true);

    try {
      final docs = await _einvoiceService.getRecentDocuments(
        pageSize: 50,
        pageNo: 1,
      );

      if (!mounted) return;
      setState(() {
        _recentDocuments = docs;
      });
    } catch (e) {
      log('Error loading recent documents: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to load documents: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDocs = false);
      }
    }
  }

  Future<void> _testSubmission() async {
    setState(() => _isLoading = true);

    try {
      // Create a test invoice document
      final testDoc = _createTestInvoice();

      // Submit to MyInvois
      final result = await _einvoiceService.submitDocuments([testDoc]);

      if (!mounted) return;

      final submissionUid = result['submissionUID'];
      final acceptedDocs = result['acceptedDocuments'] ?? [];
      final rejectedDocs = result['rejectedDocuments'] ?? [];

      if (acceptedDocs.isNotEmpty) {
        ToastHelper.showToast(
          context,
          '✓ Test invoice submitted successfully!\n'
          'Submission: $submissionUid\n'
          'UUID: ${acceptedDocs[0]['uuid']}',
        );
        _loadRecentDocuments(); // Reload list
      } else if (rejectedDocs.isNotEmpty) {
        ToastHelper.showToast(
          context,
          '✗ Test invoice rejected:\n${rejectedDocs[0]['error']}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Submission failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  EInvoiceDocument _createTestInvoice() {
    final config = _einvoiceService.config!;
    final now = DateTime.now();

    return EInvoiceDocument(
      invoiceCodeNumber: 'TEST-${now.millisecondsSinceEpoch}',
      issueDate: now,
      issueTime: now,
      supplier: EInvoiceSupplier(
        tin: config.tin,
        name: config.businessName,
        addressLine1: config.businessAddress,
        city: 'Kuala Lumpur',
        state: '14',
        postalCode: '50000',
        phone: config.businessPhone,
        email: config.businessEmail,
      ),
      customer: EInvoiceCustomer(
        name: 'Test Customer',
        addressLine1: 'Test Address',
        city: 'Kuala Lumpur',
        state: '14',
        postalCode: '50000',
        idType: 'NRIC',
        idValue: '123456789012',
      ),
      lineItems: [
        EInvoiceLineItem(
          lineNumber: 1,
          itemName: 'Test Product',
          itemDescription: 'Test Product Description',
          quantity: 1.0,
          unitPrice: 100.00,
          lineExtensionAmount: 100.00,
          taxTotal: EInvoiceLineTax(
            taxAmount: 6.00,
            taxCategoryCode: 'S',
            taxPercent: 6.0,
          ),
        ),
      ],
      taxTotal: EInvoiceTaxTotal(
        totalTaxAmount: 6.00,
        subtotals: [
          EInvoiceTaxSubtotal(
            taxableAmount: 100.00,
            taxAmount: 6.00,
            taxCategoryCode: 'S',
            taxPercent: 6.0,
          ),
        ],
      ),
      legalMonetaryTotal: EInvoiceLegalMonetaryTotal(
        lineExtensionAmount: 100.00,
        taxExclusiveAmount: 100.00,
        taxInclusiveAmount: 106.00,
        payableAmount: 106.00,
      ),
    );
  }

  void _showDocumentDetails(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document ${doc['uuid'] ?? 'Unknown'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('UUID', doc['uuid']),
              _buildDetailRow('Invoice No', doc['invoiceCodeNumber']),
              _buildDetailRow('Status', doc['status']),
              _buildDetailRow('Date', doc['dateTimeIssued']),
              _buildDetailRow(
                'Total',
                'RM ${doc['totalExcludingTax'] ?? '0.00'}',
              ),
              _buildDetailRow('Tax', 'RM ${doc['totalTaxAmount'] ?? '0.00'}'),
              _buildDetailRow(
                'Grand Total',
                'RM ${doc['totalIncludingTax'] ?? '0.00'}',
              ),
              const SizedBox(height: 8),
              if (doc['validationUrl'] != null) ...[
                const Text(
                  'Validation Link:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(
                  doc['validationUrl'],
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = _einvoiceService.isConfigured;
    final isEnabled = _einvoiceService.isEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('e-Invoice Submission'),
        backgroundColor: const Color(0xFF2563EB),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/einvoice-config');
              setState(() {}); // Refresh state after config
            },
          ),
        ],
      ),
      body: !isConfigured
          ? _buildNotConfiguredView()
          : !isEnabled
          ? _buildDisabledView()
          : _buildMainView(),
    );
  }

  Widget _buildNotConfiguredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_suggest, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'e-Invoice Not Configured',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please configure your MyInvois credentials to start submitting e-Invoices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/einvoice-config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              icon: const Icon(Icons.settings),
              label: const Text('Configure e-Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 80, color: Colors.orange.shade400),
            const SizedBox(height: 24),
            const Text(
              'e-Invoice Disabled',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'e-Invoice submission is currently disabled. Enable it in settings to start submitting invoices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/einvoice-config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              icon: const Icon(Icons.toggle_on),
              label: const Text('Enable e-Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        // Status Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'e-Invoice Active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      _einvoiceService.config?.isProduction ?? false
                          ? 'Production Mode'
                          : 'Sandbox Mode',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testSubmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text('Test Submit'),
              ),
            ],
          ),
        ),

        // Recent Documents List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _isLoadingDocs ? null : _loadRecentDocuments,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingDocs
              ? const Center(child: CircularProgressIndicator())
              : _recentDocuments.isEmpty
              ? const Center(
                  child: Text(
                    'No documents found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recentDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = _recentDocuments[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(doc['status']),
                          child: const Icon(Icons.receipt, color: Colors.white),
                        ),
                        title: Text(doc['invoiceCodeNumber'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UUID: ${doc['uuid'] ?? 'N/A'}'),
                            Text('Status: ${doc['status'] ?? 'Unknown'}'),
                          ],
                        ),
                        trailing: Text(
                          'RM ${doc['totalIncludingTax'] ?? '0.00'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _showDocumentDetails(doc),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'valid':
        return Colors.green;
      case 'invalid':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
