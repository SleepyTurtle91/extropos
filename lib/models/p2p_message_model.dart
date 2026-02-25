import 'dart:convert';

/// Enum for P2P message types
enum P2PMessageType {
  // Discovery and connection
  discovery, // Device announcement for discovery
  acknowledgement, // Acknowledge receipt of message
  heartbeat, // Keep-alive signal

  // Order related
  orderForward, // Forward order to client device
  orderStatus, // Status update of an order
  orderCancel, // Cancel an order
  orderSync, // Sync order state

  // Sync and data
  cartSync, // Sync cart with other devices
  productSync, // Sync product data
  configSync, // Sync configuration

  // Device management
  deviceInfo, // Device information request/response
  serverMode, // Enter/exit server mode

  // Control
  broadcastUpdate, // Broadcast update to all devices
  deviceCommand, // Command execution request
  deviceResponse, // Command response

  // Error handling
  error, // Error message
  warning, // Warning message
}

extension P2PMessageTypeExtension on P2PMessageType {
  String get value {
    return toString().split('.').last;
  }

  static P2PMessageType fromValue(String value) {
    return P2PMessageType.values
        .firstWhere((e) => e.value == value, orElse: () => P2PMessageType.error);
  }
}

/// Base class for all P2P messages
class P2PMessage {
  final String messageId;
  final P2PMessageType messageType;
  final String fromDeviceId;
  final String? toDeviceId; // null = broadcast
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final int priority; // 0-10, higher = more important
  bool? acknowledged;

  P2PMessage({
    required this.messageId,
    required this.messageType,
    required this.fromDeviceId,
    this.toDeviceId,
    required this.timestamp,
    this.payload = const {},
    this.priority = 5,
    this.acknowledged,
  });

  /// Check if message is broadcast
  bool get isBroadcast => toDeviceId == null;

  /// Check if message is response to a specific device
  bool get isDirected => toDeviceId != null;

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'messageType': messageType.value,
      'fromDeviceId': fromDeviceId,
      'toDeviceId': toDeviceId,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
      'priority': priority,
      'acknowledged': acknowledged,
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON
  factory P2PMessage.fromJson(Map<String, dynamic> json) {
    return P2PMessage(
      messageId: json['messageId'] as String,
      messageType: P2PMessageTypeExtension.fromValue(json['messageType'] as String),
      fromDeviceId: json['fromDeviceId'] as String,
      toDeviceId: json['toDeviceId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      priority: json['priority'] as int? ?? 5,
      acknowledged: json['acknowledged'] as bool?,
    );
  }

  /// Create from JSON string
  factory P2PMessage.fromJsonString(String jsonString) {
    return P2PMessage.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Create a copy with modified fields
  P2PMessage copyWith({
    String? messageId,
    P2PMessageType? messageType,
    String? fromDeviceId,
    String? toDeviceId,
    DateTime? timestamp,
    Map<String, dynamic>? payload,
    int? priority,
    bool? acknowledged,
  }) {
    return P2PMessage(
      messageId: messageId ?? this.messageId,
      messageType: messageType ?? this.messageType,
      fromDeviceId: fromDeviceId ?? this.fromDeviceId,
      toDeviceId: toDeviceId ?? this.toDeviceId,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  @override
  String toString() =>
      'P2PMessage(id=$messageId, type=${messageType.value}, from=$fromDeviceId, to=$toDeviceId)';
}

/// Specialized message for discovery announcements
class P2PDiscoveryMessage extends P2PMessage {
  P2PDiscoveryMessage({
    required super.messageId,
    required super.fromDeviceId,
    required Map<String, dynamic> deviceInfo,
  }) : super(
    messageType: P2PMessageType.discovery,
    timestamp: DateTime.now(),
    payload: deviceInfo,
    priority: 8,
  );
}

/// Specialized message for heartbeat
class P2PHeartbeatMessage extends P2PMessage {
  P2PHeartbeatMessage({
    required super.messageId,
    required super.fromDeviceId,
    super.toDeviceId,
  }) : super(
    messageType: P2PMessageType.heartbeat,
    timestamp: DateTime.now(),
    priority: 2,
  );
}

/// Specialized message for acknowledgement
class P2PAckMessage extends P2PMessage {
  final String? acknowledgedMessageId;

  P2PAckMessage({
    required super.messageId,
    required super.fromDeviceId,
    required String super.toDeviceId,
    this.acknowledgedMessageId,
  }) : super(
    messageType: P2PMessageType.acknowledgement,
    timestamp: DateTime.now(),
    payload: {
      if (acknowledgedMessageId != null) 'acknowledgedMessageId': acknowledgedMessageId,
    },
    priority: 3,
  );
}

/// Specialized message for error reporting
class P2PErrorMessage extends P2PMessage {
  final String errorCode;
  final String errorDescription;
  final String? errorDetails;

  P2PErrorMessage({
    required super.messageId,
    required super.fromDeviceId,
    super.toDeviceId,
    required this.errorCode,
    required this.errorDescription,
    this.errorDetails,
  }) : super(
    messageType: P2PMessageType.error,
    timestamp: DateTime.now(),
    payload: {
      'errorCode': errorCode,
      'errorDescription': errorDescription,
      if (errorDetails != null) 'errorDetails': errorDetails,
    },
    priority: 9,
  );
}
