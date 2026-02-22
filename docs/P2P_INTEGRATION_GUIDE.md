# P2P Integration Guide for FlutterPOS

Date: February 22, 2026  
Version: 1.0  
Target: Main POS ↔ Client Devices (Ordering Tablet, Secondary POS)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Main POS Terminal                        │
│  (Windows Desktop - Primary Device)                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ UnifiedPOSScreen                                     │  │
│  │ - Retail/Cafe/Restaurant modes                      │  │
│  │ - Shows device status badges                        │  │
│  │ - "Send to Tablet" button                           │  │
│  │ - Order tracking                                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                   │
│  LocalNetworkP2PService (TCP 8766 / UDP 8765)               │
│  - Discovers devices                                        │
│  - Maintains connections                                    │
│  - Routes messages                                          │
└─────────────────────────────────────────────────────────────┘
         ↑                                           ↑
    orders/status                              discovery
         ↓                                           ↓
    [WiFi Network - Local Only]
         ↓                                           ↓
         ↑                                           ↑
    ┌────────────────────┐               ┌────────────────────┐
    │ Ordering Tablet    │               │ Secondary POS      │
    │ (Android)          │               │ (Windows/Android)  │
    │                    │               │                    │
    │ P2POrderMessage    │               │ P2POrderMessage    │
    │ listeners →        │               │ listeners →        │
    │ Process & display  │               │ Process & handle   │
    └────────────────────┘               └────────────────────┘
```

## Integration Steps

### Step 1: Add P2P Initialization to main.dart

```dart
// In lib/main.dart

import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:extropos/services/p2p_order_router_service.dart';

// In MyApp or MyAppState.initState():
Future<void> _initializeServices() async {
  // ... existing initializations ...

  // Initialize P2P for local network communication
  await _initializeP2PService();
}

Future<void> _initializeP2PService() async {
  try {
    final p2pService = LocalNetworkP2PService();

    // Initialize with device info from BusinessInfo
    final businessName = BusinessInfo.instance.businessName ?? 'Main POS';
    
    await p2pService.initialize(
      deviceName: businessName,
      deviceType: P2PDeviceType.mainPOS,
    );

    // Start service
    await p2pService.start();
    
    // Auto-discover devices (optional)
    p2pService.discoverDevices().then((devices) {
      print('[App] Auto-discovery: Found ${devices.length} devices');
    });

    print('[App] P2P Service initialized and running');
  } catch (e) {
    print('[App] P2P initialization failed: $e');
    // Continue - P2P is optional
  }
}
```

### Step 2: Add Device Status to Main POS AppBar

```dart
// In lib/screens/unified_pos_screen.dart

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Main POS'),
      actions: [
        // P2P Device Status Badge
        Padding(
          padding: const EdgeInsets.all(8),
          child: StreamBuilder<P2PDevice>(
            stream: LocalNetworkP2PService().deviceStream,
            builder: (context, snapshot) {
              final devices = LocalNetworkP2PService().connectedDevices;
              final active = devices
                  .where((d) => d.isActive)
                  .length;

              return Tooltip(
                message: 'Connected devices: $active',
                child: Center(
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: active > 0 ? Colors.green : Colors.grey,
                      child: const Icon(Icons.devices, color: Colors.white),
                    ),
                    label: Text('$active'),
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              );
            },
          ),
        ),
        
        // ... existing menu buttons ...
      ],
    ),
    body: // ... existing body ...
  );
}
```

### Step 3: Add Order Forwarding to Cart/Checkout

```dart
// Add button in checkout section to send order to tablets/secondary POS

Column(
  children: [
    // Existing cart display...
    
    // Forward order section
    if (LocalNetworkP2PService().connectedDevices.isNotEmpty)
      Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forward Order To Device',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Device selector
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select device'),
                value: _selectedDeviceId,
                onChanged: (value) {
                  setState(() => _selectedDeviceId = value);
                },
                items: LocalNetworkP2PService()
                    .connectedDevices
                    .where((d) => d.isActive)
                    .map((device) => DropdownMenuItem(
                      value: device.deviceId,
                      child: Row(
                        children: [
                          Icon(device.deviceType.icon),
                          const SizedBox(width: 8),
                          Text(device.displayTitle),
                        ],
                      ),
                    ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              
              // Send button
              ElevatedButton.icon(
                onPressed: _selectedDeviceId != null
                    ? _sendOrderToDevice
                    : null,
                icon: const Icon(Icons.send),
                label: const Text('Send Order'),
              ),
            ],
          ),
        ),
      ),
    
    // Checkout buttons...
  ],
)
```

### Step 4: Implement Order Sending Logic

```dart
// In UnifiedPOSScreen state

