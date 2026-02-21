import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:extropos/widgets/horizon_badge.dart';
import 'package:extropos/widgets/horizon_button.dart';
import 'package:extropos/widgets/horizon_layout.dart';
import 'package:extropos/widgets/horizon_metric_card.dart';
import 'package:flutter/material.dart';

/// Horizon Admin - Demo Dashboard Screen
/// Phase 2 implementation showcasing layout architecture
class HorizonDashboardScreen extends StatelessWidget {
  const HorizonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Horizon Dashboard',
      subtitle: 'Cloud analytics is coming soon.',
    );
    return HorizonLayout(
      breadcrumbs: const ['Dashboard'],
      currentRoute: '/',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: HorizonColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back! Here\'s your business overview',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HorizonColors.textSecondary,
                        ),
                  ),
                ],
              ),
              HorizonButton(
                text: 'Sync Now',
                type: HorizonButtonType.primary,
                icon: Icons.sync,
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Metric Cards Grid
          ResponsiveGrid(
            children: [
              HorizonMetricCard(
                title: 'Total Sales',
                value: 'RM 12,450.00',
                subtitle: 'Today',
                icon: Icons.trending_up,
                iconColor: HorizonColors.emerald,
                percentageChange: 12.5,
              ),
              HorizonMetricCard(
                title: 'Orders',
                value: '248',
                subtitle: 'Today',
                icon: Icons.receipt_long_outlined,
                iconColor: HorizonColors.electricIndigo,
                percentageChange: 8.3,
              ),
              HorizonMetricCard(
                title: 'Avg Order Value',
                value: 'RM 50.20',
                subtitle: 'Today',
                icon: Icons.attach_money,
                iconColor: HorizonColors.amber,
                percentageChange: -2.1,
              ),
              HorizonMetricCard(
                title: 'Alerts',
                value: '5',
                subtitle: 'Low stock items',
                icon: Icons.warning_amber_rounded,
                iconColor: HorizonColors.rose,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent Activity Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Orders
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Orders',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: HorizonColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildOrderItem(
                          orderId: 'ORD-2026-001',
                          customer: 'John Doe',
                          amount: 'RM 125.00',
                          status: 'Completed',
                          time: '5 min ago',
                        ),
                        const Divider(height: 24),
                        _buildOrderItem(
                          orderId: 'ORD-2026-002',
                          customer: 'Jane Smith',
                          amount: 'RM 89.50',
                          status: 'Pending',
                          time: '12 min ago',
                        ),
                        const Divider(height: 24),
                        _buildOrderItem(
                          orderId: 'ORD-2026-003',
                          customer: 'Bob Wilson',
                          amount: 'RM 210.00',
                          status: 'Completed',
                          time: '18 min ago',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Quick Actions
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: HorizonColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAction(
                          icon: Icons.inventory_2_outlined,
                          label: 'Manage Inventory',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _buildQuickAction(
                          icon: Icons.receipt_long_outlined,
                          label: 'View Reports',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _buildQuickAction(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required String orderId,
    required String customer,
    required String amount,
    required String status,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: HorizonColors.surfaceGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            size: 20,
            color: HorizonColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HorizonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customer,
                style: const TextStyle(
                  fontSize: 13,
                  color: HorizonColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: HorizonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            StatusBadge(status: status),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HorizonColors.surfaceGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: HorizonColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: HorizonColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: HorizonColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: HorizonColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
