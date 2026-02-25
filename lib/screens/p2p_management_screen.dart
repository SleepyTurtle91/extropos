import 'dart:async';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_message_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// P2P Management Screen for server/client setup and device management
class P2PManagementScreen extends StatefulWidget {
  const P2PManagementScreen({super.key});

  @override
  State<P2PManagementScreen> createState() => _P2PManagementScreenState();
}

class _P2PManagementScreenState extends State<P2PManagementScreen> {
  final LocalNetworkP2PService _p2pService = LocalNetworkP2PService();
  
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _deviceStreamSubscription;
  StreamSubscription? _messageStreamSubscription;
  
  // Form fields
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _customPortController = TextEditingController();
  P2PDeviceType _selectedDeviceType = P2PDeviceType.mainPOS;
  
  List<P2PDevice> _connectedDevices = [];
  final List<String> _messageLog = [];

  @override
  void initState() {
    super.initState();
    _deviceNameController.text = 'POS Terminal';
    _customPortController.text = '8766';
    _loadCurrentStatus();
    _setupListeners();
  }

  @override
  void dispose() {
    _deviceStreamSubscription?.cancel();
    _messageStreamSubscription?.cancel();
    _deviceNameController.dispose();
    _customPortController.dispose();
    super.dispose();
  }

  void _loadCurrentStatus() {
    if (_p2pService.isInitialized) {
      setState(() {
        _deviceNameController.text = _p2pService.deviceName;
        _selectedDeviceType = _p2pService.deviceType;
        _connectedDevices = _p2pService.connectedDevices;
      });
    }
  }

  void _setupListeners() {
    _deviceStreamSubscription = _p2pService.deviceStream.listen((device) {
      setState(() {
        _connectedDevices = _p2pService.connectedDevices;
        _addToMessageLog('Device ${device.connectionStatus == P2PConnectionStatus.connected ? "connected" : "discovered"}: ${device.deviceName}');
      });
    });

    _messageStreamSubscription = _p2pService.messageStream.listen((message) {
      _addToMessageLog('Message received: ${message.messageType.value} from ${message.fromDeviceId}');
    });
  }

  void _addToMessageLog(String message) {
    setState(() {
      _messageLog.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_messageLog.length > 50) {
        _messageLog.removeLast();
      }
    });
  }

  Future<void> _initializeP2P() async {
    if (_deviceNameController.text.isEmpty) {
      _showError('Please enter a device name');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final port = int.tryParse(_customPortController.text);
      
      await _p2pService.initialize(
        deviceName: _deviceNameController.text,
        deviceType: _selectedDeviceType,
        customPort: port,
      );

      await _p2pService.start();

      _addToMessageLog('P2P Service initialized successfully');
      _addToMessageLog('Device ID: ${_p2pService.deviceId}');
      _addToMessageLog('Device Type: ${_selectedDeviceType.displayName}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('P2P Service started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to initialize P2P: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopP2P() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _p2pService.stop();
      _addToMessageLog('P2P Service stopped');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('P2P Service stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _connectedDevices.clear();
      });
    } catch (e) {
      _showError('Failed to stop P2P: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _discoverDevices() async {
    if (!_p2pService.isRunning) {
      _showError('P2P Service must be running to discover devices');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _addToMessageLog('Starting device discovery...');
      final devices = await _p2pService.discoverDevices();
      
      _addToMessageLog('Discovery completed. Found ${devices.length} devices');
      
      setState(() {
        _connectedDevices = devices;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${devices.length} devices'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to discover devices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(P2PDevice device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addToMessageLog('Connecting to ${device.deviceName}...');
      final success = await _p2pService.connectToDevice(device);
      
      if (success) {
        _addToMessageLog('Successfully connected to ${device.deviceName}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.deviceName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('Failed to connect to ${device.deviceName}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError('Connection error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _addToMessageLog('ERROR: $message');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Network Management'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          if (_p2pService.isRunning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Running',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceStatusCard(),
                    const SizedBox(height: 16),
                    if (!_p2pService.isInitialized) ...[
                      _buildInitializationCard(),
                    ] else ...[
                      _buildDeviceInfoCard(),
                      const SizedBox(height: 16),
                      _buildControlButtonsCard(),
                      const SizedBox(height: 16),
                      _buildConnectedDevicesCard(),
                      const SizedBox(height: 16),
                      _buildMessageLogCard(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServiceStatusCard() {
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
                    child: _buildStatusItem(
                      'Connected Devices',
                      '${_connectedDevices.length}',
                      Icons.devices,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatusItem(
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

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildInitializationCard() {
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
                onPressed: _initializeP2P,
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

  Widget _buildDeviceInfoCard() {
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
            _buildInfoRow('Device Name', _p2pService.deviceName),
            const SizedBox(height: 8),
            _buildInfoRow('Device ID', _p2pService.deviceId),
            const SizedBox(height: 8),
            _buildInfoRow('Device Type', _p2pService.deviceType.displayName),
            const SizedBox(height: 8),
            _buildInfoRow('Port', LocalNetworkP2PService.dataPort.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildControlButtonsCard() {
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
                        child: _buildDiscoverButton(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStopButton(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildDiscoverButton(),
                      const SizedBox(height: 12),
                      _buildStopButton(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _p2pService.isRunning ? _discoverDevices : null,
        icon: const Icon(Icons.search),
        label: const Text('Discover Devices'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _p2pService.isRunning ? _stopP2P : null,
        icon: const Icon(Icons.stop),
        label: const Text('Stop Service'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildConnectedDevicesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connected Devices',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_connectedDevices.length} devices',
                  style: TextStyle(
                    color: _connectedDevices.isEmpty ? Colors.grey : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_connectedDevices.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No devices connected',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Click "Discover Devices" to find devices on your network',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _connectedDevices.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final device = _connectedDevices[index];
                  return ListTile(
                    leading: Icon(
                      device.deviceType.icon,
                      color: device.deviceType.statusColor,
                      size: 32,
                    ),
                    title: Text(
                      device.deviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${device.ipAddress}:${device.port}'),
                        Text(
                          device.deviceType.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: device.deviceType.statusColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: device.connectionStatus == P2PConnectionStatus.connected
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          device.connectionStatus.displayName,
                          style: TextStyle(
                            color: device.connectionStatus == P2PConnectionStatus.connected
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (device.connectionStatus != P2PConnectionStatus.connected) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.link, size: 20),
                            onPressed: () => _connectToDevice(device),
                            tooltip: 'Connect',
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageLogCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Log',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _messageLog.isEmpty ? null : () {
                    setState(() {
                      _messageLog.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withAlpha(50)),
              ),
              child: _messageLog.isEmpty
                  ? const Center(
                      child: Text(
                        'No activity yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      reverse: false,
                      itemCount: _messageLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            _messageLog[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