Future<void> _sendOrderToDevice() async {
  try {
    final router = P2POrderRouterService();
    final deviceId = _selectedDeviceId;

    if (deviceId == null) {
      _showError('No device selected');
      return;
    }

    // Calculate totals
    double subtotal = 0;
    for (var item in cart) {
      subtotal += item.totalPrice;
    }

    final taxAmount = BusinessInfo.instance.isTaxEnabled
        ? subtotal * BusinessInfo.instance.taxRate
        : 0.0;

    final serviceChargeAmount = 
        BusinessInfo.instance.isServiceChargeEnabled
            ? subtotal * BusinessInfo.instance.serviceChargeRate
            : 0.0;

    final total = subtotal + taxAmount + serviceChargeAmount;

    // Send order
    final success = await router.sendOrderToDevice(
      'order-${DateTime.now().millisecondsSinceEpoch}',
      deviceId,
      cart,
      subtotal: subtotal,
      tax: taxAmount > 0 ? taxAmount : null,
      serviceCharge: serviceChargeAmount > 0 ? serviceChargeAmount : null,
      total: total,
      customerName: customerName,
      specialInstructions: specialInstructions,
    );

    if (success) {
      _showSuccess('Order sent to device');
      // Optionally save to database
      // Clear selection
      setState(() => _selectedDeviceId = null);
    } else {
      _showError('Failed to send order');
    }
  } catch (e) {
    _showError('Error: $e');
  }
}

