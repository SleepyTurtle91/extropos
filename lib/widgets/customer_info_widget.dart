import 'package:extropos/models/customer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A dialog for collecting customer information during order creation
class CustomerInfoDialog extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final String? initialEmail;
  final String? initialNotes;

  const CustomerInfoDialog({
    super.key,
    this.initialName,
    this.initialPhone,
    this.initialEmail,
    this.initialNotes,
  });

  @override
  State<CustomerInfoDialog> createState() => _CustomerInfoDialogState();
}

class _CustomerInfoDialogState extends State<CustomerInfoDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;
  late final TextEditingController _searchController;

  Customer? _selectedCustomer;
  List<Customer> _customerSuggestions = [];
  bool _isSearchingCustomer = false;
  bool _showSearchMode = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _notesController = TextEditingController(text: widget.initialNotes);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Search for customers by phone number or name
  Future<void> _searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _customerSuggestions = []);
      return;
    }

    setState(() => _isSearchingCustomer = true);

    try {
      final suggestions = await DatabaseService.instance.searchCustomers(query);
      setState(() {
        _customerSuggestions = suggestions;
        _isSearchingCustomer = false;
      });
    } catch (e) {
      setState(() => _isSearchingCustomer = false);
    }
  }

  /// Select a customer from suggestions
  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _customerSuggestions = [];
      _showSearchMode = false;
    });
  }

  /// Clear customer selection
  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _customerSuggestions = [];
      _showSearchMode = false;
    });
  }

  /// Toggle between search mode and manual entry mode
  void _toggleSearchMode() {
    setState(() {
      _showSearchMode = !_showSearchMode;
      if (!_showSearchMode) {
        _customerSuggestions = [];
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Customer Information'),
          const Spacer(),
          IconButton(
            onPressed: _toggleSearchMode,
            icon: Icon(_showSearchMode ? Icons.edit : Icons.search),
            tooltip: _showSearchMode ? 'Manual Entry' : 'Search Customer',
            iconSize: 20,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Customer search mode
            if (_showSearchMode) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Customer',
                  hintText: 'Enter name, phone, or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearchingCustomer
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _customerSuggestions = []);
                                },
                              )
                            : null),
                  border: const OutlineInputBorder(),
                  helperText: 'Search existing customers',
                ),
                onChanged: _searchCustomers,
              ),

              // Customer suggestions dropdown
              if (_customerSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _customerSuggestions.length,
                    itemBuilder: (context, index) {
                      final customer = _customerSuggestions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(
                          '${customer.phone ?? 'No phone'} • ${customer.customerTier} • ${customer.visitCount} visits',
                        ),
                        trailing: Text(
                          '${customer.loyaltyPoints} pts',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _selectCustomer(customer),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // Selected customer info display
            if (_selectedCustomer != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _clearCustomer,
                            icon: const Icon(Icons.clear, size: 16),
                            tooltip: 'Clear selection',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedCustomer!.customerTier} Customer',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_selectedCustomer!.visitCount} visits • RM${_selectedCustomer!.totalSpent.toStringAsFixed(2)} total spent',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (_selectedCustomer!.loyaltyPoints > 0)
                        Text(
                          '${_selectedCustomer!.loyaltyPoints} loyalty points',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Manual entry fields
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                hintText: 'Enter customer name',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                helperText: _selectedCustomer != null
                    ? 'Customer selected - field locked'
                    : 'Enter customer name (optional)',
              ),
              textCapitalization: TextCapitalization.words,
              enabled: _selectedCustomer == null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
                helperText: _selectedCustomer != null
                    ? 'Customer selected - field locked'
                    : 'Enter phone number (optional)',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              enabled: _selectedCustomer == null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter email address',
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                helperText: _selectedCustomer != null
                    ? 'Customer selected - field locked'
                    : 'Enter email address (optional)',
              ),
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              enabled: _selectedCustomer == null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions / Notes',
                hintText: 'Any special requests or notes (optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'customerName': _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
              'customerPhone': _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              'customerEmail': _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              'specialInstructions': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              'selectedCustomer': _selectedCustomer,
            });
          },
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

/// A compact widget to display and edit customer information
class CustomerInfoWidget extends StatelessWidget {
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? specialInstructions;
  final VoidCallback? onEdit;

  const CustomerInfoWidget({
    super.key,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.specialInstructions,
    this.onEdit,
  });

  bool get hasCustomerInfo =>
      customerName != null ||
      customerPhone != null ||
      customerEmail != null ||
      specialInstructions != null;

  @override
  Widget build(BuildContext context) {
    if (!hasCustomerInfo && onEdit == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Customer Information',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: 'Edit customer information',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
            if (hasCustomerInfo) ...[
              const SizedBox(height: 4),
              if (customerName != null) ...[
                Row(
                  children: [
                    const SizedBox(width: 28),
                    const Icon(Icons.badge, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerName!,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (customerPhone != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const SizedBox(width: 28),
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerPhone!,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (customerEmail != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const SizedBox(width: 28),
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerEmail!,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (specialInstructions != null) ...[
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 28),
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        specialInstructions!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (onEdit != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      'No customer information added',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
