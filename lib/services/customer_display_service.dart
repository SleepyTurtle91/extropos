import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/customer_display_model.dart';
import 'package:extropos/services/android_customer_display_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:universal_io/io.dart';

class CustomerDisplayService {
  static final CustomerDisplayService _instance = CustomerDisplayService._internal();
  factory CustomerDisplayService() => _instance;
  CustomerDisplayService._internal();

  final StreamController<String> _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isAndroid) {
      // No platform-specific initialization required for non-Android (placeholder)
      _initialized = true;
      return;
    }
    try {
      await AndroidCustomerDisplayService().initialize();
      _initialized = true;
    } catch (e) {
      developer.log('CustomerDisplayService: initialize failed: $e');
    }
  }

  Future<List<CustomerDisplay>> discoverDisplays() async {
    if (!Platform.isAndroid) return [];
    try {
      await initialize();
      final result = await AndroidCustomerDisplayService().discoverDisplays();
      return result;
    } catch (e) {
      developer.log('CustomerDisplayService: discoverDisplays failed: $e');
      return [];
    }
  }

  Future<bool> showText(CustomerDisplay display, String text) async {
    try {
      await initialize();
      final success = await AndroidCustomerDisplayService().showText(display, text);
      _logController.add('[CustomerDisplay] showText: ${display.name} -> ${success ? 'OK' : 'FAILED'}');
      return success;
    } catch (e) {
      developer.log('CustomerDisplayService: showText failed: $e');
      return false;
    }
  }

  Future<bool> clear(CustomerDisplay display) async {
    try {
      await initialize();
      final success = await AndroidCustomerDisplayService().clear(display);
      return success;
    } catch (e) {
      developer.log('CustomerDisplayService: clear failed: $e');
      return false;
    }
  }

  Future<bool> testDisplay(CustomerDisplay display) async {
    try {
      await initialize();
      final success = await AndroidCustomerDisplayService().test(display);
      return success;
    } catch (e) {
      developer.log('CustomerDisplayService: testDisplay failed: $e');
      return false;
    }
  }

  Future<List<CustomerDisplay>> getSavedDisplays() async {
    return await DatabaseService.instance.getCustomerDisplays();
  }

  Future<void> saveDisplay(CustomerDisplay display) async {
    return await DatabaseService.instance.saveCustomerDisplay(display);
  }

  Future<void> deleteDisplay(String id) async {
    return await DatabaseService.instance.deleteCustomerDisplay(id);
  }

  Future<CustomerDisplay?> getDefaultDisplay() async {
    return await DatabaseService.instance.getDefaultCustomerDisplay();
  }
}
