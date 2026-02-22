import 'package:flutter/material.dart';

/// Enum for P2P device types in the network
enum P2PDeviceType {
  mainPOS, // Primary POS terminal
  orderingTablet, // Mobile device for taking orders
  secondaryPOS, // Secondary POS terminal
  kds, // Kitchen Display System
  customerDisplay, // Customer-facing display
}

extension P2PDeviceTypeExtension on P2PDeviceType {
  String get displayName {
    switch (this) {
      case P2PDeviceType.mainPOS:
        return 'Main POS';
      case P2PDeviceType.orderingTablet:
        return 'Ordering Tablet';
      case P2PDeviceType.secondaryPOS:
        return 'Secondary POS';
      case P2PDeviceType.kds:
        return 'Kitchen Display';
      case P2PDeviceType.customerDisplay:
        return 'Customer Display';
    }
  }

  IconData get icon {
    switch (this) {
      case P2PDeviceType.mainPOS:
        return Icons.desktop_mac;
      case P2PDeviceType.orderingTablet:
        return Icons.tablet;
      case P2PDeviceType.secondaryPOS:
        return Icons.devices;
      case P2PDeviceType.kds:
        return Icons.restaurant;
      case P2PDeviceType.customerDisplay:
        return Icons.display_settings;
    }
  }

  Color get statusColor {
    switch (this) {
      case P2PDeviceType.mainPOS:
        return const Color(0xFF2196F3);
      case P2PDeviceType.orderingTablet:
        return const Color(0xFF4CAF50);
      case P2PDeviceType.secondaryPOS:
        return const Color(0xFFFF9800);
      case P2PDeviceType.kds:
        return const Color(0xFFF44336);
      case P2PDeviceType.customerDisplay:
        return const Color(0xFF9C27B0);
    }
  }
}

/// Enum for P2P connection status
enum P2PConnectionStatus {
  disconnected,
  discovering,
  connecting,
  connected,
  error,
}

extension P2PConnectionStatusExtension on P2PConnectionStatus {
  String get displayName {
    switch (this) {
      case P2PConnectionStatus.disconnected:
        return 'Disconnected';
      case P2PConnectionStatus.discovering:
        return 'Discovering...';
      case P2PConnectionStatus.connecting:
        return 'Connecting...';
      case P2PConnectionStatus.connected:
        return 'Connected';
      case P2PConnectionStatus.error:
        return 'Error';
    }
  }

  Color get color {
    switch (this) {
      case P2PConnectionStatus.disconnected:
        return Colors.grey;
      case P2PConnectionStatus.discovering:
      case P2PConnectionStatus.connecting:
        return Colors.orange;
      case P2PConnectionStatus.connected:
        return Colors.green;
      case P2PConnectionStatus.error:
        return Colors.red;
    }
  }
}

/// Model representing a connected P2P device on the local network
class P2PDevice {
  final String deviceId;
  final String deviceName;
  final P2PDeviceType deviceType;
  final String ipAddress;
  final int port;
  final String hostname;
  P2PConnectionStatus connectionStatus;
  DateTime? lastSeen;
  final Map<String, dynamic> metadata; // Device-specific metadata
  
  P2PDevice({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.port,
    required this.hostname,
    this.connectionStatus = P2PConnectionStatus.disconnected,
    this.lastSeen,
    this.metadata = const {},
  });

  /// Check if device is currently active
  bool get isActive =>
      connectionStatus == P2PConnectionStatus.connected &&
      (lastSeen?.difference(DateTime.now()).inSeconds.abs() ?? 0) < 30;

  /// Get display title for the device
  String get displayTitle => '$deviceName (${deviceType.displayName})';

  /// Create a copy of this device with modified fields
  P2PDevice copyWith({
    String? deviceId,
    String? deviceName,
    P2PDeviceType? deviceType,
    String? ipAddress,
    int? port,
    String? hostname,
    P2PConnectionStatus? connectionStatus,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return P2PDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      hostname: hostname ?? this.hostname,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType.toString(),
      'ipAddress': ipAddress,
      'port': port,
      'hostname': hostname,
      'connectionStatus': connectionStatus.toString(),
      'lastSeen': lastSeen?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory P2PDevice.fromJson(Map<String, dynamic> json) {
    return P2PDevice(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      deviceType: P2PDeviceType.values.firstWhere(
        (e) => e.toString() == json['deviceType'],
        orElse: () => P2PDeviceType.secondaryPOS,
      ),
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      hostname: json['hostname'] as String? ?? '',
      connectionStatus: P2PConnectionStatus.values.firstWhere(
        (e) => e.toString() == json['connectionStatus'],
        orElse: () => P2PConnectionStatus.disconnected,
      ),
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() =>
      'P2PDevice(id=$deviceId, name=$deviceName, type=$deviceType, ip=$ipAddress:$port)';
}

/// Model for P2P device discovery response
class P2PDiscoveryResponse {
  final String deviceId;
  final String deviceName;
  final P2PDeviceType deviceType;
  final String ipAddress;
  final int port;
  final String hostname;
  final Map<String, dynamic> metadata;

  P2PDiscoveryResponse({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.port,
    required this.hostname,
    this.metadata = const {},
  });

  /// Convert to P2PDevice
  P2PDevice toDevice() {
    return P2PDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      ipAddress: ipAddress,
      port: port,
      hostname: hostname,
      metadata: metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType.toString(),
      'ipAddress': ipAddress,
      'port': port,
      'hostname': hostname,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory P2PDiscoveryResponse.fromJson(Map<String, dynamic> json) {
    return P2PDiscoveryResponse(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      deviceType: P2PDeviceType.values.firstWhere(
        (e) => e.toString() == json['deviceType'],
        orElse: () => P2PDeviceType.secondaryPOS,
      ),
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      hostname: json['hostname'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
