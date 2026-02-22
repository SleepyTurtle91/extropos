# P2P Local Network System - Quick Reference

**Last Updated**: February 22, 2026

## Quick Start (30 seconds)

```dart
// 1. Initialize in main.dart startup
final p2p = LocalNetworkP2PService();
await p2p.initialize(
  deviceName: 'Main POS',
  deviceType: P2PDeviceType.mainPOS,
);
await p2p.start();

// 2. Get connected devices
final devices = p2p.connectedDevices;

// 3. Send order to tablet
final router = P2POrderRouterService();
await router.sendOrderToDevice(
  'order-123',
  deviceId,
  cartItems,
  subtotal: 100,
  total: 110,
);
```

## File Structure

```
lib/
  models/
    p2p_device_model.dart          # P2PDevice, P2PDeviceType, P2PConnectionStatus
    p2p_message_model.dart         # P2PMessage, P2PMessageType
    p2p_order_message_model.dart   # P2POrderMessage, P2POrderItem
  
  services/
    local_network_p2p_service.dart # Main P2P service
    p2p_order_router_service.dart  # Order routing service
  
  widgets/
    p2p_widgets.dart               # UI widgets for P2P management
  
  examples/
    p2p_integration_examples.dart  # Complete examples
  
  docs/
    P2P_LOCAL_NETWORK_SYSTEM.md    # Full documentation
```

## Core Classes

### P2PDevice
Represents a connected device.

| Property | Type | Description |
|----------|------|-------------|
| `deviceId` | String | Unique device identifier |
| `deviceName` | String | Display name |
| `deviceType` | P2PDeviceType | mainPOS, orderingTablet, secondaryPOS, etc. |
| `ipAddress` | String | IP address on network |
| `port` | int | Listening port (default 8766) |
| `connectionStatus` | P2PConnectionStatus | connected, disconnected, error |
| `isActive` | bool | Connected and responsive |

**Device Types**:
- `P2PDeviceType.mainPOS` - Primary terminal
- `P2PDeviceType.orderingTablet` - Mobile ordering device
- `P2PDeviceType.secondaryPOS` - Secondary terminal
- `P2PDeviceType.kds` - Kitchen display
- `P2PDeviceType.customerDisplay` - Customer display

### P2PMessage
Base message class.

| Property | Type | Description |
|----------|------|-------------|
| `messageId` | String | Unique message ID |
| `messageType` | P2PMessageType | Type of message |
| `fromDeviceId` | String | Source device |
| `toDeviceId` | String? | Target device (null = broadcast) |
| `timestamp` | DateTime | Message time |
| `payload` | Map | Message data |
| `priority` | int | 0-10 (higher = urgent) |

**Message Types**:
- `discovery` - Device announcement
- `orderForward` - Send order
- `orderStatus` - Status update
- `orderCancel` - Cancel order
- `heartbeat` - Keep-alive
- `acknowledgement` - Receipt confirmation
- `error` - Error message

### LocalNetworkP2PService
Main P2P service.

| Method | Returns | Description |
|--------|---------|-------------|
| `initialize(...)` | Future | Set up service |
| `start()` | Future | Start TCP/UDP servers |
| `stop()` | Future | Stop service |
| `discoverDevices()` | Future<List<P2PDevice>> | Find devices |
| `connectToDevice(device)` | Future<bool> | Connect to device |
| `sendMessage(message)` | Future | Send message |
| `onMessage(type, handler)` | void | Register message handler |

| Property | Type | Description |
|----------|------|-------------|
| `isInitialized` | bool | Service ready |
| `isRunning` | bool | Service active |
| `deviceId` | String | This device's ID |
| `connectedDevices` | List<P2PDevice> | All connected devices |
| `deviceStream` | Stream | Device connection events |
| `messageStream` | Stream | All incoming messages |

### P2POrderRouterService
Order routing service.

| Method | Returns | Description |
|--------|---------|-------------|
| `sendOrderToDevice(...)` | Future<bool> | Send to one device |
| `sendOrderToDeviceType(...)` | Future<int> | Send to device type |
| `broadcastOrderToAllClients(...)` | Future<int> | Broadcast to all |
| `broadcastOrderStatusUpdate(...)` | Future | Update status |
| `cancelOrderOnDevice(...)` | Future | Cancel order |
| `getSentOrder(orderId)` | P2POrderMessage? | Get sent order |

## Common Patterns

### Send Order to Tablet

