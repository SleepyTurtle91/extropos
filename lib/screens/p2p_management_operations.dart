part of 'p2p_management_screen.dart';

extension P2PManagementOperations on _P2PManagementScreenState {
  void loadCurrentStatus() {
    if (_p2pService.isInitialized) {
      setState(() {
        _deviceNameController.text = _p2pService.deviceName;
        _selectedDeviceType = _p2pService.deviceType;
        _connectedDevices = _p2pService.connectedDevices;
      });
    }
  }

  void setupListeners() {
    _deviceStreamSubscription = _p2pService.deviceStream.listen((device) {
      setState(() {
        _connectedDevices = _p2pService.connectedDevices;
        addToMessageLog(
          'Device ${device.connectionStatus == P2PConnectionStatus.connected ? "connected" : "discovered"}: ${device.deviceName}',
        );
      });
    });

    _messageStreamSubscription = _p2pService.messageStream.listen((message) {
      addToMessageLog(
        'Message received: ${message.messageType.value} from ${message.fromDeviceId}',
      );
    });
  }

  void addToMessageLog(String message) {
    setState(() {
      _messageLog.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_messageLog.length > 50) {
        _messageLog.removeLast();
      }
    });
  }

  Future<void> initializeP2P() async {
    if (_deviceNameController.text.isEmpty) {
      showError('Please enter a device name');
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

      addToMessageLog('P2P Service initialized successfully');
      addToMessageLog('Device ID: ${_p2pService.deviceId}');
      addToMessageLog('Device Type: ${_selectedDeviceType.displayName}');

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
      showError('Failed to initialize P2P: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> stopP2P() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _p2pService.stop();
      addToMessageLog('P2P Service stopped');

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
      showError('Failed to stop P2P: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> discoverDevices() async {
    if (!_p2pService.isRunning) {
      showError('P2P Service must be running to discover devices');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      addToMessageLog('Starting device discovery...');
      final devices = await _p2pService.discoverDevices();

      addToMessageLog('Discovery completed. Found ${devices.length} devices');

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
      showError('Failed to discover devices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> connectToDevice(P2PDevice device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      addToMessageLog('Connecting to ${device.deviceName}...');
      final success = await _p2pService.connectToDevice(device);

      if (success) {
        addToMessageLog('Successfully connected to ${device.deviceName}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.deviceName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        showError('Failed to connect to ${device.deviceName}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      showError('Connection error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    addToMessageLog('ERROR: $message');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
