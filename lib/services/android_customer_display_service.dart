import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/customer_display_model.dart';
import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';

class AndroidCustomerDisplayService {
  static const MethodChannel _channel = MethodChannel(
    'com.extrotarget.extropos/printer',
  );

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');
    } catch (e) {
      developer.log('AndroidCustomerDisplayService: initialize error: $e');
    }
  }

  Future<List<CustomerDisplay>> discoverDisplays() async {
    if (!Platform.isAndroid) return [];
    try {
      final res = await _channel.invokeMethod('discoverCustomerDisplays');
      final List<dynamic> list = res as List<dynamic>;
      final displays = list
          .map(
            (e) =>
                CustomerDisplay.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      return displays;
    } catch (e) {
      developer.log(
        'AndroidCustomerDisplayService: discoverDisplays error: $e',
      );
      return [];
    }
  }

  Future<bool> showText(CustomerDisplay display, String text) async {
    if (!Platform.isAndroid) return false;
    try {
      final args = {
        'displayId': display.id,
        'connectionDetails': {
          'connectionType': display.connectionType.name,
          'ipAddress': display.ipAddress,
          'port': display.port,
          'usbDeviceId': display.usbDeviceId,
          'bluetoothAddress': display.bluetoothAddress,
          'platformSpecificId': display.platformSpecificId,
        },
        'text': text,
      };
      final res = await _channel.invokeMethod('showCustomerDisplay', args);
      return res == true;
    } catch (e) {
      developer.log('AndroidCustomerDisplayService: showText error: $e');
      return false;
    }
  }

  Future<bool> clear(CustomerDisplay display) async {
    if (!Platform.isAndroid) return false;
    try {
      final args = {'displayId': display.id};
      final res = await _channel.invokeMethod('clearCustomerDisplay', args);
      return res == true;
    } catch (e) {
      developer.log('AndroidCustomerDisplayService: clear error: $e');
      return false;
    }
  }

  Future<bool> test(CustomerDisplay display) async {
    if (!Platform.isAndroid) return false;
    try {
      final args = {'displayId': display.id};
      final res = await _channel.invokeMethod('testCustomerDisplay', args);
      return res == true;
    } catch (e) {
      developer.log('AndroidCustomerDisplayService: test error: $e');
      return false;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      // Add any callbacks from native side if needed
      default:
        developer.log(
          'AndroidCustomerDisplayService: Unknown method call: ${call.method}',
        );
    }
  }
}
