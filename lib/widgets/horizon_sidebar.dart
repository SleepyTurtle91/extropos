import 'package:extropos/design_system/horizon_colors.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Dark Sidebar Navigation
class HorizonSidebar extends StatefulWidget {
  final bool isCollapsed;
  final Function(bool) onToggleCollapse;
  final String currentRoute;

  const HorizonSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.currentRoute = '/',
  });

  @override
  State<HorizonSidebar> createState() => _HorizonSidebarState();
}

class _HorizonSidebarState extends State<HorizonSidebar> {
  @override
  Widget build(BuildContext context) {
    final width = widget.isCollapsed ? 80.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      color: HorizonColors.deepMidnight,
      child: Column(
        children: [
          // Logo Section
          _buildLogoSection(),

          const SizedBox(height: 24),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/',
                ),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Sales',
                  route: '/sales',
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  route: '/inventory',
                ),
                _buildMenuItem(
                  icon: Icons.people_outline,
                  label: 'Customers',
                  route: '/customers',
                ),
                _buildMenuItem(
                  icon: Icons.analytics_outlined,
                  label: 'Reports',
                  route: '/reports',
                ),
                const SizedBox(height: 12),
                const Divider(color: HorizonColors.deepMidnightLight),
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),

          // Collapse Button
          _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HorizonColors.electricIndigo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.point_of_sale,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'ExtroPOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to route
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? HorizonColors.electricIndigo.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: HorizonColors.electricIndigo.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? HorizonColors.electricIndigoLight
                      : HorizonColors.textTertiary,
                  size: 22,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : HorizonColors.textTertiary,
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onToggleCollapse(!widget.isCollapsed),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HorizonColors.deepMidnightLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isCollapsed
                      ? Icons.chevron_right
                      : Icons.chevron_left,
                  color: HorizonColors.textTertiary,
                  size: 20,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Collapse',
                    style: TextStyle(
                      color: HorizonColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
