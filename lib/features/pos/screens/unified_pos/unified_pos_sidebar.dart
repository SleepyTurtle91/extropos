part of 'unified_pos_screen.dart';

extension UnifiedPOSSidebar on _UnifiedPOSScreenState {
  Widget _buildSidebar() {
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
          _buildLogo(),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarSectionLabel('MAIN MENU'),
                _sidebarItem(Icons.grid_view_rounded, 'Dashboard'),
                _sidebarItem(Icons.shopping_bag_outlined, 'POS', isActive: activeTab == 'POS'),
                if (activeMode == POSMode.restaurant)
                  _sidebarItem(Icons.table_bar_outlined, 'Tables', isActive: activeTab == 'Tables'),
                _sidebarItem(Icons.bar_chart_rounded, 'Reports', isActive: activeTab == 'Reports'),
                _sidebarItem(Icons.history, 'Transactions'),
                if (activeMode != POSMode.retail)
                  _sidebarItem(Icons.restaurant_menu, 'Kitchen'),
                _sidebarItem(Icons.undo, 'Return & Void', highlight: true),
                const SizedBox(height: 24),
                _sidebarSectionLabel('SYSTEM MODE'),
                _modeButton(POSMode.retail, Icons.storefront, 'Retail'),
                _modeButton(POSMode.cafe, Icons.coffee, 'Cafe'),
                _modeButton(POSMode.restaurant, Icons.restaurant, 'Dining'),
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

  Widget _buildLogo() {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ExtroPOS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Terminal ${ConfigService.instance.terminalId}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            )
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesDashboardScreen()),
        );
        break;
      case 'Reports':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsDashboardScreen()),
        );
        break;
      case 'Transactions':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
        );
        break;
      case 'Kitchen':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KitchenDisplayScreen()),
        );
        break;
      case 'Return & Void':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RefundServiceScreen()),
        );
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
}
