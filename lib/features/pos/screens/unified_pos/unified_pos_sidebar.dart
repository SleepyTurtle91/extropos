part of 'unified_pos_screen.dart';

extension UnifiedPOSSidebar on _UnifiedPOSScreenState {
  Widget _buildSidebar() {
    final isModeLocked = ConfigService.instance.isSetupDone;
    final lockedMode = _getLockModeFromConfig();

    // If mode is locked, force the active mode to match the locked mode
    if (isModeLocked && activeMode != lockedMode) {
      _updateState(() => activeMode = lockedMode);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(isModeLocked, lockedMode),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarSectionLabel('MAIN MENU'),
                _sidebarItem(Icons.grid_view_rounded, 'Dashboard'),
                _sidebarItem(Icons.shopping_bag_outlined, 'POS', isActive: activeTab == 'POS'),
                if (_shouldShowMenuItem('tables'))
                  _sidebarItem(Icons.table_bar_outlined, 'Tables', isActive: activeTab == 'Tables'),
                _sidebarItem(Icons.bar_chart_rounded, 'Reports', isActive: activeTab == 'Reports'),
                _sidebarItem(Icons.history, 'Transactions'),
                if (_shouldShowMenuItem('kitchen'))
                  _sidebarItem(Icons.restaurant_menu, 'Kitchen'),
                _sidebarItem(Icons.undo, 'Return & Void', highlight: true),
                const SizedBox(height: 24),
                // Only show mode selection if setup is NOT complete (mode not locked)
                if (!isModeLocked) ...[
                  _sidebarSectionLabel('SYSTEM MODE'),
                  _modeButton(POSMode.retail, Icons.storefront, 'Retail'),
                  _modeButton(POSMode.cafe, Icons.coffee, 'Cafe'),
                  _modeButton(POSMode.restaurant, Icons.restaurant, 'Dining'),
                ] else if (!isSidebarCollapsed) ...[
                  // Show locked mode indicator
                  _buildLockedModeIndicator(lockedMode),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          _sidebarItem(Icons.settings_outlined, 'Settings'),
          _sidebarItem(Icons.logout, 'Logout'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Determine if a menu item should be shown based on the current/locked mode
  bool _shouldShowMenuItem(String itemType) {
    final lockedMode = _getLockModeFromConfig();
    final currentMode = activeMode;

    // If mode is locked, restrict to that mode's items only
    if (ConfigService.instance.isSetupDone) {
      switch (itemType) {
        case 'tables':
          return lockedMode == POSMode.restaurant;
        case 'kitchen':
          return lockedMode != POSMode.retail;
        default:
          return false;
      }
    }

    // If mode is not locked, show based on current activeMode
    switch (itemType) {
      case 'tables':
        return currentMode == POSMode.restaurant;
      case 'kitchen':
        return currentMode != POSMode.retail;
      default:
        return false;
    }
  }

  /// Get the locked POSMode from ConfigService business type
  POSMode _getLockModeFromConfig() {
    final businessType = ConfigService.instance.businessType;
    switch (businessType.toLowerCase()) {
      case 'retail':
        return POSMode.retail;
      case 'cafe':
        return POSMode.cafe;
      case 'restaurant':
        return POSMode.restaurant;
      default:
        return POSMode.retail;
    }
  }

  /// Show indicator that mode is locked
  Widget _buildLockedModeIndicator(POSMode mode) {
    final modeLabel = _getModeLabel(mode);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Mode',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _getModeIcon(mode),
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 10, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  'Locked',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get human-readable mode label
  String _getModeLabel(POSMode mode) {
    switch (mode) {
      case POSMode.retail:
        return 'Retail';
      case POSMode.cafe:
        return 'Cafe';
      case POSMode.restaurant:
        return 'Dining';
    }
  }

  /// Get icon for mode
  IconData _getModeIcon(POSMode mode) {
    switch (mode) {
      case POSMode.retail:
        return Icons.storefront;
      case POSMode.cafe:
        return Icons.coffee;
      case POSMode.restaurant:
        return Icons.restaurant;
    }
  }

  Widget _buildLogo(bool isModeLocked, POSMode lockedMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('E', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ),
          if (!isSidebarCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ExtroPOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Row(
                    children: [
                      Text(
                        'Terminal ${ConfigService.instance.terminalId}',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      if (isModeLocked) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.lock, size: 8, color: Colors.grey.shade400),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _sidebarSectionLabel(String text) {
    if (isSidebarCollapsed) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 16),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Future<void> _handleSidebarAction(String label) async {
    if (label == 'POS') {
      _updateState(() => activeTab = label);
      return;
    }

    _updateState(() => activeTab = label);

    switch (label) {
      case 'Dashboard':
        // TODO: Implement sales dashboard screen
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const SalesDashboardScreen()),
        // );
        ToastHelper.showToast(context, 'Dashboard not yet implemented');
        break;
      case 'Reports':
        // TODO: Implement reports dashboard screen
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const ReportsDashboardScreen()),
        // );
        ToastHelper.showToast(context, 'Reports not yet implemented');
        break;
      case 'Transactions':
        // TODO: Implement sales history screen
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
        // );
        ToastHelper.showToast(context, 'Transactions not yet implemented');
        break;
      case 'Kitchen':
        // TODO: Implement kitchen display screen
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const KitchenDisplayScreen()),
        // );
        ToastHelper.showToast(context, 'Kitchen display not yet implemented');
        break;
      case 'Return & Void':
        // TODO: Implement refund service screen
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const RefundServiceScreen()),
        // );
        ToastHelper.showToast(context, 'Return & Void not yet implemented');
        break;
      case 'Tables':
        if (activeMode == POSMode.restaurant) {
          _showTableSelectionDialog();
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TablesManagementScreen()),
          );
        }
        break;
      case 'Settings':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case 'Logout':
        final didSignOut = await showDialog<bool>(
          context: context,
          builder: (_) => const SignOutDialogSimple(),
        );
        if (didSignOut == true && mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/lock', (_) => false);
        }
        break;
      default:
        break;
    }

    if (mounted) {
      _updateState(() => activeTab = 'POS');
    }
  }

  Widget _sidebarItem(IconData icon, String label, {bool isActive = false, bool highlight = false}) {
    return InkWell(
      onTap: () => _handleSidebarAction(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFFF1F2) : (isActive ? Theme.of(context).primaryColor : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: highlight ? Border.all(color: const Color(0xFFF43F5E)) : null,
        ),
        child: Row(
          mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: highlight ? const Color(0xFFF43F5E) : (isActive ? Colors.white : Colors.grey.shade600), size: 20),
            if (!isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: highlight ? const Color(0xFFF43F5E) : (isActive ? Colors.white : Colors.grey.shade700), fontWeight: FontWeight.w500, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _modeButton(POSMode mode, IconData icon, String label) {
    bool isActive = activeMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          _updateState(() {
            activeMode = mode;
            activeTab = 'POS';
            activeCategory = 'All';
          });
          _fetchData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: isActive ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: isActive ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: isActive ? Theme.of(context).primaryColor : Colors.grey, size: 18),
              if (!isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _showTableSelectionDialog() {
    //TODO: Implement table selection dialog
    ToastHelper.showToast(context, 'Table selection coming soon');
  }
}
