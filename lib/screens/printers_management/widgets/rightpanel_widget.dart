part of '../../printers_management_screen_widgets.dart';

extension PrintersManagementWidget_Rightpanel on _PrintersManagementScreenState {
  Widget _buildRightPanel() {
    final selectedPrinter = _selectedPrinter;
    if (selectedPrinter == null) {
      return const Center(child: Text('Select a printer to configure.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPrinter.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Device ID: ${selectedPrinter.id.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: (_isTesting ||
                            selectedPrinter.status == PrinterStatus.offline)
                        ? null
                        : _handleTestPrint,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print, size: 18),
                    label: Text(_isTesting ? 'Printing...' : 'Test Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Connection Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRINTER NAME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: ValueKey('${selectedPrinter.id}_name'),
                                initialValue: selectedPrinter.name,
                                onChanged: (value) =>
                                    _updatePrinterField(name: value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                decoration: _inputDecoration(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PAPER SIZE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildToggleBtn(
                                        '80mm',
                                        '80mm',
                                        selectedPrinter.paperSize !=
                                            ThermalPaperSize.mm58,
                                        (value) => _updatePrinterField(
                                          paperSize: ThermalPaperSize.mm80,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildToggleBtn(
                                        '58mm',
                                        '58mm',
                                        selectedPrinter.paperSize ==
                                            ThermalPaperSize.mm58,
                                        (value) => _updatePrinterField(
                                          paperSize: ThermalPaperSize.mm58,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'CONNECTION TYPE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'network',
                            'Network / LAN',
                            Icons.wifi,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.network,
                            () => _updatePrinterField(
                              connectionType: PrinterConnectionType.network,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'bluetooth',
                            'Bluetooth',
                            Icons.bluetooth,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.bluetooth,
                            () => _updatePrinterField(
                              connectionType:
                                  PrinterConnectionType.bluetooth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'usb',
                            'USB Direct',
                            Icons.usb,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.usb,
                            () => _updatePrinterField(
                              connectionType: PrinterConnectionType.usb,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTypeSelectBtn(
                            'posmac',
                            'POSMAC',
                            Icons.print,
                            selectedPrinter.connectionType ==
                                PrinterConnectionType.posmac,
                            () => _updatePrinterField(
                              connectionType: PrinterConnectionType.posmac,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      selectedPrinter.connectionType ==
                              PrinterConnectionType.network
                          ? 'IP ADDRESS'
                          : selectedPrinter.connectionType ==
                                  PrinterConnectionType.bluetooth
                              ? 'MAC ADDRESS'
                              : selectedPrinter.connectionType ==
                                      PrinterConnectionType.posmac
                                  ? 'DEVICE ID'
                                  : 'USB PORT',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey('${selectedPrinter.id}_addr'),
                      initialValue: _connectionAddress(selectedPrinter),
                      onChanged: (value) =>
                          _updatePrinterField(address: value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                      decoration: _inputDecoration(),
                    ),
                    if (selectedPrinter.connectionType ==
                        PrinterConnectionType.network) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'PORT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey('${selectedPrinter.id}_port'),
                        initialValue:
                            (selectedPrinter.port ?? 9100).toString(),
                        onChanged: (value) => _updatePrinterField(
                          port: int.tryParse(value) ?? 9100,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                        decoration: _inputDecoration(),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Print Assignments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildJobToggle(
                      title: 'Customer Receipts',
                      description:
                          'Print final bills and customer receipts upon payment.',
                      icon: Icons.receipt_long,
                      isActive: selectedPrinter.type == PrinterType.receipt,
                      onToggle: () => _updatePrinterField(
                        type: PrinterType.receipt,
                        categories: const [],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildJobToggle(
                      title: 'Kitchen Order Tickets (KOT)',
                      description:
                          'Send food and beverage orders directly to the kitchen.',
                      icon: Icons.restaurant_menu,
                      isActive: selectedPrinter.type == PrinterType.kitchen,
                      onToggle: () => _updatePrinterField(
                        type: PrinterType.kitchen,
                      ),
                      expandedContent:
                          selectedPrinter.type == PrinterType.kitchen
                              ? _buildKitchenCategories(selectedPrinter)
                              : null,
                    ),
                    const SizedBox(height: 16),
                    _buildJobToggle(
                      title: 'Bar Tickets',
                      description:
                          'Print beverage orders to the bar station printer.',
                      icon: Icons.local_bar,
                      isActive: selectedPrinter.type == PrinterType.bar,
                      onToggle: () => _updatePrinterField(
                        type: PrinterType.bar,
                      ),
                      expandedContent: selectedPrinter.type == PrinterType.bar
                          ? _buildKitchenCategories(selectedPrinter)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _deletePrinter(selectedPrinter),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove Printer'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF43F5E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await DatabaseService.instance
                          .savePrinter(selectedPrinter);
                      if (!mounted) return;
                      ToastHelper.showToast(
                        context,
                        'Configuration saved for ${selectedPrinter.name}',
                      );
                      await _loadPrinters();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Configuration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
