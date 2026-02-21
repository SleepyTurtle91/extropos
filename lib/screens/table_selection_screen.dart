import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/screens/pos_order_screen_fixed.dart';
import 'package:extropos/screens/shift/end_shift_dialog.dart';
import 'package:extropos/screens/shift/start_shift_dialog.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/reset_service.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/services/table_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class TableSelectionScreen extends StatefulWidget {
  final bool embedded;

  const TableSelectionScreen({super.key, this.embedded = false});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  late TableService _tableService;
  bool _mergeMode = false;
  bool _splitMode = false;
  RestaurantTable? _sourceTableForSplit;
  final Set<String> _selectedTableIds = {};

  @override
  void initState() {
    super.initState();
    _tableService = TableService();
    _tableService.initialize();
    _tableService.addListener(_onTablesChanged);

    // Listen for reset events to clear table orders
    ResetService.instance.addListener(_handleReset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
  }

  @override
  void dispose() {
    _tableService.removeListener(_onTablesChanged);
    // Remove ResetService listener
    ResetService.instance.removeListener(_handleReset);
    _tableService.dispose();
    super.dispose();
  }

  void _onTablesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkShiftStatus() async {
    try {
      final shiftService = ShiftService.instance;
      final currentUser = LockManager.instance.currentUser;

      if (currentUser == null) return;

      final activeShift = await shiftService.getCurrentShift(currentUser.id);

      if (activeShift == null) {
        if (!mounted) return;
        // Force start shift
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StartShiftDialog(userId: currentUser.id),
        );
      }
    } catch (e) {
      developer.log('Error checking shift status: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Error checking shift status');
      }
    }
  }

  void _manageShift() async {
    try {
      final shiftService = ShiftService.instance;
      final currentUser = LockManager.instance.currentUser;

      if (currentUser == null) return;

      final shift = await shiftService.getCurrentShift(currentUser.id);

      if (!mounted) return;

      if (shift == null) {
        await showDialog(
          context: context,
          builder: (context) => StartShiftDialog(userId: currentUser.id),
        );
        return;
      }

      // Show options: End Shift or Cancel
      final shouldEnd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Shift Management'),
          content: Text('Current Shift started at:\n${shift.startTime}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'End Shift',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldEnd == true && mounted) {
        await showDialog(
          context: context,
          builder: (context) => EndShiftDialog(shift: shift),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Error managing shift: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        ToastHelper.showToast(context, 'Error managing shift. Please try again.');
      }
    }
  }

  Future<void> _loadTables() async {
    // Tables are now loaded automatically by TableService
    // This method is kept for compatibility but now just triggers a refresh
    await _tableService.refreshTables();
  }

  void _handleReset() {
    if (!mounted) return;
    _loadTables();
  }

  void _onTableTap(RestaurantTable t) async {
    if (_mergeMode) {
      setState(() {
        if (_selectedTableIds.contains(t.id)) {
          _selectedTableIds.remove(t.id);
        } else {
          _selectedTableIds.add(t.id);
        }
      });
      return;
    }

    final parentNavigator = Navigator.of(context);
    await parentNavigator.push(
      MaterialPageRoute(builder: (_) => POSOrderScreen(table: t)),
    );

    if (!mounted) return;
    // Force UI update to reflect table status changes
    setState(() {});

    // Note: Don't reload tables here as the table object is updated in-place
    // and orders are stored in memory only
    // await _loadTables();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Grid sizing is handled by maxCrossAxisExtent for adaptive columns;
        // keep a responsive childAspectRatio below.

        double childAspectRatio = 1.2;
        if (constraints.maxWidth < 600) {
          childAspectRatio = 1.05;
        } else if (constraints.maxWidth < 900) {
          childAspectRatio = 1.1;
        }

        final tableGrid = GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: AppTokens.tableCardMinWidth + 40,
            mainAxisSpacing: AppSpacing.m,
            crossAxisSpacing: AppSpacing.m,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _tableService.tables.length,
          itemBuilder: (context, index) {
            final t = _tableService.tables[index];
            return GestureDetector(
              onTap: () => _onTableTap(t),
              child: TableCard(
                table: t,
                onTap: () => _onTableTap(t),
                isSelected: _selectedTableIds.contains(t.id),
              ),
            );
          },
        );

        if (widget.embedded) {
          return Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.table_restaurant, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Tables',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      ..._buildActionButtons(),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              Expanded(child: tableGrid),
            ],
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Tables'), actions: _buildActionButtons()),
          body: tableGrid,
        );
      },
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      IconButton(
        icon: const Icon(Icons.access_time),
        tooltip: 'Shift Management',
        onPressed: _manageShift,
      ),
      if (_mergeMode) ...[
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _mergeMode = false;
            _selectedTableIds.clear();
          }),
          tooltip: 'Cancel merge mode',
        ),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _onMergePressed,
          tooltip: 'Confirm merge',
        ),
      ] else if (_splitMode) ...[
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _splitMode = false;
            _sourceTableForSplit = null;
            _selectedTableIds.clear();
          }),
          tooltip: 'Cancel split mode',
        ),
        IconButton(
          icon: const Icon(Icons.call_split),
          onPressed: _onSplitPressed,
          tooltip: 'Confirm split',
        ),
      ] else ...[
        IconButton(
          icon: const Icon(Icons.merge_type),
          onPressed: () => setState(() {
            _mergeMode = true;
          }),
          tooltip: 'Enter merge mode',
        ),
        IconButton(
          icon: const Icon(Icons.call_split),
          onPressed: _enterSplitMode,
          tooltip: 'Enter split mode',
        ),
      ],
    ];
  }

  void _onMergePressed() async {
    if (_selectedTableIds.length < 2) {
      ToastHelper.showToast(context, 'Select at least two tables to merge');
      return;
    }

    final tablesById = {for (final t in _tableService.tables) t.id: t};
    final selectedTables = _selectedTableIds
        .map((id) => tablesById[id]!)
        .toList();

    final target = await showDialog<RestaurantTable?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select target table for merge'),
        children: _tableService.tables
            .where((t) => _selectedTableIds.contains(t.id))
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(t),
                child: Text(t.name),
              ),
            )
            .toList(),
      ),
    );

    if (target == null) return;

    // Confirm merge with the user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Merge'),
        content: Text(
          'Merge ${selectedTables.length} tables into ${target.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Use TableService for merge operation
    final success = await _tableService.mergeTables(
      targetTableId: target.id,
      sourceTableIds: selectedTables.map((t) => t.id).toList(),
    );

    if (success) {
      _selectedTableIds.clear();
      _mergeMode = false;
      ToastHelper.showToast(context, 'Tables merged successfully');
    } else {
      ToastHelper.showToast(context, 'Failed to merge tables');
    }
  }

  void _enterSplitMode() async {
    // First, let user select a source table with orders
    final occupiedTables = _tableService.tables.where((t) => t.isOccupied).toList();

    if (occupiedTables.isEmpty) {
      ToastHelper.showToast(context, 'No occupied tables to split');
      return;
    }

    final sourceTable = await showDialog<RestaurantTable?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select table to split'),
        children: occupiedTables.map(
          (t) => SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(t),
            child: Text('${t.name} (${t.itemCount} items)'),
          ),
        ).toList(),
      ),
    );

    if (sourceTable == null) return;

    setState(() {
      _splitMode = true;
      _sourceTableForSplit = sourceTable;
    });
  }

  void _onSplitPressed() async {
    if (_sourceTableForSplit == null || _selectedTableIds.isEmpty) {
      ToastHelper.showToast(context, 'Select target table(s) for split');
      return;
    }

    // Show order selection dialog
    final ordersToSplit = await showDialog<List<CartItem>?>(
      context: context,
      builder: (ctx) => _OrderSelectionDialog(
        sourceTable: _sourceTableForSplit!,
        availableTargets: _tableService.tables
            .where((t) => _selectedTableIds.contains(t.id))
            .toList(),
      ),
    );

    if (ordersToSplit == null || ordersToSplit.isEmpty) return;

    // Select target table
    final targetTable = await showDialog<RestaurantTable?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select target table'),
        children: _tableService.tables
            .where((t) => _selectedTableIds.contains(t.id))
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(t),
                child: Text(t.name),
              ),
            )
            .toList(),
      ),
    );

    if (targetTable == null) return;

    // Confirm split
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Split'),
        content: Text(
          'Move ${ordersToSplit.length} item(s) from ${_sourceTableForSplit!.name} to ${targetTable.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Split'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform split using TableService
    final success = await _tableService.splitTableOrders(
      sourceTableId: _sourceTableForSplit!.id,
      targetTableId: targetTable.id,
      ordersToMove: ordersToSplit,
    );

    if (success) {
      setState(() {
        _splitMode = false;
        _sourceTableForSplit = null;
        _selectedTableIds.clear();
      });
      ToastHelper.showToast(context, 'Table split successfully');
    } else {
      ToastHelper.showToast(context, 'Failed to split table');
    }
  }
}

