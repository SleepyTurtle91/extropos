import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/business_session_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/user_activity_service.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user sign-in/out sessions during business hours
/// Separate from the app-level LockManager authentication
class UserSessionService extends ChangeNotifier {
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();

  User? _currentActiveUser;
  DateTime? _signInTime;

  User? get currentActiveUser => _currentActiveUser;
  DateTime? get signInTime => _signInTime;
  bool get hasActiveUser => _currentActiveUser != null;

  /// Sign in a user for POS operations during business hours
  Future<bool> signInUser(String pin) async {
    // Verify business is open
    if (!BusinessSessionService().isBusinessOpen) {
      throw Exception('Business must be open to sign in users');
    }

    // Find user by PIN
    final user = await DatabaseService.instance.findUserByPin(pin);
    if (user == null) {
      throw Exception('Invalid PIN');
    }

    if (user.status != UserStatus.active) {
      throw Exception('User account is not active');
    }

    // If another user is signed in, this is a handover
    if (_currentActiveUser != null) {
      // Log the previous user's sign-out
      await UserActivityService.instance.logUserSignOut(
        _currentActiveUser!,
        notes: 'Handover to ${user.fullName}',
      );
    }

    _currentActiveUser = user;
    _signInTime = DateTime.now();

    // Log the new user's sign-in
    await UserActivityService.instance.logUserSignIn(user);

    // Update user's last login
    await DatabaseService.instance.updateUser(
      user.copyWith(lastLoginAt: DateTime.now()),
    );

    notifyListeners();
    return true;
  }

  /// Sign out current user
  /// If endShift is true, also ends their shift
  Future<void> signOutUser({bool endShift = false}) async {
    if (_currentActiveUser == null) return;

    // Log the user's sign-out
    await UserActivityService.instance.logUserSignOut(
      _currentActiveUser!,
      notes: endShift ? 'End of shift' : 'User sign out',
    );

    _currentActiveUser = null;
    _signInTime = null;

    notifyListeners();
  }

  /// Quick switch - sign out without ending shift
  Future<void> quickSwitch() async {
    await signOutUser(endShift: false);
  }

  /// Clear session (for business close or emergency)
  void clearSession() {
    _currentActiveUser = null;
    _signInTime = null;
    notifyListeners();
  }
}
