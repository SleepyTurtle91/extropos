import 'package:extropos/models/loyalty_member.dart';
import 'package:extropos/models/loyalty_transaction.dart';
import 'package:extropos/services/database_helper.dart';

class LoyaltyService {
  static final LoyaltyService _instance = LoyaltyService._internal();

  factory LoyaltyService() {
    return _instance;
  }

  LoyaltyService._internal();

  static LoyaltyService get instance => _instance;

  // ==================== MEMBER OPERATIONS ====================

  Future<List<LoyaltyMember>> getAllMembers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('loyalty_members');
      return maps.map((map) => LoyaltyMember.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting all members: $e');
      rethrow;
    }
  }

  Future<LoyaltyMember?> getMemberById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'loyalty_members',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return LoyaltyMember.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting member by ID: $e');
      rethrow;
    }
  }

  Future<LoyaltyMember?> getMemberByPhone(String phone) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'loyalty_members',
        where: 'phone = ?',
        whereArgs: [phone],
      );
      if (maps.isNotEmpty) {
        return LoyaltyMember.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting member by phone: $e');
      rethrow;
    }
  }

  Future<int> addMember(LoyaltyMember member) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.insert('loyalty_members', member.toMap());
    } catch (e) {
      print('❌ Error adding member: $e');
      rethrow;
    }
  }

  Future<int> updateMember(LoyaltyMember member) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.update(
        'loyalty_members',
        member.toMap(),
        where: 'id = ?',
        whereArgs: [member.id],
      );
    } catch (e) {
      print('❌ Error updating member: $e');
      rethrow;
    }
  }

  Future<int> deleteMember(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.delete(
        'loyalty_members',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('❌ Error deleting member: $e');
      rethrow;
    }
  }

  // ==================== POINTS OPERATIONS ====================

  Future<void> addPoints(String memberId, int points, String reason) async {
    try {
      final member = await getMemberById(memberId);
      if (member == null) throw Exception('Member not found');

      final updatedMember = member.copyWith(
        totalPoints: member.totalPoints + points,
        lastPurchaseDate: DateTime.now(),
      );

      await updateMember(updatedMember);

      // Record transaction
      final transaction = LoyaltyTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        memberId: memberId,
        transactionType: 'Purchase',
        amount: 0,
        pointsEarned: points,
        pointsRedeemed: 0,
        transactionDate: DateTime.now(),
        notes: reason,
      );

      await addTransaction(transaction);
    } catch (e) {
      print('❌ Error adding points: $e');
      rethrow;
    }
  }

  Future<void> redeemPoints(String memberId, int points, String reward) async {
    try {
      final member = await getMemberById(memberId);
      if (member == null) throw Exception('Member not found');
      if (member.availablePoints < points) {
        throw Exception('Insufficient points');
      }

      final updatedMember = member.copyWith(
        redeemedPoints: member.redeemedPoints + points,
      );

      await updateMember(updatedMember);

      // Record transaction
      final transaction = LoyaltyTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        memberId: memberId,
        transactionType: 'Reward',
        amount: 0,
        pointsEarned: 0,
        pointsRedeemed: points,
        transactionDate: DateTime.now(),
        notes: reward,
      );

      await addTransaction(transaction);
    } catch (e) {
      print('❌ Error redeeming points: $e');
      rethrow;
    }
  }

  // ==================== TIER OPERATIONS ====================

  Future<void> updateMemberTier(String memberId, String newTier) async {
    try {
      final member = await getMemberById(memberId);
      if (member == null) throw Exception('Member not found');

      final updatedMember = member.copyWith(currentTier: newTier);
      await updateMember(updatedMember);
    } catch (e) {
      print('❌ Error updating tier: $e');
      rethrow;
    }
  }

  String calculateTier(LoyaltyMember member) {
    // Calculate tier based on total spending
    if (member.totalSpent >= 5000) {
      return 'Platinum';
    } else if (member.totalSpent >= 2000) {
      return 'Gold';
    } else if (member.totalSpent >= 500) {
      return 'Silver';
    } else {
      return 'Bronze';
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<List<LoyaltyTransaction>> getMemberTransactions(String memberId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'loyalty_transactions',
        where: 'member_id = ?',
        whereArgs: [memberId],
        orderBy: 'transaction_date DESC',
      );
      return maps.map((map) => LoyaltyTransaction.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting member transactions: $e');
      rethrow;
    }
  }

  Future<List<LoyaltyTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'loyalty_transactions',
        where: 'transaction_date BETWEEN ? AND ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'transaction_date DESC',
      );
      return maps.map((map) => LoyaltyTransaction.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting transactions by date range: $e');
      rethrow;
    }
  }

  Future<int> addTransaction(LoyaltyTransaction transaction) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.insert('loyalty_transactions', transaction.toMap());
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>> getMemberStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final memberCount = (await db.rawQuery('SELECT COUNT(*) FROM loyalty_members')).first['COUNT(*)'] as int? ?? 0;
      final totalPointsIssued = (await db.rawQuery('SELECT SUM(points_earned) FROM loyalty_transactions')).first['SUM(points_earned)'] as int? ?? 0;
      final totalPointsRedeemed = (await db.rawQuery('SELECT SUM(points_redeemed) FROM loyalty_transactions')).first['SUM(points_redeemed)'] as int? ?? 0;

      return {
        'totalMembers': memberCount,
        'totalPointsIssued': totalPointsIssued,
        'totalPointsRedeemed': totalPointsRedeemed,
        'activeMembers': 0,
      };
    } catch (e) {
      print('❌ Error getting member stats: $e');
      rethrow;
    }
  }

  Future<List<LoyaltyMember>> getTopMembers({int limit = 10}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'loyalty_members',
        orderBy: 'total_spent DESC',
        limit: limit,
      );
      return maps.map((map) => LoyaltyMember.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting top members: $e');
      rethrow;
    }
  }
}
