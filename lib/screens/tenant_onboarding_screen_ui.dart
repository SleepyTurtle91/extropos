part of 'tenant_onboarding_screen.dart';

/// UI extension for TenantOnboardingScreen
extension TenantOnboardingScreenUI on _TenantOnboardingScreenState {
  @override
  Widget build(BuildContext context) {
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
