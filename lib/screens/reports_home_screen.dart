import 'package:extropos/screens/advanced_reports_screen.dart';
import 'package:extropos/screens/modern_reports_dashboard.dart';
import 'package:flutter/material.dart';

/// Reports home screen with visual selection of report types
class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterPOS Reports'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Complete Feature List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Two-column layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 900;

                  if (isMobile) {
                    return Column(
                      children: [
                        _buildBasicReportsSection(context),
                        const SizedBox(height: 24),
                        _buildAdvancedReportsSection(context),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildBasicReportsSection(context),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildAdvancedReportsSection(context),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicReportsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.bar_chart, color: Color(0xFF2563EB), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Basic Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'All Flavors',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Basic report cards
        _buildReportCard(
          context,
          icon: Icons.calendar_today,
          title: 'Daily Reports',
          subtitle: "Today's sales summary",
          color: Colors.blue.shade600,
          onTap: () => _navigateToDashboard(context, 'today'),
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          context,
          icon: Icons.show_chart,
          title: 'Weekly Reports',
          subtitle: '7-day sales trends',
          color: Colors.green.shade600,
          onTap: () => _navigateToDashboard(context, 'week'),
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          context,
          icon: Icons.calendar_month,
          title: 'Monthly Reports',
          subtitle: 'Full month breakdown',
          color: Colors.orange.shade600,
          onTap: () => _navigateToDashboard(context, 'month'),
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          context,
          icon: Icons.date_range,
          title: 'Custom Date Range',
          subtitle: 'User-selected start/end dates',
          color: Colors.purple.shade600,
          onTap: () => _navigateToDashboard(context, 'custom'),
        ),
      ],
    );
  }

  Widget _buildAdvancedReportsSection(BuildContext context) {
    final advancedReports = [
      _AdvancedReportInfo(
        icon: Icons.trending_up,
        title: 'Sales Summary',
        description: 'Gross/net sales, discounts, refunds, tax breakdown',
        color: Colors.blue.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.shopping_bag,
        title: 'Product Sales',
        description: 'Units sold, revenue, top/worst sellers',
        color: Colors.green.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.category,
        title: 'Category Sales',
        description: 'Sales by category, performance metrics',
        color: Colors.orange.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.credit_card,
        title: 'Payment Methods',
        description: 'Transaction breakdown by payment type',
        color: Colors.red.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.people,
        title: 'Employee Performance',
        description: 'Sales per employee, leaderboards, commissions',
        color: Colors.purple.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.inventory,
        title: 'Inventory',
        description: 'Stock levels, reorder points, COGS, GMROI',
        color: Colors.teal.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.warning_amber,
        title: 'Shrinkage',
        description: 'Variance tracking, loss analysis',
        color: Colors.amber.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.work,
        title: 'Labor Cost',
        description: 'Employee costs, labor percentage, efficiency metrics',
        color: Colors.indigo.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.person,
        title: 'Customer Analysis',
        description: 'Top customers, lifetime value, segmentation',
        color: Colors.pink.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.shopping_cart,
        title: 'Basket Analysis',
        description: 'Average basket size, common combinations',
        color: Colors.cyan.shade600,
      ),
      _AdvancedReportInfo(
        icon: Icons.card_giftcard,
        title: 'Loyalty Program',
        description: 'Points earned/redeemed, tier distribution',
        color: Colors.lime.shade600,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.analytics, color: Color(0xFF2563EB), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Advanced Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '11 Types',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Advanced report grid
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 400 ? 1 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: advancedReports.length,
              itemBuilder: (context, index) {
                final report = advancedReports[index];
                return _buildAdvancedReportCard(
                  context,
                  report,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedReportCard(
    BuildContext context,
    _AdvancedReportInfo report,
  ) {
    return Material(
      child: InkWell(
        onTap: () => _navigateToAdvancedReport(context, report.title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: report.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      report.icon,
                      color: report.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                report.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDashboard(BuildContext context, String period) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernReportsDashboard(initialPeriod: period),
      ),
    );
  }

  void _navigateToAdvancedReport(BuildContext context, String reportType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedReportsScreen(),
      ),
    );
  }
}

class _AdvancedReportInfo {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _AdvancedReportInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