```dart
final router = P2POrderRouterService();
await router.sendOrderToDevice(
  'order-123',
  'tablet-device-id',
  cartItems,
  subtotal: 100.0,
  tax: 10.0,
  total: 110.0,
);
```

### Broadcast to All Tablets

```dart
final count = await router.sendOrderToDeviceType(
  'order-123',
  cartItems,
  P2PDeviceType.orderingTablet,
  subtotal: 100.0,
  total: 110.0,
);
print('Sent to $count tablets');
```

### Update Order Status

```dart
await router.broadcastOrderStatusUpdate(
  'order-123',
  newStatus: OrderStatus.ready,
  reason: 'Ready for pickup',
);
```

### Listen for Orders (Tablet)

```dart
final p2p = LocalNetworkP2PService();
p2p.onMessage(P2PMessageType.orderForward, (message) {
  final order = P2POrderMessage.tryFromMessage(message);
  if (order != null) {
    // Handle incoming order
  }
});
```

### Discover Devices

```dart
final p2p = LocalNetworkP2PService();
final devices = await p2p.discoverDevices(
  timeout: Duration(seconds: 5),
);
for (final device in devices) {
  print('Found: ${device.displayTitle}');
}
```

## Configuration Constants

```dart
// LocalNetworkP2PService
static const int discoveryPort = 8765;        // UDP discovery
static const int dataPort = 8766;              // TCP data
static const Duration discoveryTimeout = 5s;   // Discovery wait
static const Duration heartbeatInterval = 15s; // Keep-alive
static const Duration deviceTimeout = 60s;     // Inactive timeout
```

## Error Handling

```dart
try {
  await router.sendOrderToDevice(orderId, deviceId, items);
} on SocketException catch (e) {
  print('Network error: $e');
} catch (e) {
  print('Unexpected error: $e');
}
```

## UI Integration

### Show Connected Devices

```dart
P2PConnectedDevicesPanel(
  devices: LocalNetworkP2PService().connectedDevices,
  onRefresh: () => LocalNetworkP2PService().discoverDevices(),
)
```

### Discover Dialog

```dart
showDialog(
  context: context,
  builder: (context) => P2PDeviceDiscoveryDialog(
    p2pService: LocalNetworkP2PService(),
    onDeviceSelected: (device) {
      // Handle selection
    },
  ),
)
```

### Connection Manager

```dart
showModalBottomSheet(
  context: context,
  builder: (context) => P2PConnectionManager(
    p2pService: LocalNetworkP2PService(),
  ),
)
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No devices found | Check same WiFi network, verify service is running |
| Connection drops | Increase heartbeat interval, check network stability |
| Messages not received | Verify handler is registered, check message type |
| Slow communication | Check network latency, reduce message size |
| Port already in use | Change customPort in initialize() |

## Performance Stats

- Message overhead: ~200 bytes per message
- Heartbeat interval: 15 seconds (default)
- Device timeout: 60 seconds (default)
- Max concurrent devices: OS dependent (100+)
- Network: Local WiFi/Ethernet only

## Network Requirements

- All devices on same local network
- Ports 8765-8766 open/unblocked
- WiFi or Ethernet connection
- No internet routing required

## Example Files

- **`p2p_integration_examples.dart`**: 10+ complete working examples
- **`P2P_LOCAL_NETWORK_SYSTEM.md`**: Full documentation
- **`p2p_widgets.dart`**: Ready-to-use UI components

## Integration Checklist

- [ ] Import services: `LocalNetworkP2PService`, `P2POrderRouterService`
- [ ] Call `initialize()` and `start()` in app startup
- [ ] Add device badges to main POS screen
- [ ] Setup order forwarding button
- [ ] Implement status update handlers
- [ ] Test all device types (tablet, secondary POS, etc.)
- [ ] Test on actual hardware
- [ ] Add error handling and logging
- [ ] Document for your team

## Key Files to Review

1. **`local_network_p2p_service.dart`** - Core service implementation
2. **`p2p_order_router_service.dart`** - Order specific operations
3. **`p2p_widgets.dart`** - UI components for management
4. **`p2p_integration_examples.dart`** - Practical examples
5. **`P2P_LOCAL_NETWORK_SYSTEM.md`** - Complete documentation

## Support Resources

- Full docs: `docs/P2P_LOCAL_NETWORK_SYSTEM.md`
- Examples: `lib/examples/p2p_integration_examples.dart`
- Widgets: `lib/widgets/p2p_widgets.dart`
- Models: `lib/models/p2p_*.dart`

---

**Ready to use!** Copy patterns from examples and integrate into your screens.
