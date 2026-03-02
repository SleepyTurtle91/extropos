part of '../../printers_management_screen_widgets.dart';

extension PrintersManagementWidget_Header on _PrintersManagementScreenState {
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Printer Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Configure receipt and kitchen printers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Search Bluetooth Printers',
                icon: const Icon(Icons.bluetooth_searching),
                onPressed: _isLoading ? null : _searchBluetoothPrinters,
              ),
              IconButton(
                tooltip: 'Search USB Printers',
                icon: const Icon(Icons.usb),
                onPressed: _isLoading ? null : _searchUsbPrinters,
              ),
              IconButton(
                tooltip: 'Discover Printers',
                icon: const Icon(Icons.search),
                onPressed: _isLoading ? null : _discoverPrintersAsync,
              ),
              IconButton(
                tooltip: 'Refresh All Printers',
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _loadPrinters,
              ),
              IconButton(
                tooltip: 'Print via ESCPrint Service',
                icon: const Icon(Icons.outgoing_mail),
                onPressed: _isLoading ? null : _printViaExternalServiceTest,
              ),
              IconButton(
                tooltip: 'Open debug console',
                icon: const Icon(Icons.bug_report),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrinterDebugConsole(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addPrinter,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Printer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
