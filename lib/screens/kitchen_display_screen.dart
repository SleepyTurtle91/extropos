import 'dart:async';

import 'package:extropos/models/kitchen_order.dart';
import 'package:extropos/models/order_status.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'kitchen_display_screen_ui.dart';

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  List<KitchenOrder> _orders = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  OrderStatus _filterStatus = OrderStatus.sentToKitchen;

  // Statistics
  int _todayCompleted = 0;
  int _activeOrders = 0;
  Duration _averageWaitTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      // Get orders with active kitchen statuses
      final ordersData = await DatabaseService.instance.getKitchenOrders();

      final List<KitchenOrder> loadedOrders = [];

      for (final orderMap in ordersData) {
        final order = KitchenOrder.fromMap(orderMap);

        // Get order items
        final itemsData = await DatabaseService.instance.getOrderItems(
          order.id,
        );
        final items = itemsData
            .map((i) => KitchenOrderItem.fromMap(i))
            .toList();

        loadedOrders.add(
          KitchenOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            tableName: order.tableName,
            items: items,
            status: order.status,
            createdAt: order.createdAt,
            sentToKitchenAt: order.sentToKitchenAt,
            specialInstructions: order.specialInstructions,
          ),
        );
      }

      // Calculate statistics
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      _todayCompleted = await DatabaseService.instance.getOrderCountByStatus(
        OrderStatus.completed,
        startDate: todayStart,
      );

      _activeOrders = loadedOrders.where((o) => o.status.isActive).length;

      if (loadedOrders.isNotEmpty) {
        final totalWait = loadedOrders.fold(
          Duration.zero,
          (sum, order) => sum + order.waitTime,
        );
        _averageWaitTime = totalWait ~/ loadedOrders.length;
      }

      if (mounted) {
        setState(() {
          _orders = loadedOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          ToastHelper.showToast(context, 'Failed to load kitchen orders: $e');
        }
      }
    }
  }

  Future<void> _updateOrderStatus(
    KitchenOrder order,
    OrderStatus newStatus,
  ) async {
    try {
      await DatabaseService.instance.updateOrderStatus(order.id, newStatus);

      if (context.mounted) {
        ToastHelper.showToast(
          context,
          'Order ${order.orderNumber} marked as ${newStatus.displayName}',
        );
      }

      await _loadOrders();
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'Failed to update order: $e');
      }
    }
  }

  List<KitchenOrder> get _filteredOrders {
    if (_filterStatus == OrderStatus.sentToKitchen) {
      // Show all active kitchen orders
      return _orders.where((o) {
        return o.status == OrderStatus.sentToKitchen ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready;
      }).toList();
    }
    return _orders.where((o) => o.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('Kitchen Display System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOrders(),
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildStatsSection()),
          SliverToBoxAdapter(child: _buildStatusFilterTabs()),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersGrid(),
          ),
        ],
      ),
    );
  }
}
