import 'package:extropos/design_system/horizon_colors.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Global Header
class HorizonHeader extends StatelessWidget implements PreferredSizeWidget {
  final List<String> breadcrumbs;
  final VoidCallback? onMenuTap;
  final bool showMenu;

  const HorizonHeader({
    super.key,
    this.breadcrumbs = const ['Dashboard'],
    this.onMenuTap,
    this.showMenu = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: HorizonColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: HorizonColors.border,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Hamburger menu (mobile)
            if (showMenu)
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu),
                color: HorizonColors.textPrimary,
              ),

            // Breadcrumbs
            Expanded(
              flex: 2,
              child: _buildBreadcrumbs(),
            ),

            const SizedBox(width: 16),

            // Search Bar
            Expanded(
              flex: 3,
              child: _buildSearchBar(context),
            ),

            const SizedBox(width: 16),

            // Right Actions
            _buildNotificationButton(),
            const SizedBox(width: 12),
            _buildStoreSelector(),
            const SizedBox(width: 12),
            _buildProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        for (int i = 0; i < breadcrumbs.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: HorizonColors.textTertiary,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            breadcrumbs[i],
            style: TextStyle(
              fontSize: 16,
              fontWeight: i == breadcrumbs.length - 1
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: i == breadcrumbs.length - 1
                  ? HorizonColors.textPrimary
                  : HorizonColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 40,
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
          const SizedBox(width: 12),
          const Icon(
            Icons.search,
            size: 20,
            color: HorizonColors.textTertiary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products, orders...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: HorizonColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 14),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: HorizonColors.surfaceWhite,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: HorizonColors.border,
                width: 1,
              ),
            ),
            child: const Text(
              '⌘K',
              style: TextStyle(
                fontSize: 11,
                color: HorizonColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: HorizonColors.textSecondary,
          tooltip: 'Notifications',
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: HorizonColors.rose,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HorizonColors.surfaceGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: HorizonColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.store_outlined,
            size: 18,
            color: HorizonColors.textSecondary,
          ),
          SizedBox(width: 6),
          Text(
            'Main Store',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: HorizonColors.textPrimary,
            ),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: HorizonColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: HorizonColors.electricIndigo,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
