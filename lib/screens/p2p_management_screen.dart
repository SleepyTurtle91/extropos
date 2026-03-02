import 'dart:async';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_message_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'p2p_management_operations.dart';
part 'p2p_management_sections.dart';
part 'p2p_management_devices_log.dart';

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
    loadCurrentStatus();
    setupListeners();
  }

  @override
  void dispose() {
    _deviceStreamSubscription?.cancel();
    _messageStreamSubscription?.cancel();
    _deviceNameController.dispose();
    _customPortController.dispose();
    super.dispose();
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
                    buildServiceStatusCard(),
                    const SizedBox(height: 16),
                    if (!_p2pService.isInitialized) ...[
                      buildInitializationCard(),
                    ] else ...[
                      buildDeviceInfoCard(),
                      const SizedBox(height: 16),
                      buildControlButtonsCard(),
                      const SizedBox(height: 16),
                      buildConnectedDevicesCard(),
                      const SizedBox(height: 16),
                      buildMessageLogCard(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
