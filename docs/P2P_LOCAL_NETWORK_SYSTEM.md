# P2P Local Network System for FlutterPOS

Date: February 22, 2026  
Version: 1.0  
Status: Ready for Integration

## Overview

The P2P Local Network system enables the Main POS terminal to communicate with client devices on the same local network (ordering tablets, secondary POS terminals, kitchen display systems, etc). This implementation provides:

- **Device Discovery**: Automatically discover compatible POS devices on the network using UDP broadcast
- **TCP/IP Communication**: Secure, reliable message delivery between devices
- **Order Routing**: Send orders to specific devices or broadcast to all
- **Status Synchronization**: Real-time order status updates across devices
- **Heartbeat Management**: Keep connections alive and detect inactive devices
- **No External Dependencies**: Uses only Dart's built-in `dart:io` networking

## Architecture

### Models

#### 1. **P2PDevice** (`lib/models/p2p_device_model.dart`)
Represents a connected POS device on the network.

```dart
P2PDevice(
  deviceId: 'unique-id',
  deviceName: 'Ordering Tablet 1',
  deviceType: P2PDeviceType.orderingTablet,
  ipAddress: '192.168.1.100',
  port: 8766,
  hostname: 'pos-tablet-1.local',
  connectionStatus: P2PConnectionStatus.connected,
)
```

**Device Types**:
- `mainPOS` - Primary POS terminal (this device)
- `orderingTablet` - Mobile device for taking orders
- `secondaryPOS` - Secondary POS terminal
- `kds` - Kitchen Display System
- `customerDisplay` - Customer-facing display

**Connection Status**:
- `disconnected` - Device is offline
- `discovering` - Looking for device
- `connecting` - Establishing connection
- `connected` - Active connection
- `error` - Connection error

#### 2. **P2PMessage** (`lib/models/p2p_message_model.dart`)
Base class for all P2P messages.

```dart
P2PMessage(
  messageId: 'unique-id',
  messageType: P2PMessageType.orderForward,
  fromDeviceId: 'main-pos-id',
  toDeviceId: 'tablet-id', // null = broadcast
  timestamp: DateTime.now(),
  payload: { /* message data */ },
  priority: 9, // 0-10
)
```

**Message Types**:
- `discovery` - Device announcement
- `orderForward` - Send order to device
- `orderStatus` - Order status update
- `orderCancel` - Cancel order
- `cartSync` - Sync cart state
- `heartbeat` - Keep-alive signal
- `acknowledgement` - Message receipt confirmation
- `error` - Error notification

#### 3. **P2POrderMessage** (`lib/models/p2p_order_message_model.dart`)
Specialized message for sending orders.

```dart
P2POrderMessage(
  messageId: const Uuid().v4(),
  fromDeviceId: mainPosId,
  orderId: 'order-123',
  items: [P2POrderItem(...)],
  subtotal: 100.0,
  tax: 10.0,
  total: 110.0,
  orderStatus: OrderStatus.pending,
  destination: OrderRoutingDestination.orderingTablet,
  destinationDeviceId: 'tablet-id',
  tableNumber: 5,
  customerName: 'John Doe',
  specialInstructions: 'Extra spicy',
)
```

### Services

#### 1. **LocalNetworkP2PService** (`lib/services/local_network_p2p_service.dart`)
Main service for managing P2P connections and communication.

**Initialization**:
```dart
final p2pService = LocalNetworkP2PService();

// Initialize (call once at app startup)
await p2pService.initialize(
  deviceName: 'Main POS Terminal',
  deviceType: P2PDeviceType.mainPOS,
  customPort: 8766, // optional
);

// Start service (call after initialize)
await p2pService.start();
```

**Device Discovery**:
```dart
// Discover devices on the network
final devices = await p2pService.discoverDevices(
  timeout: Duration(seconds: 5),
);

// Listen for device stream
p2pService.deviceStream.listen((device) {
  print('Device connected: ${device.displayTitle}');
});
```

**Sending Messages**:
```dart
// Send to specific device
final message = P2PMessage(
  messageId: const Uuid().v4(),
  messageType: P2PMessageType.orderForward,
  fromDeviceId: p2pService.deviceId,
  toDeviceId: 'tablet-id',
  timestamp: DateTime.now(),
  payload: { 'orderId': '123' },
);
await p2pService.sendMessage(message);

// Broadcast to all devices
final broadcastMessage = P2PMessage(
  messageId: const Uuid().v4(),
  messageType: P2PMessageType.broadcast,
  fromDeviceId: p2pService.deviceId,
  toDeviceId: null, // null = broadcast
  timestamp: DateTime.now(),
  payload: { 'newConfig': {...} },
);
await p2pService.sendMessage(broadcastMessage);
```

**Message Handlers**:
```dart
// Register handler for specific message type
p2pService.onMessage(P2PMessageType.orderStatus, (message) {
  print('Order status update: ${message.payload}');
});

// Listen to all messages
p2pService.messageStream.listen((message) {
  print('Received: ${message.messageType.value}');
});
```

