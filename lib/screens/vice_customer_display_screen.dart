import 'package:extropos/models/customer_display_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/customer_display_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// Customer Display Screen - Control and test customer-facing displays
class ViceCustomerDisplayScreen extends StatefulWidget {
  const ViceCustomerDisplayScreen({super.key});

  @override
  State<ViceCustomerDisplayScreen> createState() => _ViceCustomerDisplayScreenState();
}

class _ViceCustomerDisplayScreenState extends State<ViceCustomerDisplayScreen> {
  List<CustomerDisplay> _displays = [];
  bool _isLoading = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadDisplays();
  }

  Future<void> _loadDisplays() async {
    setState(() => _isLoading = true);

    try {
      _displays = await DatabaseService.instance.getCustomerDisplays();
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to load customer displays');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDisplay(CustomerDisplay display) async {
    setState(() => _isTesting = true);

    try {
      final success = await CustomerDisplayService().testDisplay(display);
      if (success) {
        ToastHelper.showToast(context, 'Display test successful');
      } else {
        ToastHelper.showToast(context, 'Display test failed');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Display test error: ${e.toString()}');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _showMessage(CustomerDisplay display) async {
    final controller = TextEditingController(text: 'Welcome to FlutterPOS!');
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Message to display',
            hintText: 'Enter message for customer display',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (message != null && message.isNotEmpty) {
      try {
        final success = await CustomerDisplayService().showText(display, message);
        if (success) {
          ToastHelper.showToast(context, 'Message sent to display');
        } else {
          ToastHelper.showToast(context, 'Failed to send message');
        }
      } catch (e) {
        ToastHelper.showToast(context, 'Error sending message: ${e.toString()}');
      }
    }
  }

  Future<void> _clearDisplay(CustomerDisplay display) async {
    try {
      final success = await CustomerDisplayService().clear(display);
      if (success) {
        ToastHelper.showToast(context, 'Display cleared');
      } else {
        ToastHelper.showToast(context, 'Failed to clear display');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Error clearing display: ${e.toString()}');
    }
  }

  Future<void> _discoverDisplays() async {
    setState(() => _isLoading = true);

    try {
      final displays = await CustomerDisplayService().discoverDisplays();

      // Save discovered displays
      for (final display in displays) {
        await DatabaseService.instance.saveCustomerDisplay(display);
      }

      await _loadDisplays(); // Refresh the list
      ToastHelper.showToast(context, 'Discovered ${displays.length} display(s)');
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to discover displays: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(CustomerDisplayStatus status) {
    switch (status) {
      case CustomerDisplayStatus.online:
        return Colors.green;
      case CustomerDisplayStatus.offline:
        return Colors.grey;
      case CustomerDisplayStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText(CustomerDisplayStatus status) {
    switch (status) {
      case CustomerDisplayStatus.online:
        return 'Online';
      case CustomerDisplayStatus.offline:
        return 'Offline';
      case CustomerDisplayStatus.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Display'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _discoverDisplays,
            icon: const Icon(Icons.search),
            tooltip: 'Discover Displays',
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadDisplays,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _displays.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.tv_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No customer displays found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _discoverDisplays,
                        icon: const Icon(Icons.search),
                        label: const Text('Discover Displays'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _displays.length,
                  itemBuilder: (context, index) {
                    final display = _displays[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(display.name),
                        subtitle: Text(
                          '${display.connectionType.name.toUpperCase()} - ${_getStatusText(display.status)}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(display.status),
                          child: Icon(
                            display.connectionType == PrinterConnectionType.bluetooth
                                ? Icons.bluetooth
                                : display.connectionType == PrinterConnectionType.usb
                                    ? Icons.usb
                                    : Icons.wifi,
                            color: Colors.white,
                          ),
                        ),
                        trailing: display.isDefault
                            ? const Chip(
                                label: Text('Default'),
                                backgroundColor: Colors.blue,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : null,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Connection details
                                Text('Connection: ${display.connectionType.name}'),
                                if (display.ipAddress != null)
                                  Text('IP Address: ${display.ipAddress}'),
                                if (display.port != null)
                                  Text('Port: ${display.port}'),
                                if (display.bluetoothAddress != null)
                                  Text('Bluetooth: ${display.bluetoothAddress}'),
                                if (display.usbDeviceId != null)
                                  Text('USB ID: ${display.usbDeviceId}'),
                                if (display.modelName != null)
                                  Text('Model: ${display.modelName}'),

                                const SizedBox(height: 16),

                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isTesting ? null : () => _testDisplay(display),
                                        icon: _isTesting
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.play_arrow),
                                        label: const Text('Test'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showMessage(display),
                                        icon: const Icon(Icons.message),
                                        label: const Text('Message'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _clearDisplay(display),
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Clear'),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Set as default button
                                if (!display.isDefault)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await DatabaseService.instance.setDefaultCustomerDisplay(display.id);
                                          await _loadDisplays();
                                          ToastHelper.showToast(context, '${display.name} set as default');
                                        } catch (e) {
                                          ToastHelper.showToast(context, 'Failed to set default display');
                                        }
                                      },
                                      icon: const Icon(Icons.star),
                                      label: const Text('Set as Default'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}