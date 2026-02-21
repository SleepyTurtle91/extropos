import 'package:extropos/services/appwrite_core_service.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

/// Backend Registration Screen
/// Allows backend instances to register themselves with the core system
class BackendRegistrationScreen extends StatefulWidget {
  const BackendRegistrationScreen({super.key});

  @override
  State<BackendRegistrationScreen> createState() =>
      _BackendRegistrationScreenState();
}

class _BackendRegistrationScreenState extends State<BackendRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _endpointController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _endpointController.dispose();
    _projectIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    try {
      final appwriteService = AppwriteService.instance;
      final endpoint = await appwriteService.getEndpoint();
      final projectId = await appwriteService.getProjectId();
      final apiKey = await appwriteService.getApiKey();

      setState(() {
        _endpointController.text = endpoint ?? '';
        _projectIdController.text = projectId ?? '';
        _apiKeyController.text = apiKey ?? '';
        _isLoadingConfig = false;
      });

      // Set default name if not set
      if (_nameController.text.isEmpty) {
        _nameController.text = 'Backend ${DateTime.now().year}';
      }
    } catch (e) {
      setState(() => _isLoadingConfig = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load config: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerBackend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      final backendId = await AppwriteCoreService.instance.registerBackend(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        endpoint: _endpointController.text.trim(),
        projectId: _projectIdController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
      );

      if (backendId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend registered successfully! ID: $backendId'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, backendId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to register backend'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Backend Registration',
      subtitle: 'Cloud backend registration is coming soon for offline POS.',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Backend'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingConfig
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register your backend with the core system to allow POS counters to discover and connect to it.',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Backend Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Main Restaurant, Branch 1, etc.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Backend name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Brief description of this backend',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            const Text(
              'Appwrite Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'Appwrite Endpoint',
                border: OutlineInputBorder(),
                hintText: 'https://cloud.appwrite.io/v1',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Endpoint is required';
                }
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.isAbsolute) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _projectIdController,
              decoration: const InputDecoration(
                labelText: 'Project ID',
                border: OutlineInputBorder(),
                hintText: 'Your Appwrite project ID',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Project ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                hintText: 'Your Appwrite API key',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'API key is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Security Notice',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your API key will be stored securely in the core system. Only registered POS counters will be able to connect to this backend.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _registerBackend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isRegistering
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Register Backend',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
