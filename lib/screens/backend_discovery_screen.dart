import 'package:extropos/services/appwrite_core_service.dart';
import 'package:extropos/services/license_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

/// Backend Discovery Screen
/// Allows POS counters to discover and connect to available backends
class BackendDiscoveryScreen extends StatefulWidget {
  const BackendDiscoveryScreen({super.key});

  @override
  State<BackendDiscoveryScreen> createState() => _BackendDiscoveryScreenState();
}

class _BackendDiscoveryScreenState extends State<BackendDiscoveryScreen> {
  final List<Map<String, dynamic>> _backends = [];
  bool _isLoading = true;
  String? _connectingBackendId;

  final TextEditingController _counterNameController = TextEditingController();
  final TextEditingController _counterDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBackends();
    _counterNameController.text =
        'Counter ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  @override
  void dispose() {
    _counterNameController.dispose();
    _counterDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadBackends() async {
    setState(() => _isLoading = true);
    try {
      final backends = await AppwriteCoreService.instance.discoverBackends();
      setState(() {
        _backends.clear();
        _backends.addAll(backends);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load backends: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectToBackend(String backendId, String backendName) async {
    if (_counterNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a counter name')),
      );
      return;
    }

    setState(() {
      _connectingBackendId = backendId;
    });

    try {
      final connectionDetails = await AppwriteCoreService.instance
          .connectToBackend(
            backendId: backendId,
            counterName: _counterNameController.text.trim(),
            counterDescription: _counterDescriptionController.text.trim(),
          );

      if (connectionDetails != null && mounted) {
        // Integrate with license service for tenant activation
        try {
          await _activateWithTenantCredentials(connectionDetails);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected to $backendName'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return success
        } catch (licenseError) {
          // Connection succeeded but license activation failed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Connected but license activation failed: $licenseError',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to backend'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _connectingBackendId = null;
        });
      }
    }
  }

  /// Activate license with tenant credentials from successful backend connection
  Future<void> _activateWithTenantCredentials(
    Map<String, String> connectionDetails,
  ) async {
    final licenseService = LicenseService.instance;
    if (!licenseService.isInited) {
      await licenseService.init();
    }

    await licenseService.activateWithTenant(
      tenantId: connectionDetails['tenantId']!,
      endpoint: connectionDetails['endpoint']!,
      apiKey: connectionDetails['apiKey']!,
      counterId: connectionDetails['counterId']!,
    );
  }

  void _showConnectionDialog(Map<String, dynamic> backend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to ${backend['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                backend['description'] ?? 'No description available',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _counterNameController,
                decoration: const InputDecoration(
                  labelText: 'Counter Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Counter 1, Main POS, etc.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Counter name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _counterDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Main counter, Drive-thru, etc.',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will register your POS as a counter with this backend. You can manage orders and access shared data.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToBackend(backend['id'], backend['name']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Backend Discovery',
      subtitle: 'Cloud backend discovery is coming soon for offline POS.',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Backends'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackends,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_backends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Backends Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No active backends are currently available',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBackends,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _backends.length,
      itemBuilder: (context, index) {
        final backend = _backends[index];
        final isConnecting = _connectingBackendId == backend['id'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud, color: Color(0xFF2563EB)),
            ),
            title: Text(
              backend['name'] ?? 'Unknown Backend',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(backend['description'] ?? 'No description'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: backend['status'] == 'active'
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      backend['status'] == 'active' ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: backend['status'] == 'active'
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton(
                    onPressed: isConnecting
                        ? null
                        : () => _showConnectionDialog(backend),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Connect'),
                  ),
          ),
        );
      },
    );
  }
}
