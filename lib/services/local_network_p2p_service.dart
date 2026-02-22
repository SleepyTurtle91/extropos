import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_message_model.dart';
import 'package:extropos/models/p2p_order_message_model.dart';
import 'package:universal_io/io.dart' show Platform;
import 'package:uuid/uuid.dart';

/// Callback for handling incoming messages
typedef P2PMessageCallback = void Function(P2PMessage message);

/// Callback for device connection status changes
typedef P2PDeviceStatusCallback = void Function(P2PDevice device, bool connected);

/// Main service for local network P2P communication between POS devices
class LocalNetworkP2PService {
  static final LocalNetworkP2PService _instance = LocalNetworkP2PService._internal();

  factory LocalNetworkP2PService() {
    return _instance;
  }

  LocalNetworkP2PService._internal();

  // Constants
  static const int discoveryPort = 8765;
  static const int dataPort = 8766;
  static const String discoveryBroadcastAddress = '255.255.255.255';
  static const Duration discoveryTimeout = Duration(seconds: 5);
  static const Duration heartbeatInterval = Duration(seconds: 15);
  static const Duration deviceTimeout = Duration(seconds: 60);

  // State
  late String _deviceId;
  late String _deviceName;
  late P2PDeviceType _deviceType;
  late int _listeningPort;

  bool _isInitialized = false;
  bool _isRunning = false;

  // Connected devices
  final Map<String, P2PDevice> _connectedDevices = {};
  final Map<String, StreamSubscription> _deviceListeners = {};

  // Message handlers
  final Map<P2PMessageType, List<P2PMessageCallback>> _messageHandlers = {};
  final Map<String, Completer<P2PMessage>> _pendingAcknowledgements = {};

  // Network resources
  ServerSocket? _tcpServer;
  RawDatagramSocket? _discoverySocket;
  Timer? _heartbeatTimer;
  Timer? _deviceTimeoutTimer;

  // Streams
  final StreamController<P2PDevice> _deviceStreamController =
      StreamController<P2PDevice>.broadcast();
  final StreamController<P2PMessage> _messageStreamController =
      StreamController<P2PMessage>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  P2PDeviceType get deviceType => _deviceType;
  List<P2PDevice> get connectedDevices => _connectedDevices.values.toList();

  Stream<P2PDevice> get deviceStream => _deviceStreamController.stream;
  Stream<P2PMessage> get messageStream => _messageStreamController.stream;

  /// Initialize the P2P service
  Future<void> initialize({
    required String deviceName,
    required P2PDeviceType deviceType,
    int? customPort,
  }) async {
    if (_isInitialized) {
      print('[P2P] Service already initialized');
      return;
    }

    try {
      _deviceId = const Uuid().v4();
      _deviceName = deviceName;
      _deviceType = deviceType;
      _listeningPort = customPort ?? dataPort;

      print('[P2P] Initializing service - Device: $_deviceName ($_deviceId)');
      _isInitialized = true;
    } catch (e) {
      print('[P2P] Initialization failed: $e');
      rethrow;
    }
  }

  /// Start the P2P service (TCP server + discovery)
  Future<void> start() async {
    if (!_isInitialized) {
      throw Exception('P2P Service not initialized. Call initialize() first.');
    }

    if (_isRunning) {
      print('[P2P] Service already running');
      return;
    }

    try {
      print('[P2P] Starting service on port $_listeningPort');

      // Start TCP server for receiving orders and messages
      await _startTCPServer();

      // Start discovery broadcast listener
      await _startDiscoveryListener();

      // Start heartbeat timer
      _startHeartbeat();

      // Start device timeout monitor
      _startDeviceTimeoutMonitor();

      _isRunning = true;
      print('[P2P] Service started successfully');
    } catch (e) {
      print('[P2P] Failed to start service: $e');
      await stop();
      rethrow;
    }
  }

