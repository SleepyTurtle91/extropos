import 'package:extropos/models/customer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CustomersManagementScreen extends StatefulWidget {
  const CustomersManagementScreen({super.key});

  @override
  State<CustomersManagementScreen> createState() =>
      _CustomersManagementScreenState();
}

class _CustomersManagementScreenState extends State<CustomersManagementScreen> {
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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
    final currentContext = context;
    try {
      final loadedCustomers = await DatabaseService.instance.getCustomers();
      setState(() {
        customers = loadedCustomers;
        filteredCustomers = loadedCustomers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ToastHelper.showToast(currentContext, 'Error loading customers: $e');
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers.where((customer) {
          final nameLower = customer.name.toLowerCase();
          final phoneLower = customer.phone?.toLowerCase() ?? '';
          final emailLower = customer.email?.toLowerCase() ?? '';
          final queryLower = query.toLowerCase();

          return nameLower.contains(queryLower) ||
              phoneLower.contains(queryLower) ||
              emailLower.contains(queryLower);
        }).toList();
      }
    });
  }

  void _addCustomer() {
    final widgetContext = context;
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(
        onSave: (customer) async {
          try {
            await DatabaseService.instance.insertCustomer(customer);
            if (!mounted) return;
            await _loadCustomers();
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(
                widgetContext,
                'Customer added successfully',
              );
            }
          } catch (e) {
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(widgetContext, 'Error adding customer: $e');
            }
          }
        },
      ),
    );
  }

  void _editCustomer(Customer customer) {
    final widgetContext = context;
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(
        customer: customer,
        onSave: (updatedCustomer) async {
          try {
            await DatabaseService.instance.updateCustomer(updatedCustomer);
            if (!mounted) return;
            await _loadCustomers();
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(
                widgetContext,
                'Customer updated successfully',
              );
            }
          } catch (e) {
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(
                widgetContext,
                'Error updating customer: $e',
              );
            }
          }
        },
      ),
    );
  }

  void _deleteCustomer(Customer customer) {
    final widgetContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService.instance.deleteCustomer(customer.id);
                if (!mounted) return;
                await _loadCustomers();
                if (!mounted) return;
                if (mounted) {
                  ToastHelper.showToast(
                    widgetContext,
                    'Customer deleted successfully',
                  );
                }
              } catch (e) {
                if (!mounted) return;
                if (mounted) {
                  ToastHelper.showToast(
                    widgetContext,
                    'Error deleting customer: $e',
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int get activeCustomersCount {
    return customers.where((c) => c.isRegular).length;
  }

  int get vipCustomersCount {
    return customers.where((c) => c.totalSpent >= 10000).length;
  }

  int get totalLoyaltyPoints {
    return customers.fold(0, (sum, c) => sum + c.loyaltyPoints);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customers Management'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.people,
                          label: 'Total Customers',
                          value: customers.length.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.trending_up,
                          label: 'Active (30d)',
                          value: activeCustomersCount.toString(),
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.star,
                          label: 'VIP Customers',
                          value: vipCustomersCount.toString(),
                          color: Colors.amber,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.card_giftcard,
                          label: 'Total Points',
                          value: totalLoyaltyPoints.toString(),
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people,
                          label: 'Total Customers',
                          value: customers.length.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_up,
                          label: 'Active (30d)',
                          value: activeCustomersCount.toString(),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.star,
                          label: 'VIP Customers',
                          value: vipCustomersCount.toString(),
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.card_giftcard,
                          label: 'Total Points',
                          value: totalLoyaltyPoints.toString(),
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
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
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterCustomers,
            ),
          ),

          // Customers Grid
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No customers found'
                              : 'No customers yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add your first customer to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Grid columns managed by maxCrossAxisExtent for predictable tiles

                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: AppTokens.tableCardMinWidth + 40,
                          crossAxisSpacing: AppSpacing.m,
                          mainAxisSpacing: AppSpacing.m,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return _CustomerCard(
                            customer: customer,
                            onEdit: () => _editCustomer(customer),
                            onDelete: () => _deleteCustomer(customer),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }
}

// Stats Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Customer Card Widget
class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'VIP':
        return Colors.purple;
      case 'Gold':
        return Colors.amber;
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTierColor(
                          customer.customerTier,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getTierColor(customer.customerTier),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        customer.customerTier,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getTierColor(customer.customerTier),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (customer.phone != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          customer.phone!,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (customer.email != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.email, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          customer.email!,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                const Spacer(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spent',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'RM ${customer.totalSpent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visits',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          customer.visitCount.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Points',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          customer.loyaltyPoints.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Customer Form Dialog
class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final Function(Customer) onSave;

  const _CustomerFormDialog({this.customer, required this.onSave});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
    _notesController = TextEditingController(
      text: widget.customer?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^[0-9\-\+\(\)\s]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final customer =
          widget.customer?.copyWith(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            updatedAt: now,
          ) ??
          Customer(
            id: const Uuid().v4(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            createdAt: now,
            updatedAt: now,
          );

      widget.onSave(customer);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Optional',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
