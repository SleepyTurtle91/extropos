import 'package:extropos/models/dealer_customer_model.dart';
import 'package:extropos/models/tenant_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/tenant_provisioning_service.dart';
import 'package:flutter/material.dart';

part 'tenant_onboarding_screen_ui.dart';

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
    throw UnimplementedError('See tenant_onboarding_screen_ui.dart');
  }
}