  /// Stop the P2P service
  Future<void> stop() async {
    print('[P2P] Stopping service');

    _heartbeatTimer?.cancel();
    _deviceTimeoutTimer?.cancel();

    await _tcpServer?.close();
    _discoverySocket?.close();

    _connectedDevices.clear();
    for (var listener in _deviceListeners.values) {
      await listener.cancel();
    }
    _deviceListeners.clear();

    _isRunning = false;
    print('[P2P] Service stopped');
  }

  /// Discover devices on the local network via UDP broadcast
  Future<List<P2PDevice>> discoverDevices({Duration timeout = discoveryTimeout}) async {
    print('[P2P] Starting device discovery...');

    final discoveries = <P2PDevice>[];

    try {
      // Broadcast discovery request
      await _broadcastDiscoveryRequest();

      // Wait for responses
      await Future.delayed(timeout);

      print('[P2P] Discovery completed. Found ${_connectedDevices.length} devices');
      discoveries.addAll(_connectedDevices.values);
    } catch (e) {
      print('[P2P] Discovery error: $e');
    }

    return discoveries;
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(P2PDevice device) async {
    try {
      print('[P2P] Connecting to device: ${device.displayTitle}');

      final socket = await Socket.connect(device.ipAddress, device.port)
          .timeout(const Duration(seconds: 5));

      // Send introduction message
      final introMessage = P2PMessage(
        messageId: const Uuid().v4(),
        messageType: P2PMessageType.deviceInfo,
        fromDeviceId: _deviceId,
        toDeviceId: device.deviceId,
        timestamp: DateTime.now(),
        payload: {
          'deviceName': _deviceName,
          'deviceType': _deviceType.toString(),
          'port': _listeningPort,
        },
      );

      socket.add(utf8.encode(introMessage.toJsonString() + '\n'));

      // Update device status
      _updateDeviceStatus(device.copyWith(
        connectionStatus: P2PConnectionStatus.connected,
        lastSeen: DateTime.now(),
      ));

      // Listen for messages from this device
      _listenToDevice(socket, device.deviceId);

      print('[P2P] Connected to ${device.displayTitle}');
      return true;
    } catch (e) {
      print('[P2P] Connection failed: $e');
      _updateDeviceStatus(device.copyWith(
        connectionStatus: P2PConnectionStatus.error,
      ));
      return false;
    }
  }

  /// Send a message to a device
  Future<void> sendMessage(P2PMessage message) async {
    try {
      if (!_isRunning) {
        throw Exception('P2P Service is not running');
      }

      print('[P2P] Sending message: ${message.messageType.value} to ${message.toDeviceId ?? "all"}');

      final messageString = message.toJsonString();
      final messageBytes = utf8.encode(messageString + '\n');

      if (message.isBroadcast) {
        // Broadcast to all connected devices
        for (final device in _connectedDevices.values) {
          try {
            await _sendToDevice(device.ipAddress, device.port, messageBytes);
          } catch (e) {
            print('[P2P] Failed to send to ${device.displayTitle}: $e');
          }
        }
      } else if (message.toDeviceId != null) {
        // Send to specific device
        final device = _connectedDevices[message.toDeviceId];
        if (device != null) {
          await _sendToDevice(device.ipAddress, device.port, messageBytes);
        } else {
          throw Exception('Device ${message.toDeviceId} not found');
        }
      }
    } catch (e) {
      print('[P2P] Error sending message: $e');
    }
  }

  /// Send an order to a device
  Future<void> sendOrder(P2POrderMessage orderMessage) async {
    try {
      print('[P2P] Sending order ${orderMessage.orderId}');
      await sendMessage(orderMessage);
    } catch (e) {
      print('[P2P] Error sending order: $e');
      rethrow;
    }
  }

  /// Send order status update
  Future<void> sendOrderStatus(P2POrderStatusMessage statusMessage) async {
    try {
      print('[P2P] Updating order status: ${statusMessage.orderId}');
      await sendMessage(statusMessage);
    } catch (e) {
      print('[P2P] Error sending order status: $e');
      rethrow;
    }
  }

  /// Register a message handler
  void onMessage(P2PMessageType messageType, P2PMessageCallback callback) {
    _messageHandlers.putIfAbsent(messageType, () => []).add(callback);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await _deviceStreamController.close();
    await _messageStreamController.close();
  }

  // ===== PRIVATE METHODS =====

  /// Start TCP server to receive connections
  Future<void> _startTCPServer() async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, _listeningPort);
      print('[P2P] TCP Server listening on port $_listeningPort');

