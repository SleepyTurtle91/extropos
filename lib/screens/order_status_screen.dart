import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/screens/start_screen.dart';
import 'package:flutter/material.dart';

enum OrderStatus { received, preparing, ready, completed }

class OrderStatusScreen extends StatefulWidget {
  final List<CartItem> orderItems;
  final String orderNumber;
  final OrderType orderType;
  final String? tableNumber;

  const OrderStatusScreen({
    super.key,
    required this.orderItems,
    required this.orderNumber,
    required this.orderType,
    this.tableNumber,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  OrderStatus _currentStatus = OrderStatus.received;

  @override
  void initState() {
    super.initState();
    // Simulate order status progression
    _simulateOrderProgression();
  }

  void _simulateOrderProgression() {
    // In a real app, this would be updated via WebSocket or polling
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _currentStatus = OrderStatus.preparing);
      }
    });

    Future.delayed(const Duration(seconds: 25), () {
      if (mounted) {
        setState(() => _currentStatus = OrderStatus.ready);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderNumber}'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Order Status Card
              _buildStatusCard(),

              const SizedBox(height: 24),

              // Order Details
              _buildOrderDetails(),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusInfo = _getStatusInfo();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusInfo.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusInfo.icon, size: 40, color: statusInfo.color),
            ),

            const SizedBox(height: 16),

            // Status Text
            Text(
              statusInfo.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Status Description
            Text(
              statusInfo.description,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Progress Indicator
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final statuses = [
      OrderStatus.received,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.completed,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statuses.map((status) {
        final isCompleted =
            statuses.indexOf(status) <= statuses.indexOf(_currentStatus);
        final isCurrent = status == _currentStatus;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF2563EB)
                      : Colors.grey[300],
                  border: isCurrent
                      ? Border.all(color: const Color(0xFF2563EB), width: 3)
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getStatusShortName(status),
                style: TextStyle(
                  fontSize: 10,
                  color: isCompleted
                      ? const Color(0xFF2563EB)
                      : Colors.grey[500],
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Order Items
            ...widget.orderItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.product.name)),
                    Text(
                      '${BusinessInfo.instance.currencySymbol}${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // Order Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Type:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  widget.orderType == OrderType.dineIn ? 'Dine In' : 'Takeaway',
                ),
              ],
            ),

            if (widget.tableNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Table:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(widget.tableNumber!),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${BusinessInfo.instance.currencySymbol}${_calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_currentStatus) {
      case OrderStatus.received:
      case OrderStatus.preparing:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _callServer,
                icon: const Icon(Icons.support_agent),
                label: const Text('Call Server'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  foregroundColor: const Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _cancelOrder,
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        );

      case OrderStatus.ready:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _orderReady,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Order Ready - Pay Now'),
          ),
        );

      case OrderStatus.completed:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rateExperience,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rate Your Experience'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _orderAgain,
                child: const Text('Order Again'),
              ),
            ),
          ],
        );
    }
  }

  _StatusInfo _getStatusInfo() {
    switch (_currentStatus) {
      case OrderStatus.received:
        return _StatusInfo(
          title: 'Order Received',
          description:
              'We\'ve received your order and will start preparing it soon.',
          icon: Icons.receipt,
          color: const Color(0xFF2563EB),
        );

      case OrderStatus.preparing:
        return _StatusInfo(
          title: 'Preparing',
          description: 'Our chefs are working on your delicious meal.',
          icon: Icons.restaurant,
          color: Colors.orange,
        );

      case OrderStatus.ready:
        return _StatusInfo(
          title: 'Ready!',
          description: 'Your order is ready. Please proceed to pickup.',
          icon: Icons.check_circle,
          color: Colors.green,
        );

      case OrderStatus.completed:
        return _StatusInfo(
          title: 'Enjoy!',
          description:
              'Thank you for dining with us. We hope to see you again!',
          icon: Icons.celebration,
          color: Colors.purple,
        );
    }
  }

  String _getStatusShortName(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return 'Received';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Done';
    }
  }

  double _calculateTotal() {
    return widget.orderItems.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  void _callServer() {
    // In a real app, this would send a notification to staff
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server has been notified and will be with you shortly.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In a real app, this would cancel the order
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _orderReady() {
    // In a real app, this would navigate to payment screen
    setState(() => _currentStatus = OrderStatus.completed);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Enjoy your meal.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _rateExperience() {
    // In a real app, this would show a rating dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _orderAgain() {
    // Navigate back to start screen
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}

class _StatusInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _StatusInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
