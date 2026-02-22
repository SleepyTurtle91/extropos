/// P2P Service Testing Utilities
/// 
/// This file provides mock implementations and test helpers for P2P functionality
/// Use these for unit testing and integration testing

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_message_model.dart';
import 'package:extropos/models/p2p_order_message_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:extropos/services/p2p_order_router_service.dart';
import 'package:uuid/uuid.dart';

/// Mock P2P Service for testing
class MockLocalNetworkP2PService implements LocalNetworkP2PService {
  final List<P2PDevice> _mockDevices = [];
  final List<P2PMessage> _sentMessages = [];
  bool _isRunning = false;

  @override
  bool get isInitialized => true;

  @override
  bool get isRunning => _isRunning;

  @override
  String get deviceId => 'mock-main-pos';

  @override
  String get deviceName => 'Mock Main POS';

  @override
  P2PDeviceType get deviceType => P2PDeviceType.mainPOS;

  @override
  List<P2PDevice> get connectedDevices => List.from(_mockDevices);

  @override
  Stream<P2PDevice> get deviceStream {
    throw UnimplementedError();
  }

  @override
  Stream<P2PMessage> get messageStream {
    throw UnimplementedError();
  }

  @override
  Future<void> initialize({
    required String deviceName,
    required P2PDeviceType deviceType,
    int? customPort,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> start() async {
    _isRunning = true;
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    _mockDevices.clear();
  }

  @override
  Future<List<P2PDevice>> discoverDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // Return mock devices
    return List.from(_mockDevices);
  }

  @override
  Future<bool> connectToDevice(P2PDevice device) async {
    final updated = device.copyWith(
      connectionStatus: P2PConnectionStatus.connected,
      lastSeen: DateTime.now(),
    );
    _mockDevices.removeWhere((d) => d.deviceId == device.deviceId);
    _mockDevices.add(updated);
    return true;
  }

  @override
  Future<void> sendMessage(P2PMessage message) async {
    _sentMessages.add(message);
  }

  @override
  void onMessage(P2PMessageType messageType, Function(P2PMessage) callback) {
    // Mock implementation
  }

  @override
  Future<void> dispose() async {
    await stop();
  }

  // Mock-specific methods for testing
  void addMockDevice(P2PDevice device) {
    _mockDevices.add(device);
  }

  List<P2PMessage> getSentMessages() => List.from(_sentMessages);

  void clearSentMessages() => _sentMessages.clear();
}

/// Helper class to create test devices
class P2PTestDeviceFactory {
  static P2PDevice createOrderingTablet({
    String? deviceId,
    String? deviceName,
    String? ipAddress,
    P2PConnectionStatus status = P2PConnectionStatus.connected,
  }) {
    return P2PDevice(
      deviceId: deviceId ?? const Uuid().v4(),
      deviceName: deviceName ?? 'Test Tablet',
      deviceType: P2PDeviceType.orderingTablet,
      ipAddress: ipAddress ?? '192.168.1.100',
      port: 8766,
      hostname: 'test-tablet.local',
      connectionStatus: status,
      lastSeen: DateTime.now(),
    );
  }

  static P2PDevice createSecondaryPOS({
    String? deviceId,
    String? deviceName,
    P2PConnectionStatus status = P2PConnectionStatus.connected,
  }) {
    return P2PDevice(
      deviceId: deviceId ?? const Uuid().v4(),
      deviceName: deviceName ?? 'Test Secondary POS',
      deviceType: P2PDeviceType.secondaryPOS,
      ipAddress: '192.168.1.101',
      port: 8766,
      hostname: 'test-secondary.local',
      connectionStatus: status,
      lastSeen: DateTime.now(),
    );
  }

