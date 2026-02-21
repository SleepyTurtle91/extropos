import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';

/// Helper class for Android runtime permissions (via native channel)
class PermissionsHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.extrotarget.extropos/printer',
  );

  /// Request Bluetooth permissions on Android 12+
  static Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _channel.invokeMethod('requestBluetoothPermissions');
      return result == true;
    } catch (e) {
      developer.log('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  /// Check if Bluetooth permissions are granted
  static Future<bool> hasBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _channel.invokeMethod('hasBluetoothPermissions');
      return result == true;
    } catch (e) {
      developer.log('Error checking Bluetooth permissions: $e');
      return false;
    }
  }
}
