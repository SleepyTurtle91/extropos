import 'package:extropos/models/dealer_customer_model.dart';
import 'package:extropos/models/tenant_model.dart';
import 'package:extropos/screens/categories_management_screen.dart';
import 'package:extropos/screens/counters_management_screen.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/keygen_home_screen.dart';
import 'package:extropos/screens/modifier_groups_management_screen.dart';
import 'package:extropos/screens/settings_screen.dart';
import 'package:extropos/screens/tenant_login_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

/// Tenant Backend Home Screen
/// Displays tenant-specific data and management options
class TenantBackendHomeScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantBackendHomeScreen({super.key, required this.tenant});

  @override
  State<TenantBackendHomeScreen> createState() =>
      _TenantBackendHomeScreenState();
}

class _TenantBackendHomeScreenState extends State<TenantBackendHomeScreen> {
  DealerCustomer? _customer;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      final customerMap = await DatabaseService.instance.getDealerCustomerById(
        widget.tenant.customerId,
      );

      if (customerMap != null) {
        setState(() {
          _customer = DealerCustomer.fromMap(customerMap);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customer info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TenantLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Tenant Backend',
      subtitle: 'Tenant cloud management is coming soon.',
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tenant.tenantName),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.store,
                              size: 32,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.tenant.ownerName,
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
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildInfoRow('Business', widget.tenant.tenantName),
                      _buildInfoRow('Email', widget.tenant.ownerEmail),
                      _buildInfoRow('Tenant ID', widget.tenant.id),
                      if (_customer != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildInfoRow('Location', _customer!.fullAddress),
                        _buildInfoRow('Phone', _customer!.phone),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Management Options
              const Text(
                'Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildActionCard(
                icon: Icons.category,
                title: 'Categories',
                description: 'Manage product categories',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoriesManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.shopping_bag,
                title: 'Products',
                description: 'Manage menu items and products',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ItemsManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.tune,
                title: 'Modifiers',
                description: 'Manage product modifiers and options',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ModifierGroupsManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.computer,
                title: 'Registered Counters',
                description: 'View and manage POS counters',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CountersManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.vpn_key,
                title: 'License Management',
                description: 'Generate licenses for counters',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KeyGenHomeScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.settings,
                title: 'Business Settings',
                description: 'Configure business information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Info Card
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your tenant database is active and ready to use',
                          style: TextStyle(color: Colors.green[900]),
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