  static P2PDevice createKDS({
    String? deviceId,
    String? deviceName,
    P2PConnectionStatus status = P2PConnectionStatus.connected,
  }) {
    return P2PDevice(
      deviceId: deviceId ?? const Uuid().v4(),
      deviceName: deviceName ?? 'Kitchen Display',
      deviceType: P2PDeviceType.kds,
      ipAddress: '192.168.1.102',
      port: 8766,
      hostname: 'test-kds.local',
      connectionStatus: status,
      lastSeen: DateTime.now(),
    );
  }
}

/// Helper class to create test messages
class P2PTestMessageFactory {
  static P2POrderMessage createTestOrder({
    String? orderId,
    String? deviceId,
    List<String>? itemNames,
    double subtotal = 100.0,
    double tax = 10.0,
    double total = 110.0,
    int? tableNumber,
    String? customerName,
  }) {
    // Create mock items
    final items = (itemNames ?? ['Item 1', 'Item 2'])
        .map((name) => P2POrderItem(
              productId: const Uuid().v4(),
              productName: name,
              price: 50.0,
              quantity: 1,
            ))
        .toList();

    return P2POrderMessage(
      messageId: const Uuid().v4(),
      fromDeviceId: 'test-main-pos',
      orderId: orderId ?? 'order-${const Uuid().v4()}',
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      orderStatus: OrderStatus.pending,
      destination: OrderRoutingDestination.orderingTablet,
      destinationDeviceId: deviceId,
      tableNumber: tableNumber,
      customerName: customerName,
    );
  }

  static P2POrderStatusMessage createTestStatusUpdate({
    String? orderId,
    required OrderStatus status,
    String? reason,
  }) {
    return P2POrderStatusMessage(
      messageId: const Uuid().v4(),
      fromDeviceId: 'test-main-pos',
      orderId: orderId ?? 'order-123',
      newStatus: status,
      statusReason: reason,
    );
  }

  static P2POrderCancelMessage createTestCancellation({
    String? orderId,
    String reason = 'Test cancellation',
  }) {
    return P2POrderCancelMessage(
      messageId: const Uuid().v4(),
      fromDeviceId: 'test-main-pos',
      orderId: orderId ?? 'order-123',
      reason: reason,
    );
  }
}

/// Test scenario helper
class P2PTestScenario {
  final List<P2PDevice> connectedDevices = [];
  final List<P2PMessage> messageLog = [];
  final MockLocalNetworkP2PService mockService = MockLocalNetworkP2PService();

  /// Setup scenario with tablet and secondary POS
  void setupStandardDevices() {
    final tablet = P2PTestDeviceFactory.createOrderingTablet();
    final secondaryPos = P2PTestDeviceFactory.createSecondaryPOS();

    mockService.addMockDevice(tablet);
    mockService.addMockDevice(secondaryPos);

    connectedDevices.addAll([tablet, secondaryPos]);
  }

  /// Setup scenario with all device types
  void setupAllDeviceTypes() {
    setupStandardDevices();
    final kds = P2PTestDeviceFactory.createKDS();
    mockService.addMockDevice(kds);
    connectedDevices.add(kds);
  }

  /// Simulate order sent
  void simulateOrderSent(P2POrderMessage order) {
    messageLog.add(order);
  }

  /// Simulate status update received
  void simulateStatusUpdateReceived(P2POrderStatusMessage update) {
    messageLog.add(update);
  }

  /// Simulate device disconnected
  void simulateDeviceDisconnected(String deviceId) {
    final device = connectedDevices.firstWhere(
      (d) => d.deviceId == deviceId,
      orElse: () => null as dynamic,
    );

    if (device != null) {
      connectedDevices.removeWhere((d) => d.deviceId == deviceId);
      final disconnected = device.copyWith(
        connectionStatus: P2PConnectionStatus.disconnected,
      );
      messageLog.add(P2PMessage(
        messageId: const Uuid().v4(),
        messageType: P2PMessageType.error,
        fromDeviceId: deviceId,
        timestamp: DateTime.now(),
        payload: {'event': 'disconnected'},
      ));
    }
  }

  /// Get all sent orders from log
  List<P2POrderMessage> getSentOrders() {
    return messageLog
        .whereType<P2POrderMessage>()
        .toList();
  }

