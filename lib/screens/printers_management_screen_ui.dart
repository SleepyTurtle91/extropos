part of 'printers_management_screen.dart';

extension _PrintersManagementScreenUI on _PrintersManagementScreenState {
  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading printers...'),
                ],
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLeftPanel(isNarrow: true),
                            Expanded(child: _buildRightPanel()),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLeftPanel(isNarrow: false),
                          Expanded(child: _buildRightPanel()),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Color _statusBadgeColor(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.online:
        return const Color(0xFFD1FAE5);
      case PrinterStatus.offline:
        return const Color(0xFFFFE4E6);
      case PrinterStatus.error:
        return const Color(0xFFFFE4E6);
    }
  }

  Color _statusTextColor(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.online:
        return const Color(0xFF047857);
      case PrinterStatus.offline:
        return const Color(0xFFBE123C);
      case PrinterStatus.error:
        return const Color(0xFFBE123C);
    }
  }

  IconData _connectionIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return Icons.wifi;
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.usb:
        return Icons.usb;
      case PrinterConnectionType.posmac:
        return Icons.print;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.print, size: 28, color: Color(0xFF1E293B)),
          const SizedBox(width: 12),
          const Text(
            'Printers Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _addPrinter,
            icon: const Icon(Icons.add),
            label: const Text('Add Printer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel({required bool isNarrow}) {
    return Container(
      width: isNarrow ? double.infinity : 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: isNarrow ? 0 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search/Filter section
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search printers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const Divider(height: 1),
          // Printer list
          Expanded(
            child: printers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No printers yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a printer to get started',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: printers.length,
                    itemBuilder: (context, index) {
                      final printer = printers[index];
                      final isSelected = _selectedPrinterId == printer.id;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedPrinterId = printer.id);
                        },
                        child: Container(
                          color: isSelected
                              ? const Color(0xFFEEF2FF)
                              : Colors.transparent,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _connectionIcon(printer.connectionType),
                                    size: 20,
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      printer.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBadgeColor(printer.status),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  printer.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _statusTextColor(printer.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    final selectedPrinter = _findPrinterById(_selectedPrinterId);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: selectedPrinter == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Select a printer',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a printer from the list to view details',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with printer name and actions
                  Row(
                    children: [
                      Icon(
                        _connectionIcon(selectedPrinter.connectionType),
                        size: 32,
                        color: const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPrinter.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedPrinter.connectionType.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editPrinter(selectedPrinter);
                          } else if (value == 'test') {
                            _testPrint(selectedPrinter);
                          } else if (value == 'delete') {
                            _deletePrinter(selectedPrinter);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'test',
                            child: Text('Test Print'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Printer details
                  _buildDetailRow('Status', selectedPrinter.status.name),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Connection Type',
                    selectedPrinter.connectionType.name,
                  ),
                  const SizedBox(height: 12),
                  if (selectedPrinter.ipAddress != null)
                    _buildDetailRow('IP Address', selectedPrinter.ipAddress!),
                  if (selectedPrinter.port != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Port', selectedPrinter.port.toString()),
                  ],
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Paper Size',
                    selectedPrinter.paperSize?.name ?? 'mm80',
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting
                          ? null
                          : () => _testPrint(selectedPrinter),
                      icon: _isTesting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey[400]!,
                                ),
                              ),
                            )
                          : const Icon(Icons.print),
                      label: Text(
                        _isTesting ? 'Testing...' : 'Test Print',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
