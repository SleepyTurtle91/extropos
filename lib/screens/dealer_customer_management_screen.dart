import 'package:extropos/models/dealer_customer_model.dart';
import 'package:extropos/screens/dealer_customer_registration_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/super_admin_service.dart';
import 'package:flutter/material.dart';

class DealerCustomerManagementScreen extends StatefulWidget {
  const DealerCustomerManagementScreen({super.key});

  @override
  State<DealerCustomerManagementScreen> createState() =>
      _DealerCustomerManagementScreenState();
}

class _DealerCustomerManagementScreenState
    extends State<DealerCustomerManagementScreen> {
  List<DealerCustomer> _customers = [];
  List<DealerCustomer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final Set<String> _processingTenants = {}; // Track tenants being processed

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    try {
      final maps = await DatabaseService.instance.getDealerCustomers();
      final customers = maps.map((map) => DealerCustomer.fromMap(map)).toList();

      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          return customer.businessName.toLowerCase().contains(_searchQuery) ||
              customer.ownerName.toLowerCase().contains(_searchQuery) ||
              customer.email.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _navigateToRegistration([DealerCustomer? customer]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DealerCustomerRegistrationScreen(customer: customer),
      ),
    );

    if (result == true) {
      _loadCustomers();
    }
  }

  Future<void> _deleteCustomer(DealerCustomer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${customer.businessName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseService.instance.deleteDealerCustomer(customer.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCustomers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting customer: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCustomerDetails(DealerCustomer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.businessName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Owner', customer.ownerName),
              _buildDetailRow('Email', customer.email),
              _buildDetailRow('Phone', customer.phone),
              if (customer.registrationNumber != null)
                _buildDetailRow('Registration #', customer.registrationNumber!),
              if (customer.taxNumber != null)
                _buildDetailRow('Tax #', customer.taxNumber!),
              if (customer.website != null)
                _buildDetailRow('Website', customer.website!),
              const Divider(),
              _buildDetailRow('Address', customer.fullAddress),
              const Divider(),
              _buildDetailRow('Created', _formatDate(customer.createdAt)),
              _buildDetailRow('Updated', _formatDate(customer.updatedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToRegistration(customer);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Handle tenant database management initiation
  Future<void> _manageTenant(DealerCustomer customer) async {
    // Add to processing set to show loading state
    setState(() {
      _processingTenants.add(customer.id);
    });

    try {
      // Call the backend API to initiate database access
      final success = await SuperAdminService.initiateTenantDatabaseAccess(
        customer.id,
      );

      if (success && mounted) {
        // Show success message as per implementation plan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully initiated maintenance access for Tenant ID ${customer.id}. The DB Ops Service is now active.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate tenant management: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Remove from processing set
      if (mounted) {
        setState(() {
          _processingTenants.remove(customer.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCustomers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterCustomers,
            ),
          ),

          // Stats Cards
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Customers',
                      _customers.length.toString(),
                      Icons.people,
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active',
                      _customers.where((c) => c.isActive).length.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.people_outline
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No customers registered yet'
                              : 'No customers found',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToRegistration(),
                            icon: const Icon(Icons.add),
                            label: const Text('Register First Customer'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2563EB),
                            child: Text(
                              customer.businessName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.businessName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(customer.ownerName),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      customer.email,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: _processingTenants.contains(customer.id)
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        _showCustomerDetails(customer);
                                        break;
                                      case 'edit':
                                        _navigateToRegistration(customer);
                                        break;
                                      case 'delete':
                                        _deleteCustomer(customer);
                                        break;
                                      case 'manage_tenant':
                                        _manageTenant(customer);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'manage_tenant',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Manage Tenant',
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          onTap: () => _showCustomerDetails(customer),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRegistration(),
        icon: const Icon(Icons.add),
        label: const Text('Register Customer'),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
