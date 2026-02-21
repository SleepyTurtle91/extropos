import 'dart:developer' as developer;

import 'package:extropos/screens/error_console_screen.dart';
import 'package:extropos/screens/performance_optimization_screen.dart';
import 'package:extropos/services/android_printer_service.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/permissions_helper.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class DebugToolsScreen extends StatefulWidget {
  const DebugToolsScreen({super.key});

  @override
  State<DebugToolsScreen> createState() => _DebugToolsScreenState();
}

class _DebugToolsScreenState extends State<DebugToolsScreen> {
  final PrinterService _printerService = PrinterService();
  bool _isBusy = false;
  bool _autoDebug = false;

  @override
  void initState() {
    super.initState();
    _autoDebug = AppSettings.instance.autoDebugPrintOnSampleFailure;
  }

  Future<void> _discoverLocalPrinters() async {
    setState(() => _isBusy = true);
    try {
      developer.log('DebugTools: Discovering local printers');
      final printers = await _printerService.discoverPrinters();
      developer.log('DebugTools: printers: ${printers.length}');
      for (final p in printers) {
        developer.log('DebugTools: printer ${p.name} ${p.id} ${p.modelName}');
      }
      if (!mounted) return;
      ToastHelper.showToast(context, 'Found ${printers.length} printers');
    } catch (e) {
      developer.log('DebugTools: discoverLocalPrinters failed: $e');
      if (mounted) ToastHelper.showToast(context, 'Discover local printers failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _discoverBluetoothPrinters() async {
    setState(() => _isBusy = true);
    try {
      developer.log('DebugTools: Discovering Bluetooth printers');
      final hasPerm = await PermissionsHelper.hasBluetoothPermissions();
      if (!hasPerm) {
        final requested = await PermissionsHelper.requestBluetoothPermissions();
        developer.log('DebugTools: Bluetooth permission requested: $requested');
      }
      final printers = await AndroidPrinterService().discoverBluetoothPrinters();
      developer.log('DebugTools: BT printers count: ${printers.length}');
      for (final p in printers) {
        developer.log('DebugTools: BT ${p.name} ${p.id} ${p.platformSpecificId}');
      }
      if (!mounted) return;
      ToastHelper.showToast(context, 'Found ${printers.length} Bluetooth printers');
    } catch (e) {
      developer.log('DebugTools: discoverBluetoothPrinters failed: $e');
      if (mounted) ToastHelper.showToast(context, 'Discover BT printers failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _requestBtPermissions() async {
    setState(() => _isBusy = true);
    try {
      final ok = await PermissionsHelper.requestBluetoothPermissions();
      developer.log('DebugTools: requestBluetoothPermissions result: $ok');
      if (mounted) ToastHelper.showToast(context, ok ? 'Bluetooth permission granted' : 'Bluetooth permission denied');
    } catch (e) {
      developer.log('DebugTools: requestBluetoothPermissions failed: $e');
      if (mounted) ToastHelper.showToast(context, 'Request Bluetooth permissions failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isBusy ? null : _discoverLocalPrinters,
              child: const Text('Discover Local Printers'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isBusy ? null : _discoverBluetoothPrinters,
              child: const Text('Discover Bluetooth Printers'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isBusy ? null : _requestBtPermissions,
              child: const Text('Request Bluetooth Permissions'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ErrorConsoleScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[800],
              ),
              child: const Text('Error Console'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerformanceOptimizationScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[800],
              ),
              child: const Text('Performance Optimization'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _autoDebug,
              title: const Text('Auto-run Debug Force Print on Sample Receipt Failure'),
              subtitle: const Text('Auto-run a native debug print when Sample Receipt fails but Test Print succeeds (developer only)'),
              onChanged: (v) async {
                setState(() => _autoDebug = v);
                await AppSettings.instance.setAutoDebugPrintOnSampleFailure(v);
                if (mounted) ToastHelper.showToast(context, 'Auto-run debug print ${v ? 'enabled' : 'disabled'}');
              },
            ),
            const SizedBox(height: 8),
            const Text('Diagnostics and plugin logs available in Printer Debug Console'),
          ],
        ),
      ),
    );
  }
}
