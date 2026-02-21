import 'package:extropos/services/my_invois_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Screen to manage queued MyInvois submissions that failed initially
class MyInvoisQueueScreen extends StatefulWidget {
  const MyInvoisQueueScreen({super.key});

  @override
  State<MyInvoisQueueScreen> createState() => _MyInvoisQueueScreenState();
}

class _MyInvoisQueueScreenState extends State<MyInvoisQueueScreen> {
  List<Map<String, dynamic>> _queuedItems = [];
  bool _isLoading = true;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final items = await MyInvoiceService().getQueuedTransactions();
      setState(() {
        _queuedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load queue: $e')),
        );
      }
    }
  }

  Future<void> _retryAll() async {
    setState(() => _isRetrying = true);
    try {
      final successCount = await MyInvoiceService().retryQueuedSubmissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successCount transaction(s) submitted successfully')),
        );
        _loadQueue();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry failed: $e')),
        );
      }
    } finally {
      setState(() => _isRetrying = false);
    }
  }

  Future<void> _clearQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear queue?'),
          content: const Text('This will permanently remove all queued submissions. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await MyInvoiceService().clearQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue cleared')),
        );
        _loadQueue();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyInvois Queue'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          if (_queuedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear queue',
              onPressed: _clearQueue,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queuedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'No queued submissions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All invoices have been submitted successfully',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.orange.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_queuedItems.length} pending submission(s)',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Text(
                                  'These invoices failed to submit and are waiting for retry',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isRetrying ? null : _retryAll,
                            icon: _isRetrying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_isRetrying ? 'Retrying...' : 'Retry All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _queuedItems.length,
                        itemBuilder: (context, index) {
                          final item = _queuedItems[index];
                          return _buildQueueCard(item);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> item) {
    final transactionData = item['transactionData'] as Map<String, dynamic>;
    final queuedAt = DateTime.parse(item['queuedAt'] as String);
    final retryCount = item['retryCount'] as int? ?? 0;
    final receiptNumber = transactionData['receiptNumber'] ?? 'N/A';
    final total = transactionData['totalAmount'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: retryCount >= 3 ? Colors.red : Colors.orange,
          child: Text(
            '$retryCount',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Receipt: $receiptNumber',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: RM ${total.toStringAsFixed(2)}'),
            Text('Queued: ${DateFormat.yMMMd().add_jm().format(queuedAt)}'),
            if (retryCount > 0)
              Text(
                'Retry attempts: $retryCount/3',
                style: TextStyle(
                  color: retryCount >= 3 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: retryCount >= 3
            ? const Chip(
                label: Text('Failed'),
                backgroundColor: Colors.red,
                labelStyle: TextStyle(color: Colors.white),
              )
            : const Chip(
                label: Text('Pending'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}
