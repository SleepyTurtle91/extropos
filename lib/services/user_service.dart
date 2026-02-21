import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Lightweight wrapper around DatabaseService to expose user-related operations.
class UserService {
  static final UserService instance = UserService._init();
  UserService._init();

  final _db = DatabaseService.instance;

  Future<List<User>> getAllUsers() => _db.getUsers();

  Future<User?> getById(String id) => _db.getUserById(id);

  Future<int> addUser(User user) => _db.insertUser(user);

  Future<int> updateUser(User user) => _db.updateUser(user);

  Future<int> deleteUser(String id) => _db.deleteUser(id);

  /// Update user's last login timestamp
  Future<int> updateLastLogin(String userId) => _db.updateUserLastLogin(userId);

  /// Find the first active user matching the provided PIN (exact match).
  Future<User?> findByPin(String pin) async {
    final all = await getAllUsers();
    debugPrint('🔐 findByPin() - Looking for PIN: "$pin"');
    for (var user in all) {
      debugPrint(
        '🔐   User: ${user.id} (${user.fullName}), PIN: "${user.pin}", Active: ${user.status == UserStatus.active}',
      );
    }
    try {
      // First try to find user with PIN stored in database
      final dbMatch = all.firstWhere(
        (u) => u.pin == pin && u.status == UserStatus.active,
      );
      debugPrint(
        '🔐 findByPin() - Found match in database: ${dbMatch.fullName}',
      );
      return dbMatch;
    } catch (e) {
      debugPrint('🔐 findByPin() - No match in database, checking PinStore...');
      // If no match in database, check PinStore for users with empty PIN in DB
      try {
        final pinStoreMatch = all.firstWhere((u) {
          if (u.status != UserStatus.active) return false;
          // Check if this user's PIN is stored in PinStore
          final storedPin = PinStore.instance.getPinForUser(u.id);
          debugPrint(
            '🔐   Checking PinStore for user ${u.id}: stored="$storedPin", input="$pin"',
          );
          return storedPin == pin;
        });
        debugPrint(
          '🔐 findByPin() - Found match in PinStore: ${pinStoreMatch.fullName}',
        );
        return pinStoreMatch;
      } catch (e2) {
        debugPrint('🔐 findByPin() - No match found in PinStore either!');
        return null;
      }
    }
  }
}
