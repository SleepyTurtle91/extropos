import 'package:extropos/models/dealer_customer_model.dart';
import 'package:extropos/models/tenant_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/tenant_provisioning_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

class TenantOnboardingScreen extends StatefulWidget {
  const TenantOnboardingScreen({super.key});

  @override
  State<TenantOnboardingScreen> createState() => _TenantOnboardingScreenState();
}

class _TenantOnboardingScreenState extends State<TenantOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _customDomainController = TextEditingController();

  bool _isCreating = false;
  bool _isLoadingCustomers = true;
  String? _createdTenantId;
  String? _errorMessage;

  List<DealerCustomer> _customers = [];
  DealerCustomer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final maps = await DatabaseService.instance.getDealerCustomers();
      final customers = maps.map((map) => DealerCustomer.fromMap(map)).toList();

      setState(() {
        _customers = customers;
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() => _isLoadingCustomers = false);
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

  void _onCustomerSelected(DealerCustomer? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _tenantNameController.text = customer.businessName;
        _ownerNameController.text = customer.ownerName;
        _ownerEmailController.text = customer.email;
      } else {
        _tenantNameController.clear();
        _ownerNameController.clear();
        _ownerEmailController.clear();
      }
    });
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _ownerEmailController.dispose();
    _ownerNameController.dispose();
    _customDomainController.dispose();
    super.dispose();
  }

  Future<void> _createTenant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _createdTenantId = null;
    });

    try {
      final tenantId = await TenantProvisioningService.instance.createTenant(
        tenantName: _tenantNameController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        customDomain: _customDomainController.text.trim().isNotEmpty
            ? _customDomainController.text.trim()
            : null,
      );

      // Save tenant info to local database
      final tenant = Tenant(
        id: tenantId,
        customerId: _selectedCustomer!.id,
        tenantName: _tenantNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim(),
        customDomain: _customDomainController.text.trim().isNotEmpty
            ? _customDomainController.text.trim()
            : null,
      );

      await DatabaseService.instance.insertTenant(tenant.toMap());

      setState(() {
        _createdTenantId = tenantId;
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tenant created successfully! ID: $tenantId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Clear form
      _selectedCustomer = null;
      _tenantNameController.clear();
      _ownerEmailController.clear();
      _ownerNameController.clear();
      _customDomainController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating tenant: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Tenant Onboarding',
      subtitle: 'Tenant provisioning is coming soon.',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Onboarding'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            color: Colors.blue[900],
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Create New Tenant',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provision a new isolated database and collections for a tenant. '
                        'Each tenant gets their own database with complete data isolation.',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Success Message
              if (_createdTenantId != null) ...[
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Tenant Created Successfully!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          'Tenant ID: $_createdTenantId',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.green[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The tenant database and all required collections have been created. '
                          'Save this tenant ID for configuration.',
                          style: TextStyle(color: Colors.green[800]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Error Message
              if (_errorMessage != null) ...[
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Form Fields
              const Text(
                'Tenant Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Customer Selection Dropdown
              if (_isLoadingCustomers)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_customers.isEmpty)
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange[700],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No customers registered yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please register customers first before creating tenants',
                          style: TextStyle(color: Colors.orange[800]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                DropdownButtonFormField<DealerCustomer>(
                  value: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'Select Customer *',
                    hintText: 'Choose a registered customer',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  items: _customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer,
                      child: Text(customer.displayName),
                    );
                  }).toList(),
                  onChanged: _isCreating ? null : _onCustomerSelected,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a customer';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Tenant Name
              TextFormField(
                controller: _tenantNameController,
                decoration: const InputDecoration(
                  labelText: 'Business/Tenant Name *',
                  hintText: 'e.g., Coffee Shop Central',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                enabled: !_isCreating,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tenant name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner Name
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Full Name *',
                  hintText: 'e.g., John Doe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: !_isCreating,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Owner name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner Email
              TextFormField(
                controller: _ownerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Owner Email *',
                  hintText: 'owner@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isCreating,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Owner email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom Domain (Optional)
              TextFormField(
                controller: _customDomainController,
                decoration: const InputDecoration(
                  labelText: 'Custom Domain (Optional)',
                  hintText: 'tenant.example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                  helperText: 'Leave empty if not using custom domain',
                ),
                enabled: !_isCreating,
              ),

              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createTenant,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_business),
                  label: Text(
                    _isCreating ? 'Creating Tenant...' : 'Create Tenant',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Information Card
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.amber[900]),
                          const SizedBox(width: 8),
                          Text(
                            'What Gets Created',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Isolated database for the tenant\n'
                        '• business_info collection\n'
                        '• categories collection\n'
                        '• products collection\n'
                        '• modifiers collection\n'
                        '• tables collection\n'
                        '• users collection\n'
                        '• Initial business info document\n'
                        '• Admin user account',
                        style: TextStyle(color: Colors.amber[900]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Security Note
              Card(
                color: Colors.purple[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.purple[900]),
                          const SizedBox(width: 8),
                          Text(
                            'Security & Isolation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Each tenant gets a completely isolated database. '
                        'Data from different tenants cannot mix or be accessed '
                        'across tenant boundaries. All collections have proper '
                        'read/write permissions configured.',
                        style: TextStyle(color: Colors.purple[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
