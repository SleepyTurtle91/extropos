import 'package:extropos/models/printer_model.dart';

enum CustomerDisplayStatus { online, offline, error }

class CustomerDisplay {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final String? ipAddress;
  final int? port;
  final String? usbDeviceId;
  final String? bluetoothAddress;
  final String? platformSpecificId;
  String? modelName;
  CustomerDisplayStatus status;
  bool isDefault;
  bool isActive;
  bool hasPermission;

  CustomerDisplay({
    required this.id,
    required this.name,
    required this.connectionType,
    this.ipAddress,
    this.port = 9100,
    this.usbDeviceId,
    this.bluetoothAddress,
    this.platformSpecificId,
    this.modelName,
    this.status = CustomerDisplayStatus.offline,
    this.isDefault = false,
    this.isActive = true,
    this.hasPermission = true,
  });

  CustomerDisplay copyWith({
    String? id,
    String? name,
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
    String? usbDeviceId,
    String? bluetoothAddress,
    String? platformSpecificId,
    String? modelName,
    CustomerDisplayStatus? status,
    bool? isDefault,
    bool? isActive,
    bool? hasPermission,
  }) {
    return CustomerDisplay(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      usbDeviceId: usbDeviceId ?? this.usbDeviceId,
      bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
      platformSpecificId: platformSpecificId ?? this.platformSpecificId,
      modelName: modelName ?? this.modelName,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'connection_type': connectionType.name,
      'ip_address': ipAddress,
      'port': port,
      'usb_device_id': usbDeviceId,
      'bluetooth_address': bluetoothAddress,
      'platform_specific_id': platformSpecificId,
      'device_name': modelName,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'status': status.name,
      'has_permission': hasPermission ? 1 : 0,
    };
  }

  factory CustomerDisplay.fromJson(Map<String, dynamic> map) {
    final connectionType = PrinterConnectionType.values.firstWhere(
      (e) => e.name == map['connection_type'],
      orElse: () => PrinterConnectionType.network,
    );

    final status = (map['status'] != null)
        ? CustomerDisplayStatus.values.firstWhere(
            (e) => e.name == map['status'],
            orElse: () => CustomerDisplayStatus.offline,
          )
        : CustomerDisplayStatus.offline;

    return CustomerDisplay(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: (map['name'] ?? 'Unknown Display').toString(),
      connectionType: connectionType,
      ipAddress: map['ip_address'] as String?,
      port: map['port'] as int?,
      usbDeviceId: map['usb_device_id'] as String?,
      bluetoothAddress: map['bluetooth_address'] as String?,
      platformSpecificId: map['platform_specific_id'] as String?,
      modelName: map['device_name'] as String?,
      status: status,
      isDefault: (map['is_default'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      hasPermission: (map['has_permission'] as int?) == 1,
    );
  }
}
