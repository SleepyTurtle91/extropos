part of 'kitchen_display_screen.dart';

extension _KitchenDisplayUIBuilders on _KitchenDisplayScreenState {
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            // Mobile: stack vertically in a flexible Wrap so we don't cause vertical overflow
            return Wrap(
              runSpacing: 8,
              spacing: 8,
              children: [
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildStatCard(
                    'Active Orders',
                    _activeOrders.toString(),
                    Icons.pending_actions,
                    const Color(0xFF2196F3),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildStatCard(
                    'Completed Today',
                    _todayCompleted.toString(),
                    Icons.check_circle,
                    const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildStatCard(
                    'Avg Wait Time',
                    '${_averageWaitTime.inMinutes} min',
                    Icons.timer,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            );
          } else {
            // Desktop: Horizontal row
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Orders',
                    _activeOrders.toString(),
                    Icons.pending_actions,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed Today',
                    _todayCompleted.toString(),
                    Icons.check_circle,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg Wait Time',
                    '${_averageWaitTime.inMinutes} min',
                    Icons.timer,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterTabs() {
    final statuses = [
      OrderStatus.sentToKitchen, // Shows all active
      OrderStatus.preparing,
      OrderStatus.ready,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = _filterStatus == status;
            final count = status == OrderStatus.sentToKitchen
                ? _orders.where((o) => o.status.isActive).length
                : _orders.where((o) => o.status == status).length;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status.icon,
                      size: 18,
                      color: isSelected ? Colors.white : status.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status == OrderStatus.sentToKitchen
                          ? 'All Active ($count)'
                          : '${status.displayName} ($count)',
                    ),
                  ],
                ),
                selectedColor: status.color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _filterStatus = status);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders in ${_filterStatus.displayName.toLowerCase()}',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here when sent to kitchen',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use maxCrossAxisExtent for adaptive columns across displays

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.l),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: AppTokens.tableCardMinWidth + 40,
            crossAxisSpacing: AppSpacing.l,
            mainAxisSpacing: AppSpacing.l,
            childAspectRatio: 0.9,
          ),
          itemCount: _filteredOrders.length,
          itemBuilder: (context, index) {
            final order = _filteredOrders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(KitchenOrder order) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: order.status.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: order.status.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.waitTimeDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.tableName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.table_restaurant,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.tableName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: order.status.color,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (item.modifiers != null &&
                                    item.modifiers!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.modifiers!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                if (item.seatNumber != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_seat,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Seat ${item.seatNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (index < order.items.length - 1)
                        Divider(color: Colors.grey[300], height: 16),
                    ],
                  ),
                );
              },
            ),
          ),

          // Special Instructions
          if (order.specialInstructions != null &&
              order.specialInstructions!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.specialInstructions!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildActionButtons(order),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(KitchenOrder order) {
    final List<Widget> buttons = [];

    if (order.status.canMarkPreparing) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, OrderStatus.preparing),
            icon: const Icon(Icons.restaurant, size: 18),
            label: const Text('Start Preparing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    if (order.status.canMarkReady) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, OrderStatus.ready),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark Ready'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    if (order.status.canMarkServed) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, OrderStatus.served),
            icon: const Icon(Icons.room_service, size: 18),
            label: const Text('Mark Served'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return Text(
        order.status.displayName,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: order.status.color,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (buttons.length == 1) {
      return buttons.first;
    }

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          buttons[i],
        ],
      ],
    );
  }
}
