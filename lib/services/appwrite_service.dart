import 'package:appwrite/appwrite.dart';
import 'package:extropos/config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppwriteService {
  static final AppwriteService instance = AppwriteService._internal();
  AppwriteService._internal();

  // Global toggle for offline-only builds
  static bool _enabled = true;

  static void setEnabled(bool enabled) => _enabled = enabled;
  static bool get isEnabled => _enabled;

  Client? _client;
  bool _isInitialized = false;

  static const String _endpointKey = 'appwrite_endpoint';
  static const String _projectIdKey = 'appwrite_project_id';
  static const String _apiKeyKey = 'appwrite_api_key';

  // Getters for configuration
  Future<String?> getEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_endpointKey);
  }

  Future<String?> getProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_projectIdKey);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  // Setters for configuration
  Future<void> setEndpoint(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointKey, endpoint);
  }

  Future<void> setProjectId(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_projectIdKey, projectId);
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  // Initialize Appwrite client
  Future<void> initialize() async {
    if (!_enabled) {
      _isInitialized = false;
      _client = null;
      return;
    }
    // Prefer user-saved values; fall back to build-time environment so web builds work out of the box.
    final endpoint = await getEndpoint() ?? Environment.appwritePublicEndpoint;
    final projectId = await getProjectId() ?? Environment.appwriteProjectId;
    final apiKey = await getApiKey() ?? Environment.appwriteApiKey;

    if (endpoint.isEmpty || projectId.isEmpty) {
      _isInitialized = false;
      return;
    }

    _client = Client().setEndpoint(endpoint).setProject(projectId);

    // Set API key if available (for administrative operations)
    if (apiKey.isNotEmpty) {
      _client!.addHeader('X-Appwrite-Key', apiKey);
    }

    _isInitialized = true;
  }

  // Test connection by pinging a simple API call
  Future<bool> testConnection() async {
    if (!_enabled) return false;
    if (!_isInitialized || _client == null) {
      await initialize();
      if (!_isInitialized || _client == null) {
        return false;
      }
    }

    try {
      // Try to list current account (guest) - this may throw if not permitted
      final account = Account(_client!);
      await account.get();
      return true;
    } catch (e) {
      // If it fails due to auth, connection is still working
      final msg = e.toString().toLowerCase();
      if (msg.contains('unauthorized') || msg.contains('guest')) {
        return true;
      }
      return false;
    }
  }

  // Get client instance (for other services to use)
  Client? get client => _client;

  bool get isInitialized => _isInitialized;

  Databases? get databases {
    if (!_isInitialized || _client == null) return null;
    return Databases(_client!);
  }

  Storage? get storage {
    if (!_isInitialized || _client == null) return null;
    return Storage(_client!);
  }

  Account? get account {
    if (!_isInitialized || _client == null) return null;
    return Account(_client!);
  }

  Functions? get functions {
    if (!_isInitialized || _client == null) return null;
    return Functions(_client!);
  }

  // Clear all settings
  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_endpointKey);
    await prefs.remove(_projectIdKey);
    await prefs.remove(_apiKeyKey);
    _isInitialized = false;
    _client = null;
  }
}
