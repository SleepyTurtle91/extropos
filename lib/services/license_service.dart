// ignore_for_file: unused_field

import 'package:appwrite/appwrite.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:extropos/config/environment.dart';
import 'package:extropos/models/activation_mode.dart';
import 'package:extropos/services/license_key_generator.dart';
import 'package:extropos/services/tenant_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

class LicenseService {
  static final LicenseService instance = LicenseService._internal();
  LicenseService._internal();

  static const _keyInstallDate = 'installDate';
  static const _keyActivated = 'isActivated';
  static const _keyLicenseKey = 'licenseKey';
  static const _keyActivationMode = 'activationMode';
  static const _keyTenantId = 'tenantId';
  static const _keyTenantEndpoint = 'tenantEndpoint';
  static const _keyTenantApiKey = 'tenantApiKey';
  static const _keyCounterId = 'counterId';
  static const _keyBoundEmail = 'boundEmail';

  SharedPreferences? _prefs;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Global Appwrite Client for License Management
  late Client _globalClient;
  late Databases _globalDatabases;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    _globalClient = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId); // Global Project
    _globalDatabases = Databases(_globalClient);
  }

  bool get isInited => _prefs != null;

  /// Ensure installDate exists (set on first-run)
  Future<void> initializeIfNeeded() async {
    if (_prefs == null) await init();
    if (!_prefs!.containsKey(_keyInstallDate)) {
      await _prefs!.setString(
        _keyInstallDate,
        DateTime.now().toIso8601String(),
      );
      await _prefs!.setBool(_keyActivated, false);
    }
  }

  bool get isActivated => _prefs?.getBool(_keyActivated) ?? false;

  String get licenseKey => _prefs?.getString(_keyLicenseKey) ?? '';
  String get boundEmail => _prefs?.getString(_keyBoundEmail) ?? '';

  ActivationMode get activationMode {
    final mode = _prefs?.getString(_keyActivationMode) ?? 'offline';
    return mode == 'tenant' ? ActivationMode.tenant : ActivationMode.offline;
  }

  String get tenantId => _prefs?.getString(_keyTenantId) ?? '';
  String get tenantEndpoint => _prefs?.getString(_keyTenantEndpoint) ?? '';
  String get tenantApiKey => _prefs?.getString(_keyTenantApiKey) ?? '';
  String get counterId => _prefs?.getString(_keyCounterId) ?? '';

  bool get isTenantActivated =>
      activationMode == ActivationMode.tenant && isActivated;

  DateTime? get installDate {
    final v = _prefs?.getString(_keyInstallDate);
    if (v == null) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  int get daysUsed {
    final d = installDate;
    if (d == null) return 0;
    return DateTime.now().difference(d).inDays;
  }

  int get daysLeft {
    if (isActivated && licenseKey.isNotEmpty) {
      if (licenseKey.startsWith('IAP-')) return 999999;
      final daysRemaining = LicenseKeyGenerator.getDaysRemaining(licenseKey);
      if (daysRemaining == null) return 999999; 
      return daysRemaining;
    }
    return 90 - daysUsed; 
  }

  bool get isExpired {
    if (isActivated && licenseKey.isNotEmpty) {
      if (licenseKey.startsWith('IAP-')) return false;
      return LicenseKeyGenerator.isExpired(licenseKey);
    }
    return !isActivated && daysLeft <= 0;
  }
  
  // --- Device Binding Logic ---

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // unique ID
    } else if (Platform.isWindows) {
      final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    }
    return 'unknown_device';
  }
  
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account?.email;
    } catch (error) {
       if (kDebugMode) print('Google Sign In Error: $error');
      return null;
    }
  }

  Future<void> activateViaIAP({required String purchaseToken, required bool isLifetime}) async {
    if (_prefs == null) await init();
    
    if (isLifetime) {
        // 1. Get Device Info
        final deviceId = await getDeviceId();
        
        // 2. Optional: Get Email
        String? email = await signInWithGoogle();
        
        // 3. Bind to Cloud
        await _bindLicenseToCloud(purchaseToken, deviceId, email);

        // 4. Save Local State
        await _prefs!.setBool(_keyActivated, true);
        await _prefs!.setString(_keyLicenseKey, 'IAP-$purchaseToken');
        await _prefs!.setString(_keyActivationMode, 'offline');
        if (email != null) {
          await _prefs!.setString(_keyBoundEmail, email);
        }
    } else {
        // Cloud Subscription
         await _prefs!.setBool(_keyActivated, true);
         await _prefs!.setString(_keyLicenseKey, 'IAP-SUBS-$purchaseToken');
         // We keep it 'offline' initially. The user must manually 'Connect to Tenant' 
         // using the credentials provided by the admin/email after purchase.
         await _prefs!.setString(_keyActivationMode, 'offline'); 
    }
  }
  
  Future<void> _bindLicenseToCloud(String token, String deviceId, String? email) async {
    try {
      // Check if license exists
      final result = await _globalDatabases.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: Environment.licensesCollection,
        queries: [
          Query.equal('license_key', token),
        ],
      );

      if (result.documents.isNotEmpty) {
        // License exists, verify binding
        final existing = result.documents.first;
        final boundDevice = existing.data['device_id'];
        
        if (boundDevice != deviceId) {
          throw Exception('License is already bound to another device ($boundDevice). Please unbind it first.');
        }
        // If match, all good. Update email if missing?
      } else {
        // Create new binding
        await _globalDatabases.createDocument(
          databaseId: Environment.posDatabase,
          collectionId: Environment.licensesCollection,
          documentId: ID.unique(),
          data: {
            'license_key': token,
            'device_id': deviceId,
            'email': email,
            'activated_at': DateTime.now().toIso8601String(),
            'is_active': true,
          }
        );
      }
    } catch (e) {
      if (e is AppwriteException && e.code == 404) {
         // Collection might not exist yet, treat as network error or server setup issue
         rethrow;
      }
      if (e.toString().contains('already bound')) rethrow;
      rethrow; 
    }
  }
  
  Future<void> unbindDevice() async {
    if (!licenseKey.startsWith('IAP-')) return; 
    
    final token = licenseKey.replaceFirst('IAP-', '');
    if (token.startsWith('SUBS-')) return; // Subscriptions handled by play store
    
    try {
       final result = await _globalDatabases.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: Environment.licensesCollection,
        queries: [
          Query.equal('license_key', token),
        ],
      );
      
      if (result.documents.isNotEmpty) {
        await _globalDatabases.deleteDocument(
          databaseId: Environment.posDatabase,
          collectionId: Environment.licensesCollection,
          documentId: result.documents.first.$id,
        );
      }
      
      // Clear local
      await _prefs!.remove(_keyLicenseKey);
      await _prefs!.setBool(_keyActivated, false);
      await _prefs!.remove(_keyBoundEmail);
      
    } catch (e) {
      throw Exception('Failed to unbind: $e');
    }
  }


  /// Validate and activate with generated license key (offline mode)
  Future<void> activate(String key) async {
    if (_prefs == null) await init();

    // Validate using the key generator
    if (LicenseKeyGenerator.validateKey(key)) {
      await _prefs!.setBool(_keyActivated, true);
      await _prefs!.setString(_keyLicenseKey, key.trim());
      await _prefs!.setString(_keyActivationMode, 'offline');
    } else {
      throw Exception('Invalid license key');
    }
  }
  
  /// Activate with tenant credentials (cloud mode)
  Future<void> activateWithTenant({
    required String tenantId,
    required String endpoint,
    required String apiKey,
    String? counterId,
  }) async {
    if (_prefs == null) await init();

    // Basic validation
    if (tenantId.isEmpty || endpoint.isEmpty || apiKey.isEmpty) {
      throw Exception('All tenant credentials are required');
    }

    // Test the connection using TenantService
    final tenantService = TenantService.instance;
    await tenantService.initializeWithCredentials(
      endpoint.trim(),
      apiKey.trim(),
      tenantId.trim(),
    );
    final connectionTest = await tenantService.testConnection();
    if (!connectionTest) {
      throw Exception(
        'Failed to connect to tenant database. Please check your credentials.',
      );
    }
    await _prefs!.setBool(_keyActivated, true);
    await _prefs!.setString(_keyActivationMode, 'tenant');
    await _prefs!.setString(_keyTenantId, tenantId.trim());
    await _prefs!.setString(_keyTenantEndpoint, endpoint.trim());
    await _prefs!.setString(_keyTenantApiKey, apiKey.trim());
    if (counterId != null) {
      await _prefs!.setString(_keyCounterId, counterId.trim());
    }
  }

  Future<void> setCounterId(String counterId) async {
    if (_prefs == null) await init();
    await _prefs!.setString(_keyCounterId, counterId.trim());
  }

  /// Extract tenant ID from counter ID
  /// Counter ID format: TENANT-{backendId}-{deviceId}-{timestamp}
  String? getTenantIdFromCounterId(String counterId) {
    if (!counterId.startsWith('TENANT-')) return null;

    final parts = counterId.split('-');
    if (parts.length < 2) return null;

    // Extract the backendId part (second component after TENANT-)
    return parts[1];
  }

  /// Get the full tenant ID for this counter
  String? get currentTenantId {
    final counterId = this.counterId;
    if (counterId.isEmpty) return null;
    return getTenantIdFromCounterId(counterId);
  }
}