// Status chips and header are intentionally omitted here; table selection
// UI shows a simple grid. A richer header can be added later if desired.

class TableCard extends StatefulWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final bool isSelected;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    this.isSelected = false,
  });
  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  bool _hovering = false;

  Color get _statusColor {
    switch (widget.table.status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        // Show capacity warnings for occupied tables
        if (widget.table.isOverCapacity) {
          return Colors.red; // Over capacity - critical
        } else if (widget.table.isCapacityCritical) {
          return Colors.deepOrange; // At capacity - warning
        } else if (widget.table.needsCapacityWarning) {
          return Colors.orange; // Near capacity - caution
        }
        return Colors.orange; // Normal occupied
      case TableStatus.reserved:
        return Colors.blue;
      case TableStatus.merged:
        return Colors.purple;
      case TableStatus.cleaning:
        return Colors.brown;
    }
  }

  IconData get _statusIcon {
    switch (widget.table.status) {
      case TableStatus.available:
        return Icons.check_circle;
      case TableStatus.occupied:
        return Icons.restaurant_menu;
      case TableStatus.reserved:
        return Icons.event;
      case TableStatus.merged:
        return Icons.merge;
      case TableStatus.cleaning:
        return Icons.cleaning_services;
    }
  }

  String get _statusText {
    switch (widget.table.status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        if (widget.table.isOverCapacity) {
          return 'OVER CAPACITY';
        } else if (widget.table.isCapacityCritical) {
          return 'AT CAPACITY';
        } else if (widget.table.needsCapacityWarning) {
          return 'NEAR CAPACITY';
        }
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.merged:
        return 'Merged';
      case TableStatus.cleaning:
        return 'Cleaning';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall =
            constraints.maxHeight < 140 || constraints.maxWidth < 200;
        final iconSize = isSmall ? 36.0 : 48.0;
        final titleFontSize = isSmall ? 16.0 : 18.0;
        final capacityFontSize = isSmall ? 11.0 : 12.0;
        final statusFontSize = isSmall ? 11.0 : 12.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            transform: _hovering
                ? (Matrix4.identity()..translate(0, -4))
                : Matrix4.identity(),
            decoration: theme.elevatedCardDecoration.copyWith(
              border: Border.all(
                color: widget.isSelected
                    ? Colors.blueAccent
                    : (widget.table.isOccupied
                          ? _statusColor
                          : Colors.transparent),
                width: widget.isSelected ? 3 : 2,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // border is set on surrounding AnimatedContainer
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Table Icon
                        Icon(
                          Icons.table_restaurant,
                          size: iconSize,
                          color: _statusColor,
                        ),
                        const SizedBox(height: 8),
                        // Table Name
                        Text(
                          widget.table.name,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Capacity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: isSmall ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${widget.table.capacity} seats',
                                style: TextStyle(
                                  fontSize: capacityFontSize,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _statusColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon,
                                size: isSmall ? 12 : 14,
                                color: _statusColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _statusText,
                                  style: TextStyle(
                                    fontSize: statusFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Order Info (if occupied)
                        if (widget.table.isOccupied) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${widget.table.itemCount} items',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.table.currentOccupancy}/${widget.table.capacity}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.table.needsCapacityWarning
                                      ? Colors.orange[700]
                                      : Colors.grey[600],
                                  fontWeight: widget.table.needsCapacityWarning
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${BusinessInfo.instance.currencySymbol} ${widget.table.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Selection overlay — show a check circle when selected
                  if (widget.isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blueAccent,
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderSelectionDialog extends StatefulWidget {
  final RestaurantTable sourceTable;
  final List<RestaurantTable> availableTargets;

  const _OrderSelectionDialog({
    required this.sourceTable,
    required this.availableTargets,
  });

  @override
  State<_OrderSelectionDialog> createState() => _OrderSelectionDialogState();
}

class _OrderSelectionDialogState extends State<_OrderSelectionDialog> {
  final Set<int> _selectedOrderIndices = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select orders to move from ${widget.sourceTable.name}'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: 400,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select which orders to move to another table:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ...widget.sourceTable.orders.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final order = entry.value;
                  final isSelected = _selectedOrderIndices.contains(index);

                  return CheckboxListTile(
                    title: Text(
                      '${order.product.name} x${order.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${BusinessInfo.instance.currencySymbol}${order.product.price.toStringAsFixed(2)} each',
                    ),
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedOrderIndices.add(index);
                        } else {
                          _selectedOrderIndices.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedOrderIndices.isEmpty
              ? null
              : () {
                  final selectedOrders = _selectedOrderIndices
                      .map((index) => widget.sourceTable.orders[index])
                      .toList();
                  Navigator.pop(context, selectedOrders);
                },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
