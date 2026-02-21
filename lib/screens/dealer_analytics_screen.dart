import 'package:extropos/services/dealer_analytics_service.dart';
import 'package:flutter/material.dart';

/// Dealer Analytics Screen
/// Shows sales and performance metrics for dealer's managed tenants
class DealerAnalyticsScreen extends StatefulWidget {
  const DealerAnalyticsScreen({super.key});

  @override
  State<DealerAnalyticsScreen> createState() => _DealerAnalyticsScreenState();
}

class _DealerAnalyticsScreenState extends State<DealerAnalyticsScreen> {
  String _selectedPeriod = '30d';
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _revenueTrendData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsData = await DealerAnalyticsService.instance.getAnalyticsData(_selectedPeriod);
      final revenueTrendData = await DealerAnalyticsService.instance.getRevenueTrendData(_selectedPeriod);

      setState(() {
        _analyticsData = analyticsData;
        _revenueTrendData = revenueTrendData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Analytics'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Refresh analytics data
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics data refreshed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: 24),

              // Key Metrics Grid
              _buildMetricsGrid(),
              const SizedBox(height: 24),

              // Revenue Section
              _buildRevenueSection(),
              const SizedBox(height: 24),

              // Tenant Status Section
              _buildTenantStatusSection(),
              const SizedBox(height: 24),

              // License Alerts
              _buildLicenseAlertsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodButton('7d', 'Last 7 Days'),
            _buildPeriodButton('30d', 'Last 30 Days'),
            _buildPeriodButton('90d', 'Last 90 Days'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedPeriod = period;
            });
            _loadAnalyticsData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? const Color(0xFF2563EB)
                : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 3;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              icon: Icons.business,
              title: 'Total Tenants',
              value: _analyticsData['totalTenants']?.toString() ?? '0',
              color: Colors.blue,
              subtitle: '+${_analyticsData['newTenants'] ?? 0} new',
            ),
            _buildMetricCard(
              icon: Icons.check_circle,
              title: 'Active Tenants',
              value: _analyticsData['activeTenants']?.toString() ?? '0',
              color: Colors.green,
              subtitle:
                  '${((_analyticsData['activeTenants'] ?? 0) / (_analyticsData['totalTenants'] ?? 1) * 100).toStringAsFixed(0)}% active',
            ),
            _buildMetricCard(
              icon: Icons.attach_money,
              title: 'Total Revenue',
              value: 'RM ${_formatCurrency(_analyticsData['totalRevenue'] ?? 0.0)}',
              color: Colors.orange,
              subtitle:
                  'Avg: RM ${_formatCurrency(_analyticsData['avgRevenuePerTenant'] ?? 0.0)}',
            ),
            _buildMetricCard(
              icon: Icons.key,
              title: 'Active Licenses',
              value: _analyticsData['totalLicenses']?.toString() ?? '0',
              color: Colors.purple,
              subtitle:
                  '${_analyticsData['expiringLicenses'] ?? 0} expiring soon',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildRevenueRow(
              'Total Revenue',
              _analyticsData['totalRevenue'] ?? 0.0,
              Colors.green,
            ),
            const Divider(height: 24),
            _buildRevenueRow(
              'Average Per Tenant',
              _analyticsData['avgRevenuePerTenant'] ?? 0.0,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildRevenueRow(
              'Active Tenant Revenue',
              (_analyticsData['totalRevenue'] ?? 0.0) *
                  ((_analyticsData['activeTenants'] ?? 0) /
                      (_analyticsData['totalTenants'] ?? 1)),
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        Text(
          'RM ${_formatCurrency(amount)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTenantStatusSection() {
    final activePercentage =
        ((_analyticsData['activeTenants'] ?? 0) /
            (_analyticsData['totalTenants'] ?? 1)) *
        100;
    final inactivePercentage = 100 - activePercentage;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tenant Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: activePercentage.toInt(),
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: inactivePercentage.toInt(),
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusLegend(
                  'Active',
                  _analyticsData['activeTenants'] ?? 0,
                  Colors.green,
                ),
                _buildStatusLegend(
                  'Inactive',
                  (_analyticsData['totalTenants'] ?? 0) -
                      (_analyticsData['activeTenants'] ?? 0),
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegend(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildLicenseAlertsSection() {
    final expiringCount = _analyticsData['expiringLicenses'] ?? 0;

    return Card(
      elevation: 2,
      color: expiringCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  expiringCount > 0 ? Icons.warning : Icons.check_circle,
                  color: expiringCount > 0 ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    expiringCount > 0
                        ? 'License Expiration Alerts'
                        : 'All Licenses Active',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (expiringCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                '$expiringCount license(s) expiring within 30 days',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to customer management to view expiring licenses
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Navigate to Customer Management to view details',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }
}
