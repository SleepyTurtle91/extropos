import 'package:extropos/models/customer_display_model.dart';
import 'package:extropos/models/printer_model.dart' show PrinterConnectionType;
import 'package:extropos/services/customer_display_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class CustomerDisplaysManagementScreen extends StatefulWidget {
  const CustomerDisplaysManagementScreen({super.key});

  @override
  State<CustomerDisplaysManagementScreen> createState() =>
      _CustomerDisplaysManagementScreenState();
}

class _CustomerDisplaysManagementScreenState
    extends State<CustomerDisplaysManagementScreen> {
  final CustomerDisplayService _service = CustomerDisplayService();
  List<CustomerDisplay> _displays = [];

  @override
  void initState() {
    super.initState();
    _loadDisplays();
  }

  Future<void> _loadDisplays() async {
    final saved = await DatabaseService.instance.getCustomerDisplays();
    final discovered = await _service.discoverDisplays();
    setState(() {
      _displays = saved;
      // merge discovered that are not saved
      for (final d in discovered) {
        if (!_displays.any(
          (s) => s.id == d.id || s.platformSpecificId == d.platformSpecificId,
        )) {
          _displays.add(d);
        }
      }
    });
  }

  Future<void> _addDisplay() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final display = CustomerDisplay(
      id: id,
      name: 'New Customer Display',
      connectionType: PrinterConnectionType.network,
      ipAddress: '192.168.0.100',
      port: 9000,
    );
    await DatabaseService.instance.saveCustomerDisplay(display);
    ToastHelper.showToast(context, 'Customer display saved');
    _loadDisplays();
  }

  Future<void> _deleteDisplay(String id) async {
    await DatabaseService.instance.deleteCustomerDisplay(id);
    ToastHelper.showToast(context, 'Customer display deleted');
    _loadDisplays();
  }

  Future<void> _testDisplay(CustomerDisplay d) async {
    final ok = await _service.testDisplay(d);
    ToastHelper.showToast(
      context,
      ok ? 'Test display OK' : 'Test display failed',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Displays')),
      body: RefreshIndicator(
        onRefresh: _loadDisplays,
        child: ListView.builder(
          itemCount: _displays.length,
          itemBuilder: (context, i) {
            final d = _displays[i];
            return ListTile(
              title: Text(d.name),
              subtitle: Text(
                '${d.connectionType.name} - ${d.ipAddress ?? d.platformSpecificId ?? ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _testDisplay(d),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteDisplay(d.id),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDisplay,
        child: const Icon(Icons.add),
      ),
    );
  }
}
