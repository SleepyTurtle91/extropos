import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking user activity during business sessions
/// Used for "No-Shift" tracking where we monitor user sessions instead of formal shifts
class UserActivityService {
  static final UserActivityService _instance = UserActivityService._internal();
  factory UserActivityService() => _instance;
  static UserActivityService get instance => _instance;
  UserActivityService._internal();

  /// Log user sign-in activity
  Future<void> logUserSignIn(User user) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activity_log', {
        'user_id': user.id,
        'activity_type': 'sign_in',
        'timestamp': DateTime.now().toIso8601String(),
        'details': 'User signed in for POS operations',
      });
    } catch (e) {
      debugPrint('Error logging user sign-in: $e');
    }
  }

  /// Log user sign-out activity
  Future<void> logUserSignOut(User user, {String? notes}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activity_log', {
        'user_id': user.id,
        'activity_type': 'sign_out',
        'timestamp': DateTime.now().toIso8601String(),
        'details': notes ?? 'User signed out',
      });
    } catch (e) {
      debugPrint('Error logging user sign-out: $e');
    }
  }

  /// Log transaction activity (called when a sale is completed)
  Future<void> logTransaction(
    String userId,
    String orderId,
    double amount, {
    String? paymentMethod,
    double discountAmount = 0.0,
    double taxAmount = 0.0,
    double taxRate = 0.0,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activity_log', {
        'user_id': userId,
        'activity_type': 'transaction',
        'timestamp': DateTime.now().toIso8601String(),
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
        'discount_amount': discountAmount,
        'tax_amount': taxAmount,
        'tax_rate': taxRate,
        'details': 'Sale transaction completed',
      });
    } catch (e) {
      debugPrint('Error logging transaction: $e');
    }
  }

  /// Log void activity
  Future<void> logVoid(
    String userId,
    String orderId,
    double amount, {
    String? reason,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activity_log', {
        'user_id': userId,
        'activity_type': 'void',
        'timestamp': DateTime.now().toIso8601String(),
        'order_id': orderId,
        'amount': amount,
        'details': reason ?? 'Transaction voided',
      });
    } catch (e) {
      debugPrint('Error logging void: $e');
    }
  }

  /// Log refund activity
  Future<void> logRefund(
    String userId,
    String orderId,
    double amount, {
    String? reason,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activity_log', {
        'user_id': userId,
        'activity_type': 'refund',
        'timestamp': DateTime.now().toIso8601String(),
        'order_id': orderId,
        'amount': amount,
        'details': reason ?? 'Refund processed',
      });
    } catch (e) {
      debugPrint('Error logging refund: $e');
    }
  }

  /// Log manual override activity
  Future<void> logOverride(
    String userId,
    String orderId, {
    String? reason,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activity_log', {
        'user_id': userId,
        'activity_type': 'override',
        'timestamp': DateTime.now().toIso8601String(),
        'order_id': orderId,
        'details': reason ?? 'Manual override performed',
      });
    } catch (e) {
      debugPrint('Error logging override: $e');
    }
  }

  /// Get user activity summary for a date range
  Future<Map<String, dynamic>> getUserActivitySummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        '''
        SELECT
          ual.user_id,
          u.full_name,
          COUNT(CASE WHEN ual.activity_type = 'transaction' THEN 1 END) as transaction_count,
          SUM(CASE WHEN ual.activity_type = 'transaction' THEN ual.amount ELSE 0 END) as total_sales,
          COUNT(CASE WHEN ual.activity_type = 'cash_drawer' THEN 1 END) as drawer_opens,
          MIN(CASE WHEN ual.activity_type = 'sign_in' THEN ual.timestamp END) as first_sign_in,
          MAX(CASE WHEN ual.activity_type = 'sign_out' THEN ual.timestamp END) as last_sign_out
        FROM user_activity_log ual
        LEFT JOIN users u ON ual.user_id = u.id
        WHERE DATE(ual.timestamp) BETWEEN DATE(?) AND DATE(?)
        GROUP BY ual.user_id, u.full_name
        ORDER BY total_sales DESC
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return {
        'summary': result,
        'date_range': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Error getting user activity summary: $e');
      return {'summary': [], 'date_range': {}};
    }
  }

  /// Get detailed activity log for a specific user and date
  Future<List<Map<String, dynamic>>> getUserDetailedActivity(
    String userId,
    DateTime date,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        '''
        SELECT
          ual.*,
          u.full_name
        FROM user_activity_log ual
        LEFT JOIN users u ON ual.user_id = u.id
        WHERE ual.user_id = ? AND DATE(ual.timestamp) = DATE(?)
        ORDER BY ual.timestamp DESC
      ''',
        [userId, date.toIso8601String()],
      );

      return result;
    } catch (e) {
      debugPrint('Error getting user detailed activity: $e');
      return [];
    }
  }
}