void _showSuccess(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

### Step 5: Add Settings Panel for Device Management

```dart
// In lib/screens/settings_screen.dart

@override
Widget build(BuildContext context) {
  return ListView(
    children: [
      // Existing settings...

      // P2P Network Management
      ExpansionTile(
        leading: const Icon(Icons.cloud),
        title: const Text('Network & P2P'),
        subtitle: const Text('Manage connected devices'),
        children: [
          P2PConnectionManager(
            p2pService: LocalNetworkP2PService(),
          ),
        ],
      ),
    ],
  );
}
```

### Step 6: Listen for Order Status Updates

```dart
// Set up listeners in UnifiedPOSScreen.initState()

@override
void initState() {
  super.initState();
  _setupP2PListeners();
}

void _setupP2PListeners() {
  final p2p = LocalNetworkP2PService();

  // Listen for order status updates from devices
  p2p.onMessage(P2PMessageType.orderStatus, (message) {
    try {
      final statusMsg = P2POrderStatusMessage.fromMessage(message);
      _handleOrderStatusUpdate(statusMsg);
    } catch (e) {
      print('[POS] Error handling status update: $e');
    }
  });

  // Listen for order cancellations
  p2p.onMessage(P2PMessageType.orderCancel, (message) {
    try {
      final cancelMsg = P2POrderCancelMessage.fromMessage(message);
      _showWarning(
        'Order ${cancelMsg.orderId} cancelled: ${cancelMsg.reason}',
      );
    } catch (e) {
      print('[POS] Error handling cancellation: $e');
    }
  });
}

void _handleOrderStatusUpdate(P2POrderStatusMessage statusMsg) {
  print('[POS] Order ${statusMsg.orderId} -> ${statusMsg.newStatus.displayName}');
  // Update UI or database with new status
  // Can integrate with existing order tracking
}
```

### Step 7: For Client Devices (Tablets/Secondary POS)

```dart
// In ordering tablet app

class OrderingTabletApp extends StatefulWidget {
  @override
  State<OrderingTabletApp> createState() => _OrderingTabletAppState();
}

class _OrderingTabletAppState extends State<OrderingTabletApp> {
  final LocalNetworkP2PService _p2p = LocalNetworkP2PService();
  final List<P2POrderMessage> _receivedOrders = [];

  @override
  void initState() {
    super.initState();
    _initializeTabletP2P();
  }

  Future<void> _initializeTabletP2P() async {
    try {
      // Initialize as ordering tablet
      await _p2p.initialize(
        deviceName: 'Ordering Tablet',
        deviceType: P2PDeviceType.orderingTablet,
      );

      // Start service
      await _p2p.start();

      // Auto-discover main POS
      _p2p.discoverDevices();

      // Setup listeners for incoming orders
      _setupOrderListeners();
    } catch (e) {
      print('[Tablet] Init error: $e');
    }
  }

  void _setupOrderListeners() {
    // Listen for orders from main POS
    _p2p.onMessage(P2PMessageType.orderForward, (message) {
      try {
        final order = P2POrderMessage.tryFromMessage(message);
        if (order != null) {
          setState(() => _receivedOrders.add(order));
          _showOrderNotification(order);
        }
      } catch (e) {
        print('[Tablet] Order error: $e');
      }
    });

    // Listen for status updates
    _p2p.onMessage(P2PMessageType.orderStatus, (message) {
      try {
        final statusMsg = P2POrderStatusMessage.fromMessage(message);
        _updateOrderStatus(statusMsg.orderId, statusMsg.newStatus);
      } catch (e) {
        print('[Tablet] Status error: $e');
      }
    });
  }

  void _updateOrderStatus(String orderId, OrderStatus status) {
    final index = _receivedOrders.indexWhere(
      (o) => o.orderId == orderId,
    );
    if (index >= 0) {
      // Update order status in UI
      print('[Tablet] Order $orderId status: ${status.displayName}');
    }
  }

  void _showOrderNotification(P2POrderMessage order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New order: ${order.orderId}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordering Tablet'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                '${_p2p.connectedDevices.whereType<P2PDevice>().where((d) => d.isActive).length} connected',
              ),
            ),
          ),
        ],
      ),
      body: // Display received orders
    );
  }
}
```

## Business Mode Integration

### Retail Mode
- Forward single orders to secondary POS
- No table management needed

### Cafe Mode
- Forward order with calling number
- Send to tablets for fulfillment tracking
- Update status when ready

### Restaurant Mode
- Forward table orders to tablets/KDS
- Include table number and customer name
- Multiple orders per table

## Security Considerations for Production

1. **Local Network Only**: P2P works only on same WiFi/Ethernet
2. **Add Device Pairing**: Implement PIN-based pairing
3. **Message Signing**: Add HMAC for integrity
4. **Encryption**: Use TLS for sensitive data
5. **Access Control**: Validate device type before accepting orders

## Testing Checklist

- [ ] P2P service initializes without errors
- [ ] Devices discovered on same network
- [ ] Orders sent and received correctly
- [ ] Status updates propagate to all devices
- [ ] Disconnections handled gracefully
- [ ] Heartbeat keeps connections alive
- [ ] UI updates reflect device status
- [ ] Works on Android tablets
- [ ] Works on Windows desktops
- [ ] No memory leaks with repeated connections

## Monitoring & Debugging

```dart
// Enable detailed logging
void setupP2PDebugging() {
  final p2p = LocalNetworkP2PService();

  // Monitor all messages
  p2p.messageStream.listen((message) {
    print('[P2P] ${message.messageType.value} from ${message.fromDeviceId}');
  });

  // Monitor device connections
  p2p.deviceStream.listen((device) {
    print('[P2P] Device: ${device.displayTitle} -> ${device.connectionStatus.displayName}');
  });
}
```

## File Checklist

- [x] `lib/models/p2p_device_model.dart` - Device definitions
- [x] `lib/models/p2p_message_model.dart` - Message definitions
- [x] `lib/models/p2p_order_message_model.dart` - Order messages
- [x] `lib/services/local_network_p2p_service.dart` - Core service
- [x] `lib/services/p2p_order_router_service.dart` - Order routing
- [x] `lib/widgets/p2p_widgets.dart` - UI components
- [x] `lib/examples/p2p_integration_examples.dart` - 10+ examples
- [x] `docs/P2P_LOCAL_NETWORK_SYSTEM.md` - Full documentation
- [x] `docs/P2P_QUICK_REFERENCE.md` - Quick reference
- [x] `docs/P2P_INTEGRATION_GUIDE.md` - This file

## Next Steps

1. **Copy the P2P files** to your lib/ directory
2. **Review examples** in `p2p_integration_examples.dart`
3. **Integrate into main.dart** using Step 1 above
4. **Test with multiple devices** on same network
5. **Add to settings screen** for management
6. **Deploy to ordering tablets**
7. **Monitor logs** for stability

## Support & Troubleshooting

See `P2P_LOCAL_NETWORK_SYSTEM.md` for:
- Detailed architecture
- API reference
- Troubleshooting guide
- Performance tuning
- Security best practices

---

**Status**: Ready for production integration  
**Last Updated**: February 22, 2026
