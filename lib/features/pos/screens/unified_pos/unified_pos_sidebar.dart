part of 'unified_pos_screen.dart';

extension _UnifiedPOSSidebar on _UnifiedPOSScreenState {
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
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
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
                const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
      case 'Reports':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
      case 'Transactions':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
        );
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RefundScreen()),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _handleSidebarAction(label),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade600],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : highlight
                    ? LinearGradient(
                        colors: [Colors.red.shade50, Colors.red.shade100],
                      )
                    : null,
            borderRadius: BorderRadius.circular(16),
            border: highlight
                ? Border.all(color: Colors.red.shade300, width: 1)
                : isActive
                    ? null
                    : Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.2)
                      : highlight
                          ? Colors.red.shade100
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? Colors.white
                      : highlight
                          ? Colors.red.shade600
                          : Colors.grey.shade600,
                  size: 18,
                ),
              ),
              if (!isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : highlight
                              ? Colors.red.shade700
                              : Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            ],
          ),
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
            if (mode != POSMode.restaurant) {
              selectedTableId = null;
            }
          });
          _fetchData();
          if (mode == POSMode.restaurant) {
            _loadTables();
          }
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> refreshTables() async {
              final tables = await DatabaseService.instance.getTables();
              if (!mounted) return;
              _updateState(() => availableTables = tables);
              setModalState(() {});
            }

            Color statusColor(TableStatus status) {
              switch (status) {
                case TableStatus.available:
                  return Colors.green;
                case TableStatus.occupied:
                  return Colors.orange;
                case TableStatus.reserved:
                  return Colors.blue;
                case TableStatus.merged:
                  return Colors.purple;
                case TableStatus.cleaning:
                  return Colors.brown;
              }
            }

            if (availableTables.isEmpty) {
              refreshTables();
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Table',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: refreshTables,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh tables',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (selectedTableId != null)
                      TextButton.icon(
                        onPressed: () {
                          _updateState(() => selectedTableId = null);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear selected table'),
                      ),
                    const SizedBox(height: 8),
                    if (availableTables.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No tables found. Configure tables first.'),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: availableTables.length,
                          separatorBuilder: (_, separatorIndex) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final table = availableTables[index];
                            final selected = table.id == selectedTableId;

                            return ListTile(
                              onTap: () {
                                _updateState(() {
                                  selectedTableId = table.id;
                                  activeTab = 'POS';
                                });
                                Navigator.pop(context);
                                ToastHelper.showToast(context, 'Selected ${table.name}');
                              },
                              leading: CircleAvatar(
                                backgroundColor: statusColor(table.status).withOpacity(0.12),
                                child: Icon(
                                  Icons.table_restaurant,
                                  color: statusColor(table.status),
                                ),
                              ),
                              title: Text(table.name),
                              subtitle: Text(
                                '${table.status.name.toUpperCase()} • Capacity ${table.capacity}',
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
