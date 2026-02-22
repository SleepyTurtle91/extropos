import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:flutter/material.dart';

/// Widget for displaying a P2P device status badge
class P2PDeviceStatusBadge extends StatelessWidget {
  final P2PDevice device;
  final VoidCallback? onTap;
  final bool showDetails;

  const P2PDeviceStatusBadge({
    super.key,
    required this.device,
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: device.connectionStatus.color.withAlpha(30),
          border: Border.all(
            color: device.connectionStatus.color,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              device.deviceType.icon,
              size: 18,
              color: device.deviceType.statusColor,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (showDetails)
                  Text(
                    device.connectionStatus.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: device.connectionStatus.color,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: device.connectionStatus == P2PConnectionStatus.connected
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying connected devices list
class P2PConnectedDevicesPanel extends StatelessWidget {
  final List<P2PDevice> devices;
  final VoidCallback? onRefresh;
  final Function(P2PDevice)? onDeviceSelected;

  const P2PConnectedDevicesPanel({
    super.key,
    required this.devices,
    this.onRefresh,
    this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final connectedDevices =
        devices.where((d) => d.connectionStatus == P2PConnectionStatus.connected).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connected Devices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${connectedDevices.length} connected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                  ),
              ],
            ),
          ),
          if (connectedDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No devices connected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: connectedDevices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = connectedDevices[index];
                return ListTile(
                  leading: Icon(
                    device.deviceType.icon,
                    color: device.deviceType.statusColor,
                  ),
                  title: Text(device.displayTitle),
                  subtitle: Text('${device.ipAddress}:${device.port}'),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Connected'),
                      ],
                    ),
                  ),
                  onTap: () => onDeviceSelected?.call(device),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Widget for P2P device discovery dialog
class P2PDeviceDiscoveryDialog extends StatefulWidget {
  final LocalNetworkP2PService p2pService;
  final Function(P2PDevice)? onDeviceSelected;

  const P2PDeviceDiscoveryDialog({
    super.key,
    required this.p2pService,
    this.onDeviceSelected,
  });

  @override
  State<P2PDeviceDiscoveryDialog> createState() => _P2PDeviceDiscoveryDialogState();
}

class _P2PDeviceDiscoveryDialogState extends State<P2PDeviceDiscoveryDialog> {
  late Future<List<P2PDevice>> _discoveryFuture;

  @override
  void initState() {
    super.initState();
    _discoveryFuture = widget.p2pService.discoverDevices();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Discover Devices'),
      content: SizedBox(
        width: 400,
        child: FutureBuilder<List<P2PDevice>>(
          future: _discoveryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Discovering devices on network...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Discovery failed: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final devices = snapshot.data ?? [];

            if (devices.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No devices found on network'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: Icon(device.deviceType.icon),
                  title: Text(device.displayTitle),
                  subtitle: Text('${device.ipAddress}:${device.port}'),
                  onTap: () {
                    widget.onDeviceSelected?.call(device);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _discoveryFuture = widget.p2pService.discoverDevices();
            });
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

/// Widget for P2P connection manager in settings/menu
class P2PConnectionManager extends StatefulWidget {
  final LocalNetworkP2PService p2pService;

  const P2PConnectionManager({
    super.key,
    required this.p2pService,
  });

  @override
  State<P2PConnectionManager> createState() => _P2PConnectionManagerState();
}

class _P2PConnectionManagerState extends State<P2PConnectionManager> {
  late Stream<P2PDevice> _deviceStream;

  @override
  void initState() {
    super.initState();
    _deviceStream = widget.p2pService.deviceStream;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'P2P Network Manager',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Device: ${widget.p2pService.deviceName} (${widget.p2pService.deviceType.displayName})',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.p2pService.isRunning ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.p2pService.isRunning ? 'Running' : 'Not running'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Connected devices
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Connected Devices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.p2pService.isRunning
                          ? () => _showDiscoveryDialog()
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Discover'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<P2PDevice>(
                  stream: _deviceStream,
                  builder: (context, snapshot) {
                    return P2PConnectedDevicesPanel(
                      devices: widget.p2pService.connectedDevices,
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: widget.p2pService.isRunning
                      ? null
                      : () => _startService(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Service'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: widget.p2pService.isRunning
                      ? () => _stopService()
                      : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscoveryDialog() {
    showDialog(
      context: context,
      builder: (context) => P2PDeviceDiscoveryDialog(
        p2pService: widget.p2pService,
        onDeviceSelected: (device) async {
          final success = await widget.p2pService.connectToDevice(device);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Connected to ${device.deviceName}'
                      : 'Failed to connect to ${device.deviceName}',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _startService() async {
    try {
      await widget.p2pService.start();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('P2P Service started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopService() async {
    try {
      await widget.p2pService.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('P2P Service stopped'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
