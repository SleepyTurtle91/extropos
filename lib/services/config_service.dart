import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static final ConfigService instance = ConfigService._init();
  ConfigService._init();

  SharedPreferences? _prefs;

  static const _keyIsSetupDone = 'app_is_setup_done';
  static const _keyStoreName = 'app_store_name';
  static const _keyTerminalId = 'app_terminal_id';
  static const _keySyncMode = 'app_sync_mode';
  static const _keyBusinessType = 'app_business_type';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isInited => _prefs != null;

  bool get isSetupDone => _prefs?.getBool(_keyIsSetupDone) ?? false;

  String get storeName => _prefs?.getString(_keyStoreName) ?? '';

  String get terminalId => _prefs?.getString(_keyTerminalId) ?? 'TERM-01';

  String get syncMode => _prefs?.getString(_keySyncMode) ?? 'local';

  String get businessType => _prefs?.getString(_keyBusinessType) ?? '';

  Future<void> setSetupDone(bool value) async {
    await _prefs?.setBool(_keyIsSetupDone, value);
  }

  Future<void> setStoreName(String name) async {
    await _prefs?.setString(_keyStoreName, name);
  }

  Future<void> setTerminalId(String terminalId) async {
    await _prefs?.setString(_keyTerminalId, terminalId);
  }

  Future<void> setSyncMode(String mode) async {
    await _prefs?.setString(_keySyncMode, mode);
  }

  Future<void> setBusinessType(String type) async {
    await _prefs?.setString(_keyBusinessType, type);
  }

  /// Reset setup-related keys (marks app as not setup and clears store name)
  Future<void> resetSetup() async {
    await _prefs?.remove(_keyIsSetupDone);
    await _prefs?.remove(_keyStoreName);
    await _prefs?.remove(_keyTerminalId);
    await _prefs?.remove(_keySyncMode);
    await _prefs?.remove(_keyBusinessType);
  }
}
