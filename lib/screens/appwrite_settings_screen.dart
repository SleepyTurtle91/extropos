import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

class AppwriteSettingsScreen extends StatefulWidget {
  const AppwriteSettingsScreen({super.key});

  @override
  State<AppwriteSettingsScreen> createState() => _AppwriteSettingsScreenState();
}

class _AppwriteSettingsScreenState extends State<AppwriteSettingsScreen> {
  final _endpointController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isConnected = false;
  String _connectionStatus = 'Not connected';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _projectIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final endpoint = await AppwriteService.instance.getEndpoint();
    final projectId = await AppwriteService.instance.getProjectId();
    final apiKey = await AppwriteService.instance.getApiKey();

    setState(() {
      // Use credentials from Appwrite configuration
      _endpointController.text = endpoint ?? 'http://127.0.0.1:8080';
      _projectIdController.text = projectId ?? '689965770017299bd5a5';
      _apiKeyController.text =
          apiKey ??
          'standard_efb1a582dc22a5a476b13e2f36fccbbc7c48f88c3cfc8c60cc9c09a2ba49a2cacc644ecdd91ef618368804ac5db846d05f831e42b5c46d145faa682d2dfbe1e33ada0bba8b37548f8109ee504f86e7b89d672d15fa74fc8de7da580f1961e2a9acdedfccb38125bc9c506075ee9e1dde5678a5e6fd7fc107b1f3d6bae37b4456';
    });

    // Check connection status
    await _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing connection...';
    });

    try {
      final isConnected = await AppwriteService.instance.testConnection();
      setState(() {
        _isConnected = isConnected;
        _connectionStatus = isConnected ? 'Connected' : 'Connection failed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final endpoint = _endpointController.text.trim();
    final projectId = _projectIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (endpoint.isEmpty || projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in endpoint and project ID')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AppwriteService.instance.setEndpoint(endpoint);
      await AppwriteService.instance.setProjectId(projectId);
      if (apiKey.isNotEmpty) await AppwriteService.instance.setApiKey(apiKey);

      // Reinitialize the service with new settings
      await AppwriteService.instance.initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }

      // Test connection with new settings
      await _checkConnection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Appwrite Settings',
      subtitle: 'Cloud settings are coming soon for offline POS.',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appwrite Integration'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Connection Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        color: _isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _checkConnection,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _isLoading ? 'Testing...' : 'Test Connection',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Configuration Section
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Endpoint
            TextFormField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'Appwrite Endpoint',
                hintText: 'https://cloud.appwrite.io/v1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Project ID
            TextFormField(
              controller: _projectIdController,
              decoration: const InputDecoration(
                labelText: 'Project ID',
                hintText: 'Your Appwrite project ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // API Key
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Your Appwrite API key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSettings,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Information Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to get your Appwrite credentials:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Go to your Appwrite Console',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                    Text(
                      '2. Select your project',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                    Text(
                      '3. Go to Settings → General to get Project ID',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                    Text(
                      '4. Go to Settings → API Keys to create an API key',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                    Text(
                      '5. Use your Appwrite endpoint URL',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