**Connection Management**:
```dart
// Get connected devices
final devices = p2pService.connectedDevices;
print('Connected devices: ${devices.length}');

// Check service status
print('Running: ${p2pService.isRunning}');
print('Device ID: ${p2pService.deviceId}');
```

#### 2. **P2POrderRouterService** (`lib/services/p2p_order_router_service.dart`)
Specialized service for order routing and management.

**Sending Orders**:
```dart
final router = P2POrderRouterService();

// Send order to specific device (ordering tablet)
final success = await router.sendOrderToDevice(
  'order-123',
  'tablet-device-id',
  cartItems,
  subtotal: 100.0,
  tax: 10.0,
  total: 110.0,
  customerName: 'John Doe',
);

// Send to all tablets
final sentCount = await router.sendOrderToDeviceType(
  'order-124',
  cartItems,
  P2PDeviceType.orderingTablet,
  subtotal: 100.0,
  total: 110.0,
);

// Broadcast to all devices
final allSentCount = await router.broadcastOrderToAllClients(
  'order-125',
  cartItems,
  subtotal: 100.0,
  total: 110.0,
);
```

**Order Status Updates**:
```dart
// Update order status on all devices
await router.broadcastOrderStatusUpdate(
  'order-123',
  newStatus: OrderStatus.ready,
  reason: 'Order is ready for pickup',
  estimatedTime: 300, // 5 minutes
);

// Cancel order on device
await router.cancelOrderOnDevice(
  'order-123',
  'tablet-id',
  reason: 'Item out of stock',
  refund: true,
);
```

**Order Tracking**:
```dart
// Get previously sent order
final orderMsg = router.getSentOrder('order-123');

// Get all sent orders
final allOrders = router.getAllSentOrders();

// Callbacks for order events
router.onOrderSent((orderId, deviceId) {
  print('Order $orderId sent to $deviceId');
});
```

## Integration Steps

### Step 1: Initialize in Main.dart (App Startup)

```dart
// In _MyAppState.initState() after other initializations:
Future<void> _initializeP2P() async {
  try {
    final p2pService = LocalNetworkP2PService();

    // Initialize
    await p2pService.initialize(
      deviceName: BusinessInfo.instance.businessName ?? 'Main POS',
      deviceType: P2PDeviceType.mainPOS,
    );

    // Start service
    await p2pService.start();
    
    // Auto-discover devices
    await p2pService.discoverDevices();
    
    print('[App] P2P Service initialized and running');
  } catch (e) {
    print('[App] P2P initialization failed: $e');
  }
}
```

### Step 2: Add P2P Manager to Settings Screen

```dart
// In settings_screen.dart or menu
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: [
        // Existing settings...
        
        // Add P2P Manager
        ExpansionTile(
          title: const Text('Network & P2P Management'),
          leading: const Icon(Icons.router),
          children: [
            P2PConnectionManager(
              p2pService: LocalNetworkP2PService(),
            ),
          ],
        ),
      ],
    ),
  );
}
```

### Step 3: Add Device Badges to Main POS Screen

```dart
// In UnifiedPOSScreen, add device status indicators
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Main POS'),
      actions: [
        // P2P Device status
        StreamBuilder<P2PDevice>(
          stream: LocalNetworkP2PService().deviceStream,
          builder: (context, snapshot) {
            final devices = LocalNetworkP2PService().connectedDevices;
            final connected = devices
                .where((d) => d.isActive)
                .length;
            
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Tooltip(
                  message: '$connected devices connected',
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('$connected'),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Existing menu items...
      ],
    ),
    body: // ... existing body
  );
}
```

### Step 4: Integrate Order Forwarding

```dart
// When sending order to secondary device (tablet/secondary POS)
Future<void> _sendOrderToTablet() async {
  try {
    final router = P2POrderRouterService();
    
    // Get target tablet device
    final tablets = LocalNetworkP2PService()
        .connectedDevices
        .where((d) => d.deviceType == P2PDeviceType.orderingTablet)
        .toList();
    
    if (tablets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tablets connected')),
      );
      return;
    }

    // Send order to first available tablet
    final success = await router.sendOrderToDevice(
      _currentOrderId,
      tablets.first.deviceId,
      cartItems,
      subtotal: calculateSubtotal(),
      tax: calculateTax(),
      total: calculateTotal(),
      customerName: customerName,
      specialInstructions: specialInstructions,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order forwarded to ${tablets.first.deviceName}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('Error sending order: $e');
  }
}
```

### Step 5: Handle Incoming Messages (Server Devices)

For ordering tablets or secondary POS devices:

