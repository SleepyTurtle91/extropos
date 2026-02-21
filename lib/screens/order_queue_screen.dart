import 'dart:async';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/order_status.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:flutter/material.dart';

class QueueOrder {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final DateTime createdAt;
  final int itemCount;

  QueueOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.itemCount,
  });

  factory QueueOrder.fromMap(Map<String, dynamic> map) {
    return QueueOrder(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      status: parseOrderStatus(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      itemCount: map['item_count'] as int? ?? 0,
    );
  }

  Duration get waitTime => DateTime.now().difference(createdAt);
}

class OrderQueueScreen extends StatefulWidget {
  const OrderQueueScreen({super.key});

  @override
  State<OrderQueueScreen> createState() => _OrderQueueScreenState();
}

class _OrderQueueScreenState extends State<OrderQueueScreen> {
  List<QueueOrder> _preparingOrders = [];
  List<QueueOrder> _readyOrders = [];
  Timer? _refreshTimer;
  Timer? _autoRemoveTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();

    // Auto-refresh every 5 seconds (faster than kitchen display)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadOrders(silent: true);
    });

    // Check for old ready orders every minute
    _autoRemoveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _removeOldReadyOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _autoRemoveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      // Get cafe orders with preparing or ready status
      final ordersData = await DatabaseService.instance.getCafeQueueOrders();

      final List<QueueOrder> allOrders = [];
      for (final orderMap in ordersData) {
        final order = QueueOrder.fromMap(orderMap);
        allOrders.add(order);
      }

      if (mounted) {
        setState(() {
          _preparingOrders = allOrders
              .where((o) => o.status == OrderStatus.preparing)
              .toList();
          _readyOrders = allOrders
              .where((o) => o.status == OrderStatus.ready)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeOldReadyOrders() {
    // Remove orders that have been ready for more than 5 minutes
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 5));

    setState(() {
      _readyOrders.removeWhere((order) => order.createdAt.isBefore(cutoff));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1A1A1A,
      ), // Dark background for visibility
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.receipt_long, size: 28),
            const SizedBox(width: 12),
            // Make title flexible so it ellipsizes on very narrow widths instead of overflowing.
            Expanded(
              child: Text(
                BusinessInfo.instance.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOrders(),
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _preparingOrders.isEmpty && _readyOrders.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header
                _buildHeader(),

                // Orders Grid
                Expanded(child: _buildOrdersGrid()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildHeaderSection(
              'PREPARING',
              _preparingOrders.length,
              const Color(0xFFFFC107), // Amber
              Icons.restaurant,
            ),
          ),
          Container(width: 2, height: 60, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: _buildHeaderSection(
              'READY FOR PICKUP',
              _readyOrders.length,
              const Color(0xFF4CAF50), // Green
              Icons.done_all,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 12),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Column sizing is adaptive using maxCrossAxisExtent for predictable tile widths

        // Combine orders: ready first, then preparing
        final displayOrders = [..._readyOrders, ..._preparingOrders];

        if (displayOrders.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.xl),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: AppTokens.tableCardMinWidth + 40,
            crossAxisSpacing: AppSpacing.xl,
            mainAxisSpacing: AppSpacing.xl,
            childAspectRatio: 1.2,
          ),
          itemCount: displayOrders.length,
          itemBuilder: (context, index) {
            final order = displayOrders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(QueueOrder order) {
    final isReady = order.status == OrderStatus.ready;
    final color = isReady ? const Color(0xFF4CAF50) : const Color(0xFFFFC107);
    final label = isReady ? 'READY' : 'PREPARING';

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Order Number
            Text(
              order.orderNumber.split('-').last, // Extract just the number part
              style: TextStyle(
                color: color,
                fontSize: 80,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),

            const SizedBox(height: 8),

            // Wait Time (for preparing orders)
            if (!isReady) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 6),
                  Text(
                    _formatWaitTime(order.waitTime),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Ready indicator animation
            if (isReady) ...[_buildReadyPulse()],
          ],
        ),
      ),
    );
  }

  Widget _buildReadyPulse() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      onEnd: () {
        if (mounted) {
          setState(() {}); // Trigger rebuild to restart animation
        }
      },
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(
            Icons.check_circle,
            color: const Color(0xFF4CAF50).withOpacity(value),
            size: 48,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.coffee, size: 120, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text(
            'No orders at the moment',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Orders will appear here when ready',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWaitTime(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes == 1) return '1 min';
    return '$minutes mins';
  }
}
