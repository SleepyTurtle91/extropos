part of 'p2p_management_screen.dart';

extension P2PManagementSections on _P2PManagementScreenState {
  Widget buildServiceStatusCard() {
    final isInitialized = _p2pService.isInitialized;
    final isRunning = _p2pService.isRunning;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRunning ? Icons.check_circle : Icons.info_outline,
                  color: isRunning ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRunning
                            ? 'P2P service is active and ready'
                            : isInitialized
                                ? 'Initialized but not running'
                                : 'Not initialized',
                        style: TextStyle(
                          color: isRunning ? Colors.green : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isRunning) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: buildStatusItem(
                      'Connected Devices',
                      '${_connectedDevices.length}',
                      Icons.devices,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: buildStatusItem(
                      'Messages',
                      '${_messageLog.length}',
                      Icons.message,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildStatusItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInitializationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Initialize P2P Service',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure your device as a P2P server or client',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'e.g., Main POS, Kitchen Display',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.device_hub),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<P2PDeviceType>(
              value: _selectedDeviceType,
              decoration: const InputDecoration(
                labelText: 'Device Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: P2PDeviceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20, color: type.statusColor),
                      const SizedBox(width: 12),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDeviceType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customPortController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Port (Optional)',
                hintText: '8766',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: initializeP2P,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Initialize & Start Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDeviceInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            buildInfoRow('Device Name', _p2pService.deviceName),
            const SizedBox(height: 8),
            buildInfoRow('Device ID', _p2pService.deviceId),
            const SizedBox(height: 8),
            buildInfoRow('Device Type', _p2pService.deviceType.displayName),
            const SizedBox(height: 8),
            buildInfoRow('Port', LocalNetworkP2PService.dataPort.toString()),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget buildControlButtonsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: buildDiscoverButton(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildStopButton(),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    buildDiscoverButton(),
                    const SizedBox(height: 12),
                    buildStopButton(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDiscoverButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _p2pService.isRunning ? discoverDevices : null,
        icon: const Icon(Icons.search),
        label: const Text('Discover Devices'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget buildStopButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _p2pService.isRunning ? stopP2P : null,
        icon: const Icon(Icons.stop),
        label: const Text('Stop Service'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

}
