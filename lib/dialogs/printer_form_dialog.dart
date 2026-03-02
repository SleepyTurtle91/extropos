import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/dialog_helpers.dart';
import 'package:extropos/widgets/responsive_row.dart';
import 'package:flutter/material.dart';

class PrinterFormDialog extends StatefulWidget {
  final Printer? printer;
  final Function(Printer) onSave;

  const PrinterFormDialog({super.key, this.printer, required this.onSave});

  @override
  State<PrinterFormDialog> createState() => _PrinterFormDialogState();
}

class _PrinterFormDialogState extends State<PrinterFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _usbDeviceIdController;
  late TextEditingController _bluetoothAddressController;
  late TextEditingController _modelController;
  late PrinterType _selectedType;
  late PrinterConnectionType _selectedConnectionType;
  ThermalPaperSize? _selectedPaperSize;
  final PrinterService _printerService = PrinterService();
  List<String> _selectedCategories = [];
  List<Map<String, dynamic>> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.printer?.name ?? '');
    _ipController = TextEditingController(
      text: widget.printer?.ipAddress ?? '192.168.1.',
    );
    _portController = TextEditingController(
      text: widget.printer?.port?.toString() ?? '9100',
    );
    _usbDeviceIdController = TextEditingController(
      text: widget.printer?.usbDeviceId ?? '',
    );
    _bluetoothAddressController = TextEditingController(
      text: widget.printer?.bluetoothAddress ?? '',
    );
    _modelController = TextEditingController(
      text: widget.printer?.modelName ?? '',
    );
    _selectedType = widget.printer?.type ?? PrinterType.receipt;
    _selectedConnectionType =
        widget.printer?.connectionType ?? PrinterConnectionType.network;
    _selectedPaperSize = widget.printer?.paperSize ?? ThermalPaperSize.mm80;
    _selectedCategories = List<String>.from(widget.printer?.categories ?? []);
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _usbDeviceIdController.dispose();
    _bluetoothAddressController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DatabaseService.instance.getCategories();
      if (mounted) {
        setState(() {
          _availableCategories = categories
              .map((c) => {'id': c.id, 'name': c.name})
              .toList();
        });
      }
    } catch (e) {
      // Ignore errors loading categories
    }
  }

  Future<void> _scanUsbDevices() async {
    try {
      // Enable printer logging to see what's happening
      await _printerService.setPrinterLogEnabled(true);

      final printers = await _printerService.discoverPrinters();
      final usbPrinters = printers
          .where((p) => p.connectionType == PrinterConnectionType.usb)
          .toList();

      if (!mounted) return;

      if (usbPrinters.isEmpty) {
        ToastHelper.showToast(
          context,
          'No USB printers found. Check Printer Debug Console for details.',
        );
        return;
      }

      // Show dialog to select from found USB devices
      final selected = await showDialog<Printer>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select USB Printer'),
          content: ConstrainedDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: usbPrinters.length,
                  itemBuilder: (context, index) {
                    final printer = usbPrinters[index];
                    return ListTile(
                      title: Text(printer.name),
                      subtitle: Text(
                        'Device ID: ${printer.usbDeviceId}\nModel: ${printer.modelName ?? 'Unknown'}',
                      ),
                      onTap: () => Navigator.pop(context, printer),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          _usbDeviceIdController.text = selected.usbDeviceId ?? '';
          _nameController.text = selected.name;
          if (selected.modelName != null) {
            _modelController.text = selected.modelName!;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error scanning USB devices: $e');
    }
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ToastHelper.showToast(context, 'Please enter a printer name');
      return;
    }

    // Validate connection-specific fields
    switch (_selectedConnectionType) {
      case PrinterConnectionType.network:
        if (_ipController.text.isEmpty) {
          ToastHelper.showToast(context, 'Please enter an IP address');
          return;
        }
        break;
      case PrinterConnectionType.usb:
        if (_usbDeviceIdController.text.isEmpty) {
          ToastHelper.showToast(context, 'Please enter a USB device ID');
          return;
        }
        break;
      case PrinterConnectionType.bluetooth:
        if (_bluetoothAddressController.text.isEmpty) {
          ToastHelper.showToast(context, 'Please enter a Bluetooth address');
          return;
        }
        break;
      case PrinterConnectionType.posmac:
        // POSMAC doesn't require additional validation for now
        break;
    }

    final Printer printer;
    switch (_selectedConnectionType) {
      case PrinterConnectionType.network:
        printer = Printer.network(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          ipAddress: _ipController.text,
          port: int.tryParse(_portController.text) ?? 9100,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
      case PrinterConnectionType.usb:
        printer = Printer.usb(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          usbDeviceId: _usbDeviceIdController.text,
          platformSpecificId: widget.printer?.platformSpecificId,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
      case PrinterConnectionType.bluetooth:
        printer = Printer.bluetooth(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          bluetoothAddress: _bluetoothAddressController.text,
          platformSpecificId: widget.printer?.platformSpecificId,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
      case PrinterConnectionType.posmac:
        printer = Printer.posmac(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          platformSpecificId: widget.printer?.platformSpecificId ?? '',
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
          categories: _selectedCategories,
        );
        break;
    }

    widget.onSave(printer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.printer == null ? 'Add Printer' : 'Edit Printer'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrinterType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Printer Type *',
                  border: OutlineInputBorder(),
                ),
                items: PrinterType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              // Show category selection for Kitchen and Bar printers
              if (_selectedType == PrinterType.kitchen ||
                  _selectedType == PrinterType.bar) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Categories to Print',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select which product categories should print to this ${_selectedType.name} printer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_availableCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No categories found. Create categories in Settings.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((cat) {
                            final isSelected = _selectedCategories.contains(
                              cat['id'],
                            );
                            return FilterChip(
                              label: Text(cat['name']),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(cat['id']);
                                  } else {
                                    _selectedCategories.remove(cat['id']);
                                  }
                                });
                              },
                              selectedColor: const Color(
                                0xFF2563EB,
                              ).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF2563EB),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<PrinterConnectionType>(
                initialValue: _selectedConnectionType,
                decoration: const InputDecoration(
                  labelText: 'Connection Type *',
                  border: OutlineInputBorder(),
                ),
                items: PrinterConnectionType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedConnectionType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Connection-specific fields
              if (_selectedConnectionType == PrinterConnectionType.network) ...[
                ResponsiveRow(
                  breakpoint: 560,
                  rowChildren: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'IP Address *',
                          border: OutlineInputBorder(),
                          hintText: '192.168.1.100',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(),
                          hintText: '9100',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                  columnChildren: [
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP Address *',
                        border: OutlineInputBorder(),
                        hintText: '192.168.1.100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                        hintText: '9100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ] else if (_selectedConnectionType ==
                  PrinterConnectionType.usb) ...[
                ResponsiveRow(
                  breakpoint: 520,
                  rowChildren: [
                    Expanded(
                      child: TextField(
                        controller: _usbDeviceIdController,
                        decoration: const InputDecoration(
                          labelText: 'USB Device ID *',
                          border: OutlineInputBorder(),
                          hintText: 'VID:PID or device path',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _scanUsbDevices,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                  columnChildren: [
                    TextField(
                      controller: _usbDeviceIdController,
                      decoration: const InputDecoration(
                        labelText: 'USB Device ID *',
                        border: OutlineInputBorder(),
                        hintText: 'VID:PID or device path',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _scanUsbDevices,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedConnectionType ==
                  PrinterConnectionType.bluetooth) ...[
                TextField(
                  controller: _bluetoothAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Bluetooth Address *',
                    border: OutlineInputBorder(),
                    hintText: 'AA:BB:CC:DD:EE:FF',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model Name',
                  border: OutlineInputBorder(),
                  hintText: 'Epson TM-T88VI',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ThermalPaperSize>(
                initialValue: _selectedPaperSize,
                decoration: const InputDecoration(
                  labelText: 'Paper Size',
                  border: OutlineInputBorder(),
                ),
                items: ThermalPaperSize.values
                    .map(
                      (ps) => DropdownMenuItem(
                        value: ps,
                        child: Text(
                          ps == ThermalPaperSize.mm58 ? '58 mm' : '80 mm',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaperSize = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
