/// Integration Examples for P2P Local Network System
/// 
/// This file demonstrates practical usage of the P2P system in the FlutterPOS application.
/// Copy these patterns into your screens and services.
library;

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_order_message_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:extropos/services/p2p_order_router_service.dart';
import 'package:extropos/widgets/p2p_widgets.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// ============================================================================
// EXAMPLE 1: App Startup - Initialize P2P Service in main.dart
// ============================================================================

/// Call this in your main app initialization (e.g., in _MyAppState.initState())
Future<void> initializeP2PService() async {
  try {
    final p2pService = LocalNetworkP2PService();

    // Step 1: Initialize with device info
    await p2pService.initialize(
      deviceName: 'Main POS Terminal',
      deviceType: P2PDeviceType.mainPOS,
      // customPort: 8766, // Optional: use custom port if needed
    );

    // Step 2: Start the service (TCP server + discovery listener)
    await p2pService.start();

    // Step 3: Auto-discover devices on network (optional)
    final discoveredDevices = await p2pService.discoverDevices(
      timeout: const Duration(seconds: 3),
    );
    print('[P2P] Auto-discovery found ${discoveredDevices.length} devices');

    // Step 4: Optionally setup message handlers
    p2pService.onMessage(P2PMessageType.orderStatus, (message) {
      print('[App] Order status update: ${message.payload}');
      // Handle order status updates here
    });

    print('[App] P2P Service initialized and running');
  } catch (e) {
    print('[App] P2P initialization error: $e');
    // Continue app anyway - P2P is optional
  }
}

// ============================================================================
// EXAMPLE 2: Send Order to Ordering Tablet
// ============================================================================

/// Widget demonstrating order forwarding to ordering tablet
class OrderForwardingExample extends StatefulWidget {
  final List<CartItem> cartItems;
  final void Function()? onOrderSent;

  const OrderForwardingExample({super.key, 
    required this.cartItems,
    this.onOrderSent,
  });

  @override
  State<OrderForwardingExample> createState() => _OrderForwardingExampleState();
}

class _OrderForwardingExampleState extends State<OrderForwardingExample> {
  final P2POrderRouterService _router = P2POrderRouterService();
  final LocalNetworkP2PService _p2p = LocalNetworkP2PService();