```dart
// In tablet app initialization
void _setupP2PListener() {
  final p2pService = LocalNetworkP2PService();
  
  // Listen for incoming orders from main POS
  p2pService.onMessage(P2PMessageType.orderForward, (message) {
    try {
      final orderMsg = P2POrderMessage.tryFromMessage(message);
      if (orderMsg != null) {
        _handleIncomingOrder(orderMsg);
      }
    } catch (e) {
      print('Error handling order: $e');
    }
  });
  
  // Listen for order status updates
  p2pService.onMessage(P2PMessageType.orderStatus, (message) {
    try {
      final statusMsg = P2POrderStatusMessage.fromMessage(message);
      _handleOrderStatusUpdate(statusMsg);
    } catch (e) {
      print('Error handling status update: $e');
    }
  });
}
```

## Usage Examples

### Example 1: Forward Order to Ordering Tablet

```dart
// Main POS screen - button to send order to tablet
ElevatedButton(
  onPressed: () async {
    final router = P2POrderRouterService();
    
    final targetTablet = LocalNetworkP2PService()
        .connectedDevices
        .firstWhere(
          (d) => d.deviceType == P2PDeviceType.orderingTablet,
          orElse: () => null as dynamic,
        );
    
    if (targetTablet == null) {
      showError('No ordering tablet connected');
      return;
    }
    
    await router.sendOrderToDevice(
      'order-${DateTime.now().millisecondsSinceEpoch}',
      targetTablet.deviceId,
      cartItems,
      subtotal: subtotal,
      tax: tax,
      total: total,
      tableNumber: selectedTableNumber,
      customerName: customerName,
    );
  },
  child: const Text('Send to Tablet'),
)
```

### Example 2: Sync Order Status Across Devices

```dart
// After order is ready in kitchen
void _markOrderAsReady(String orderId) {
  final router = P2POrderRouterService();
  
  // Update in main POS database
  _updateOrderInDatabase(orderId, OrderStatus.ready);
  
  // Broadcast status update to all connected devices
  router.broadcastOrderStatusUpdate(
    orderId,
    newStatus: OrderStatus.ready,
    reason: 'Order prepared',
    estimatedTime: 0,
  );
}
```

### Example 3: Discover and List All Devices

```dart
// Settings screen - show all discovered devices
Future<void> _discoverAndShowDevices() async {
  final p2pService = LocalNetworkP2PService();
  
  final devices = await p2pService.discoverDevices(
    timeout: const Duration(seconds: 5),
  );
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Available Devices'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return ListTile(
              leading: Icon(device.deviceType.icon),
              title: Text(device.deviceName),
              subtitle: Text(device.ipAddress),
              trailing: ElevatedButton(
                onPressed: () async {
                  await p2pService.connectToDevice(device);
                  Navigator.pop(context);
                },
                child: const Text('Connect'),
              ),
            );
          },
        ),
      ),
    ),
  );
}
```

## Deployment Checklist

- [ ] Add uuid package verification in pubspec.yaml
- [ ] Test P2P service initialization in main.dart
- [ ] Verify device discovery on same WiFi network
- [ ] Test order forwarding to tablet
- [ ] Test order status synchronization
- [ ] Verify heartbeat keeps connections alive
- [ ] Test device timeout/disconnection handling
- [ ] Add error logging and monitoring
- [ ] Test on actual hardware (Android tablets, Windows desktops)
- [ ] Verify on same network (WiFi or Ethernet)
- [ ] Test firewall compatibility (ports 8765-8766)

## Troubleshooting

### Devices Not Discovered

1. Verify all devices are on same network
2. Check that P2P service is running: `p2pService.isRunning`
3. Verify firewall allows ports 8765-8766
4. Check device IP addresses are reachable
5. Try manual connection with IP address and port

### Messages Not Received

1. Verify device is connected: `device.connectionStatus == connected`
2. Check message handlers are registered
3. Verify message type matches handler type
4. Check network connectivity

### Connection Drops

1. Heartbeat interval (default 15s) may need adjustment
2. Device timeout (default 60s) may need adjustment
3. Network instability - check WiFi signal
4. Firewall may be blocking connections

## Performance Notes

- Heartbeat interval: 15 seconds (configurable)
- Device timeout: 60 seconds (configurable)
- Message buffer: Unlimited (may need cleanup)
- Concurrent connections: Limited by OS (typically 100+)
- Network: Local WiFi/Ethernet only (not internet)

## Security Considerations

- **Local Network Only**: Only accessible on same network
- **No Encryption**: Add TLS for production if needed
- **No Authentication**: Consider adding device pairing
- **Message Signing**: Add HMAC for integrity verification
- **Port Binding**: Bind to local IP only in production

## Future Enhancements

1. **Device Pairing**: Add PIN-based device pairing
2. **TLS/SSL**: Encrypted connections option
3. **Database Persistence**: Persist connected devices
4. **Batch Messages**: Support message batching
5. **Compression**: Compress large payloads
6. **Sync Queue**: Offline message queue
7. **Topology**: Support mesh/relay topology
8. **Analytics**: Track P2P communication metrics

---

Last Updated: February 22, 2026
