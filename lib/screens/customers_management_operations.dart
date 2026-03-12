part of 'customers_management_screen.dart';

extension _CustomersManagementOperations on _CustomersManagementScreenState {
  Future<void> loadCustomers() async {
    final currentContext = context;
    try {
      final loadedCustomers = await DatabaseService.instance.getCustomers();
      if (!mounted) return;
      setState(() {
        customers = loadedCustomers;
        filteredCustomers = loadedCustomers;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ToastHelper.showToast(currentContext, 'Error loading customers: $e');
    }
  }

  void filterCustomers(String query) {
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

  void addCustomer() {
    final widgetContext = context;
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(
        onSave: (customer) async {
          try {
            await DatabaseService.instance.insertCustomer(customer);
            if (!mounted) return;
            await loadCustomers();
            if (!mounted) return;
            ToastHelper.showToast(widgetContext, 'Customer added successfully');
          } catch (e) {
            if (!mounted) return;
            ToastHelper.showToast(widgetContext, 'Error adding customer: $e');
          }
        },
      ),
    );
  }

  void editCustomer(Customer customer) {
    final widgetContext = context;
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(
        customer: customer,
        onSave: (updatedCustomer) async {
          try {
            await DatabaseService.instance.updateCustomer(updatedCustomer);
            if (!mounted) return;
            await loadCustomers();
            if (!mounted) return;
            ToastHelper.showToast(widgetContext, 'Customer updated successfully');
          } catch (e) {
            if (!mounted) return;
            ToastHelper.showToast(widgetContext, 'Error updating customer: $e');
          }
        },
      ),
    );
  }

  void deleteCustomer(Customer customer) {
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
                await loadCustomers();
                if (!mounted) return;
                ToastHelper.showToast(
                  widgetContext,
                  'Customer deleted successfully',
                );
              } catch (e) {
                if (!mounted) return;
                ToastHelper.showToast(
                  widgetContext,
                  'Error deleting customer: $e',
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int get activeCustomersCount => customers.where((c) => c.isRegular).length;

  int get vipCustomersCount => customers.where((c) => c.totalSpent >= 10000).length;

  int get totalLoyaltyPoints => customers.fold(0, (sum, c) => sum + c.loyaltyPoints);
}