      _tcpServer?.listen(
        (socket) => _handleIncomingConnection(socket),
        onError: (error) => print('[P2P] Server error: $error'),
      );
    } catch (e) {
      print('[P2P] Failed to start TCP server: $e');
      rethrow;
    }
  }

  /// Handle incoming TCP connection
  void _handleIncomingConnection(Socket socket) {
    print('[P2P] New connection from ${socket.remoteAddress.address}');
    _listenToSocket(socket);
  }

  /// Listen to a socket for incoming messages
  void _listenToSocket(Socket socket) {
    socket.listen(
      (data) {
        final messageString = utf8.decode(data).trim();
        if (messageString.isNotEmpty) {
          try {
            final messages = messageString.split('\n');
            for (final msgStr in messages) {
              if (msgStr.isNotEmpty) {
                final message = P2PMessage.fromJsonString(msgStr);
                _handleIncomingMessage(message);

                // Track device
                if (!_connectedDevices.containsKey(message.fromDeviceId)) {
                  _discoverDeviceFromMessage(message);
                }
              }
            }
          } catch (e) {
            print('[P2P] Error parsing message: $e');
          }
        }
      },
      onError: (error) => print('[P2P] Socket error: $error'),
      onDone: () => print('[P2P] Socket closed'),
    );
  }

  /// Listen to a specific device for messages
  void _listenToDevice(Socket socket, String deviceId) {
    socket.listen(
      (data) {
        final messageString = utf8.decode(data).trim();
        if (messageString.isNotEmpty) {
          try {
            final message = P2PMessage.fromJsonString(messageString);
            _handleIncomingMessage(message);
          } catch (e) {
            print('[P2P] Error parsing message from device: $e');
          }
        }
      },
      onError: (error) {
        print('[P2P] Device socket error: $error');
        final device = _connectedDevices[deviceId];
        if (device != null) {
          _updateDeviceStatus(device.copyWith(
            connectionStatus: P2PConnectionStatus.error,
          ));
        }
      },
      onDone: () {
        _deviceListeners.remove(deviceId)?.cancel();
      },
    );
  }

  /// Handle incoming message
  void _handleIncomingMessage(P2PMessage message) {
    print('[P2P] Received message: ${message.messageType.value} from ${message.fromDeviceId}');

    // Update last seen for device
    final device = _connectedDevices[message.fromDeviceId];
    if (device != null) {
      _updateDeviceStatus(device.copyWith(lastSeen: DateTime.now()));
    }

    // Handle acknowledgement expectation
    if (message.messageType != P2PMessageType.acknowledgement) {
      // Optionally send acknowledgement
      _sendAcknowledgement(message);
    }

    // Call registered handlers
    final handlers = _messageHandlers[message.messageType];
    if (handlers != null) {
      for (final handler in handlers) {
        try {
          handler(message);
        } catch (e) {
          print('[P2P] Error in message handler: $e');
        }
      }
    }

    // Emit to stream
    _messageStreamController.add(message);

    // Complete pending acknowledgements
    _pendingAcknowledgements[message.messageId]?.complete(message);
  }

  /// Send acknowledgement for a message
  void _sendAcknowledgement(P2PMessage message) {
    try {
      final ackMessage = P2PAckMessage(
        messageId: const Uuid().v4(),
        fromDeviceId: _deviceId,
        toDeviceId: message.fromDeviceId,
        acknowledgedMessageId: message.messageId,
      );
      sendMessage(ackMessage);
    } catch (e) {
      print('[P2P] Error sending acknowledgement: $e');
    }
  }

  /// Discover device via network interface
  void _discoverDeviceFromMessage(P2PMessage message) {
    // Create device from received message metadata
    // This would be populated by actual device discovery
  }

  /// Start UDP discovery listener
  Future<void> _startDiscoveryListener() async {
    try {
      _discoverySocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      print('[P2P] Discovery listener started on port $discoveryPort');

      _discoverySocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          try {
            final datagram = _discoverySocket?.receive();
            if (datagram != null) {
              final message = utf8.decode(datagram.data).trim();
              if (message.isNotEmpty) {
                _handleDiscoveryMessage(message, datagram.address.address);
              }
            }
          } catch (e) {
            print('[P2P] Error in discovery listener: $e');
          }
        }
      });
    } catch (e) {
      print('[P2P] Failed to start discovery listener: $e');
    }
  }

  /// Handle discovery broadcast message
  void _handleDiscoveryMessage(String messageString, String ipAddress) {
    try {
      final discovery = P2PDiscoveryResponse.fromJson(jsonDecode(messageString));
      final device = discovery.toDevice().copyWith(
        ipAddress: ipAddress,
        connectionStatus: P2PConnectionStatus.connected,
        lastSeen: DateTime.now(),
      );

      _updateDeviceStatus(device);
    } catch (e) {
      print('[P2P] Error parsing discovery message: $e');
    }
  }

  /// Broadcast discovery request
  Future<void> _broadcastDiscoveryRequest() async {
    try {
      final discoveryMessage = P2PDiscoveryMessage(
        messageId: const Uuid().v4(),
        fromDeviceId: _deviceId,
        deviceInfo: {
          'deviceName': _deviceName,
          'deviceType': _deviceType.toString(),
          'port': _listeningPort,
        },
      );

      final messageString = discoveryMessage.toJsonString();
      final messageBytes = utf8.encode(messageString);

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      socket.send(
        messageBytes,
        InternetAddress(discoveryBroadcastAddress),
        discoveryPort,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      socket.close();
    } catch (e) {
      print('[P2P] Error broadcasting discovery request: $e');
    }
  }

  /// Send data to a device
  Future<void> _sendToDevice(String ipAddress, int port, List<int> data) async {
    try {
      final socket = await Socket.connect(ipAddress, port)
          .timeout(const Duration(seconds: 3));
      socket.add(data);
      await socket.flush();
      await socket.close();
    } catch (e) {
      print('[P2P] Error sending to device: $e');
      rethrow;
    }
  }

  /// Update device status and emit event
  void _updateDeviceStatus(P2PDevice device) {
    final oldDevice = _connectedDevices[device.deviceId];
    _connectedDevices[device.deviceId] = device;

    final connected = device.connectionStatus == P2PConnectionStatus.connected;
    final wasConnected =
        oldDevice?.connectionStatus == P2PConnectionStatus.connected;

    if (connected != wasConnected) {
      _deviceStreamController.add(device);
    }
  }

  /// Start heartbeat to keep connections alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      for (final device in _connectedDevices.values) {
        try {
          final heartbeat = P2PHeartbeatMessage(
            messageId: const Uuid().v4(),
            fromDeviceId: _deviceId,
            toDeviceId: device.deviceId,
          );
          sendMessage(heartbeat);
        } catch (e) {
          print('[P2P] Heartbeat error: $e');
        }
      }
    });
  }

  /// Monitor and remove inactive devices
  void _startDeviceTimeoutMonitor() {
    _deviceTimeoutTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      final toRemove = <String>[];

      for (final device in _connectedDevices.values) {
        final lastSeen = device.lastSeen;
        if (lastSeen != null && now.difference(lastSeen) > deviceTimeout) {
          toRemove.add(device.deviceId);
        }
      }

      for (final deviceId in toRemove) {
        final device = _connectedDevices.remove(deviceId);
        if (device != null) {
          print('[P2P] Device timeout: ${device.displayTitle}');
          _deviceStreamController.add(
              device.copyWith(connectionStatus: P2PConnectionStatus.disconnected));
        }
      }
    });
  }
}