  bool _isLoading = false;
  String? _selectedTabletId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Device selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forward Order To:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select a device'),
                value: _selectedTabletId,
                onChanged: (newValue) {
                  setState(() => _selectedTabletId = newValue);
                },
                items: _p2p.connectedDevices
                    .where((d) =>
                        d.connectionStatus == P2PConnectionStatus.connected &&
                        (d.deviceType == P2PDeviceType.orderingTablet ||
                            d.deviceType == P2PDeviceType.secondaryPOS))
                    .map((device) => DropdownMenuItem<String>(
                          value: device.deviceId,
                          child: Row(
                            children: [
                              Icon(device.deviceType.icon,
                                  color: device.deviceType.statusColor),
                              const SizedBox(width: 8),
                              Text(device.displayTitle),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

        // Send button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed:
                _isLoading || _selectedTabletId == null ? null : _sendOrder,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isLoading ? 'Sending...' : 'Send Order'),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOrder() async {
    setState(() => _isLoading = true);

    try {
      final orderId = 'order-${const Uuid().v4()}';
      double subtotal = 0;
      for (var item in widget.cartItems) {
        subtotal += item.totalPrice;
      }
      final tax = subtotal * 0.10; // 10% tax
      final total = subtotal + tax;

      final success = await _router.sendOrderToDevice(
        orderId,
        _selectedTabletId!,
        widget.cartItems,
        subtotal: subtotal,
        tax: tax,
        total: total,
        customerName: 'Customer', // Use actual customer name
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Order forwarded successfully'
                  : 'Failed to forward order',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          widget.onOrderSent?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ============================================================================
// EXAMPLE 3: Broadcast Order to All Tablets
// ============================================================================

/// Send same order to all connected tablets
Future<int> broadcastOrderToAllTablets(List<CartItem> cartItems) async {
  try {
    final router = P2POrderRouterService();

    double subtotal = 0;
    for (var item in cartItems) {
      subtotal += item.totalPrice;
    }
    final tax = subtotal * 0.10;
    final total = subtotal + tax;

    final sentCount = await router.sendOrderToDeviceType(
      'order-${const Uuid().v4()}',
      cartItems,
      P2PDeviceType.orderingTablet,
      subtotal: subtotal,
      tax: tax,
      total: total,
    );

    print('[Example] Order broadcast to $sentCount tablets');
    return sentCount;
  } catch (e) {
    print('[Example] Broadcast failed: $e');
    return 0;
  }
}

// ============================================================================
// EXAMPLE 4: Update Order Status Across Devices
// ============================================================================

/// Update order status in main POS and sync to all connected devices
Future<void> updateOrderStatusAndSync(
  String orderId,
  OrderStatus newStatus,
) async {
  try {
    final router = P2POrderRouterService();

    // Step 1: Update in local database
    // await updateOrderInDatabase(orderId, newStatus);

    // Step 2: Broadcast status to all connected devices
    await router.broadcastOrderStatusUpdate(
      orderId,
      newStatus: newStatus,
      reason: 'Status updated at main POS',
      estimatedTime: newStatus == OrderStatus.ready ? 0 : 300,
    );

    print('[Example] Order status synced across all devices');
  } catch (e) {
    print('[Example] Status sync failed: $e');
  }
}

// ============================================================================
// EXAMPLE 5: Listen for Incoming Orders (Tablet App)
// ============================================================================

/// Setup P2P listener in ordering tablet app
void setupTabletP2PListener() {
  final p2pService = LocalNetworkP2PService();

  // Listen for orders from main POS
  p2pService.onMessage(P2PMessageType.orderForward, (message) {
    try {
      final orderMsg = P2POrderMessage.tryFromMessage(message);
      if (orderMsg != null) {
        _handleIncomingOrder(orderMsg);
      }
    } catch (e) {
      print('[Tablet P2P] Error handling order: $e');
    }
  });

  // Listen for status updates
  p2pService.onMessage(P2PMessageType.orderStatus, (message) {
    try {
      final statusMsg = P2POrderStatusMessage.fromMessage(message);
      _handleOrderStatusUpdate(statusMsg.orderId, statusMsg.newStatus);
      print('[Tablet P2P] Order ${statusMsg.orderId} -> ${statusMsg.newStatus.displayName}');
    } catch (e) {
      print('[Tablet P2P] Error handling status: $e');
    }
  });

  // Listen for cancellations
  p2pService.onMessage(P2PMessageType.orderCancel, (message) {
    try {
      final cancelMsg = P2POrderCancelMessage.fromMessage(message);
      _handleOrderCancellation(cancelMsg.orderId, cancelMsg.reason);
      print('[Tablet P2P] Order ${cancelMsg.orderId} cancelled: ${cancelMsg.reason}');
    } catch (e) {
      print('[Tablet P2P] Error handling cancellation: $e');
    }
  });
}

// Placeholder functions for tablet
void _handleIncomingOrder(P2POrderMessage order) {
  print('[Tablet] Received order: ${order.orderId}');
  // Update UI, add to orders list, etc.
}

void _handleOrderStatusUpdate(String orderId, OrderStatus status) {
  print('[Tablet] Order $orderId updated to $status');
  // Update UI
}

void _handleOrderCancellation(String orderId, String reason) {
  print('[Tablet] Order $orderId cancelled: $reason');
  // Update UI, remove from list, etc.
}

// ============================================================================
// EXAMPLE 6: Device Manager Screen
// ============================================================================

/// Full-featured device management screen for settings
Future<void> showP2PDeviceManager(BuildContext context) async {
  final p2pService = LocalNetworkP2PService();

  if (!p2pService.isInitialized) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('P2P Service not initialized')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: P2PConnectionManager(p2pService: p2pService),
    ),
  );
}

// ============================================================================
// EXAMPLE 7: Monitor Device Connections
// ============================================================================

/// Widget to show real-time device connection status
class DeviceStatusMonitor extends StatefulWidget {
  const DeviceStatusMonitor({super.key});

  @override
  State<DeviceStatusMonitor> createState() => _DeviceStatusMonitorState();
}

class _DeviceStatusMonitorState extends State<DeviceStatusMonitor> {
  final LocalNetworkP2PService _p2p = LocalNetworkP2PService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<P2PDevice>(
      stream: _p2p.deviceStream,
      builder: (context, snapshot) {
        final connectedCount = _p2p.connectedDevices
            .where((d) => d.isActive)
            .length;
        final totalCount = _p2p.connectedDevices.length;

        return Material(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    const Icon(Icons.cloud, size: 40, color: Colors.blue),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: connectedCount > 0 ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$connectedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'P2P Network',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '$connectedCount / $totalCount devices',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// EXAMPLE 8: Handle Network Errors Gracefully
// ============================================================================

/// Graceful error handling for P2P operations
Future<bool> sendOrderWithFallback(
  List<CartItem> cartItems,
  String? targetDeviceId,
) async {
  try {
    final router = P2POrderRouterService();

    if (targetDeviceId != null) {
      // Try sending to specific device
      return await router.sendOrderToDevice(
        'order-${const Uuid().v4()}',
        targetDeviceId,
        cartItems,
        subtotal: _calculateSubtotal(cartItems),
        total: _calculateTotal(cartItems),
      );
    } else {
      // Fallback: broadcast to all devices
      final count = await router.broadcastOrderToAllClients(
        'order-${const Uuid().v4()}',
        cartItems,
        subtotal: _calculateSubtotal(cartItems),
        total: _calculateTotal(cartItems),
      );
      return count > 0;
    }
  } on SocketException catch (e) {
    print('[Example] Network error: $e');
    // Show user-friendly error
    return false;
  } catch (e) {
    print('[Example] Unexpected error: $e');
    return false;
  }
}

double _calculateSubtotal(List<CartItem> items) {
  return items.fold(0, (sum, item) => sum + item.totalPrice);
}

double _calculateTotal(List<CartItem> items) {
  return _calculateSubtotal(items) * 1.1; // +10% tax
}

// ============================================================================
// EXAMPLE 9: Restaurant Mode - Table-Based Order Forwarding
// ============================================================================

/// Send order for specific table to available devices
Future<void> forwardTableOrderToDevices(
  String orderId,
  int tableNumber,
  List<CartItem> cartItems,
  String customerName,
) async {
  try {
    final router = P2POrderRouterService();
    final p2p = LocalNetworkP2PService();

    // Get available ordering tablets
    final tablets = p2p.connectedDevices
        .where((d) =>
            d.deviceType == P2PDeviceType.orderingTablet &&
            d.isActive)
        .toList();

    if (tablets.isEmpty) {
      print('[Example] No ordering tablets available');
      return;
    }

    // Send to all tablets so staff can see assignment options
    for (final tablet in tablets) {
      await router.sendOrderToDevice(
        orderId,
        tablet.deviceId,
        cartItems,
        subtotal: _calculateSubtotal(cartItems),
        total: _calculateTotal(cartItems),
        tableNumber: tableNumber,
        customerName: customerName,
        specialInstructions: 'For table $tableNumber',
      );
    }

    print('[Example] Order sent to ${tablets.length} tablets');
  } catch (e) {
    print('[Example] Error: $e');
  }
}

// ============================================================================
// EXAMPLE 10: Auto-Reconnection Handler
// ============================================================================

/// Listen for disconnections and attempt reconnection
void setupAutoReconnection() {
  final p2p = LocalNetworkP2PService();

  p2p.deviceStream.listen((device) {
    if (device.connectionStatus == P2PConnectionStatus.disconnected) {
      print('[Auto-Reconnect] Device disconnected: ${device.deviceName}');

      // Attempt reconnection after delay
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          final success = await p2p.connectToDevice(device);
          if (success) {
            print('[Auto-Reconnect] Reconnected to ${device.deviceName}');
          }
        } catch (e) {
          print('[Auto-Reconnect] Reconnection failed: $e');
        }
      });
    }
  });
}

// ============================================================================
// Imports needed for these examples
// ============================================================================
/*
import 'dart:io' show SocketException;
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/order_status.dart';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_message_model.dart';
import 'package:extropos/models/p2p_order_message_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:extropos/services/p2p_order_router_service.dart';
import 'package:extropos/widgets/p2p_widgets.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
*/
