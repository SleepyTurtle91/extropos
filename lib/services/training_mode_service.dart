import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/enum_models.dart';
import 'package:extropos/services/mock_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage training mode and temporary training transactions
class TrainingModeService with ChangeNotifier {
  static final TrainingModeService instance = TrainingModeService._init();
  TrainingModeService._init() {
    _loadTrainingModeStatus();
  }

  static const _prefsKey = 'isTrainingModeEnabled';
  bool _isTrainingMode = false;

  // Simple in-memory list to store training transactions
  final List<Map<String, dynamic>> _trainingTransactions = [];

  bool get isTrainingMode => _isTrainingMode;

  List<Map<String, dynamic>> get trainingTransactions =>
      List.unmodifiable(_trainingTransactions);

  Future<void> _loadTrainingModeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTrainingMode = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      // In some test environments the shared_preferences plugin isn't
      // registered and throws MissingPluginException. Default to false and
      // continue — training mode will be off unless explicitly enabled.
      _isTrainingMode = false;
    }
    notifyListeners();
  }

  Future<void> toggleTrainingMode(bool enabled) async {
    if (_isTrainingMode == enabled) return;
    _isTrainingMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    
    if (enabled) {
      // Load appropriate training database based on business mode
      await _loadTrainingDatabase();
    } else {
      clearTrainingData();
    }
    
    notifyListeners();
  }

  /// Load training database based on current business mode
  Future<void> _loadTrainingDatabase() async {
    try {
      final businessMode = BusinessInfo.instance.selectedBusinessMode;
      
      if (businessMode == BusinessMode.restaurant) {
        print('📚 Loading Restaurant Training Database...');
        await MockDatabaseService.instance.restoreRestaurantMockData();
      } else {
        // Default to retail for both retail and cafe modes
        print('📚 Loading Retail Training Database...');
        await MockDatabaseService.instance.restoreRetailMockData();
      }
      
      print('✅ Training database loaded successfully');
    } catch (e) {
      print('❌ Error loading training database: $e');
      // Don't rethrow - allow training mode to continue even if DB load fails
    }
  }

  void addTrainingTransaction(Map<String, dynamic> tx) {
    _trainingTransactions.add(tx);
    notifyListeners();
  }

  void clearTrainingData() {
    _trainingTransactions.clear();
    notifyListeners();
  }
}
