import 'package:extropos/models/parked_sale_model.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/parked_sale_service.dart';
import 'package:flutter/material.dart';

class ParkedSalesScreen extends StatefulWidget {
  const ParkedSalesScreen({super.key});

  @override
  State<ParkedSalesScreen> createState() => _ParkedSalesScreenState();
}

class _ParkedSalesScreenState extends State<ParkedSalesScreen> {
  List<ParkedSale> _parkedSales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParkedSales();
  }

  Future<void> _loadParkedSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await ParkedSaleService.instance.getParkedSales();
      setState(() {
        _parkedSales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading parked sales: $e')),
        );
      }
    }
  }

  Future<void> _deleteParkedSale(String saleId) async {
    try {
      await ParkedSaleService.instance.deleteParkedSale(saleId);
      await _loadParkedSales();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Parked sale deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting parked sale: $e')),
        );
      }
    }
  }

  Future<void> _resumeSale(ParkedSale sale) async {
    // Return the sale data to the previous screen
    if (mounted) {
      Navigator.of(context).pop(sale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parked Sales'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          if (_parkedSales.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Parked Sales'),
                    content: const Text(
                      'Are you sure you want to delete all parked sales? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ParkedSaleService.instance.clearAllParkedSales();
                  await _loadParkedSales();
                }
              },
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parkedSales.isEmpty
          ? _buildEmptyState()
          : _buildSalesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_parking, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Parked Sales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suspended sales will appear here',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _parkedSales.length,
      itemBuilder: (context, index) {
        final sale = _parkedSales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sale #${sale.id.substring(sale.id.length - 4)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  sale.formattedTimestamp,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text('${sale.itemCount} items'),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(FormattingService.currency(sale.total)),
                  ],
                ),
                if (sale.customerName != null &&
                    sale.customerName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(sale.customerName!),
                    ],
                  ),
                ],
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sale.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'resume':
                    _resumeSale(sale);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(sale);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'resume',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Resume Sale'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _resumeSale(sale),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(ParkedSale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Parked Sale'),
        content: Text(
          'Are you sure you want to delete sale #${sale.id.substring(sale.id.length - 4)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteParkedSale(sale.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