  /// Get all status updates from log
  List<P2POrderStatusMessage> getStatusUpdates() {
    return messageLog
        .whereType<P2POrderStatusMessage>()
        .toList();
  }

  /// Clear the scenario
  void clear() {
    connectedDevices.clear();
    messageLog.clear();
    mockService.clearSentMessages();
  }
}

/// Test utilities for P2P integration
class P2PTestUtils {
  /// Create test cart items
  static List<CartItem> createMockCartItems({int count = 2}) {
    final items = <CartItem>[];
    for (int i = 0; i < count; i++) {
      items.add(
        CartItem(
          MockProduct(
            id: 'product-$i',
            name: 'Test Product $i',
            price: 50.0,
          ),
          1,
        ),
      );
    }
    return items;
  }

  /// Assert device is connected
  static void assertDeviceConnected(P2PDevice device) {
    assert(
      device.connectionStatus == P2PConnectionStatus.connected,
      'Device ${device.deviceName} is not connected',
    );
  }

  /// Assert device is active
  static void assertDeviceActive(P2PDevice device) {
    assert(
      device.isActive,
      'Device ${device.deviceName} is not active',
    );
  }

  /// Assert message type
  static void assertMessageType(
    P2PMessage message,
    P2PMessageType expectedType,
  ) {
    assert(
      message.messageType == expectedType,
      'Expected ${expectedType.value} but got ${message.messageType.value}',
    );
  }

  /// Assert message has payload
  static void assertMessagePayload(
    P2PMessage message,
    Map<String, dynamic> expectedPayload,
  ) {
    for (final key in expectedPayload.keys) {
      assert(
        message.payload.containsKey(key),
        'Payload missing key: $key',
      );
      assert(
        message.payload[key] == expectedPayload[key],
        'Payload[$key] mismatch: expected ${expectedPayload[key]}, got ${message.payload[key]}',
      );
    }
  }

  /// Assert order data integrity
  static void assertOrderIntegrity(P2POrderMessage order) {
    assert(
      order.items.isNotEmpty,
      'Order has no items',
    );
    assert(
      order.subtotal > 0,
      'Order subtotal must be positive',
    );
    assert(
      order.total >= order.subtotal,
      'Order total must be >= subtotal',
    );
  }
}

/// Mock Product for testing cart items
class MockProduct {
  final String id;
  final String name;
  final double price;

  MockProduct({
    required this.id,
    required this.name,
    required this.price,
  });
}

// Import required for tests
/*
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/order_status.dart';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_message_model.dart';
import 'package:extropos/models/p2p_order_message_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:extropos/services/p2p_order_router_service.dart';
import 'package:uuid/uuid.dart';
*/

/// Example test using these utilities
/*
void main() {
  group('P2P Order Router', () {
    late P2PTestScenario scenario;

    setUp(() {
      scenario = P2PTestScenario();
      scenario.setupStandardDevices();
    });

    test('Should create order message with correct data', () {
      final order = P2PTestMessageFactory.createTestOrder(
        itemNames: ['Burger', 'Fries'],
        subtotal: 150.0,
        total: 165.0,
      );

      P2PTestUtils.assertOrderIntegrity(order);
      expect(order.items.length, 2);
      expect(order.subtotal, 150.0);
      expect(order.total, 165.0);
    });

    test('Should handle status update correctly', () {
      final update = P2PTestMessageFactory.createTestStatusUpdate(
        status: OrderStatus.ready,
        reason: 'Order prepared',
      );

      P2PTestUtils.assertMessageType(update, P2PMessageType.orderStatus);
      expect(update.newStatus, OrderStatus.ready);
      expect(update.statusReason, 'Order prepared');
    });

    test('Should track connected devices', () {
      expect(scenario.connectedDevices.length, 2);
      
      for (final device in scenario.connectedDevices) {
        P2PTestUtils.assertDeviceConnected(device);
      }
    });

    tearDown(() {
      scenario.clear();
    });
  });
}
*/
