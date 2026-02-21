import 'package:extropos/models/shift_model.dart';
import 'package:extropos/services/business_session_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/permission_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ShiftService extends ChangeNotifier {
  static final ShiftService _instance = ShiftService._internal();
  static ShiftService get instance => _instance;
  factory ShiftService() => _instance;
  ShiftService._internal();

  Shift? _currentShift;

  Shift? get currentShift => _currentShift;
  bool get hasActiveShift => _currentShift != null && _currentShift!.isActive;

  Future<void> initialize(String userId) async {
    _currentShift = await getCurrentShift(userId);
    notifyListeners();
  }

  Future<Shift?> getCurrentShift(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Shift.fromMap(maps.first);
    }
    return null;
  }

  Future<Shift> startShift(
    String userId,
    double openingCash, {
    String? notes,
  }) async {
    // Check if user already has an active shift
    final existingShift = await getCurrentShift(userId);
    if (existingShift != null) {
      throw Exception('User already has an active shift');
    }

    final session = BusinessSessionService().currentSession;

    final shift = Shift(
      id: const Uuid().v4(),
      userId: userId,
      businessSessionId: session?.id,
      startTime: DateTime.now(),
      openingCash: openingCash,
      notes: notes,
      status: 'active',
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert('shifts', shift.toMap());

    _currentShift = shift;
    notifyListeners();
    return shift;
  }

  Future<Shift> endShift(
    String shiftId,
    double closingCash, {
    String? notes,
    bool forceEnd = false, // For manager override
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Get the shift first
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [shiftId],
    );

    if (maps.isEmpty) {
      throw Exception('Shift not found');
    }

    final currentShift = Shift.fromMap(maps.first);

    // Calculate expected cash (opening + sales + etc)
    final expectedCash =
        currentShift.openingCash + await calculateShiftSales(shiftId);

    // Calculate variance
    final variance = closingCash - expectedCash;

    // Check if variance requires manager acknowledgment
    if (!forceEnd && variance.abs() > 0.01) {
      // Allow 1 sen tolerance
      final currentUser = UserSessionService().currentActiveUser;
      if (currentUser == null ||
          !PermissionService().hasPermission('canAcknowledgeVariance')) {
        throw Exception(
          'Cash variance detected: RM${variance.abs().toStringAsFixed(2)} ${variance > 0 ? 'surplus' : 'shortage'}. '
          'Manager authorization required to acknowledge variance.',
        );
      }
    }

    final updatedShift = currentShift.copyWith(
      endTime: DateTime.now(),
      closingCash: closingCash,
      expectedCash: expectedCash,
      variance: variance,
      notes: notes,
      status: 'completed',
      varianceAcknowledged: variance.abs() <= 0.01 || forceEnd,
    );

    await db.update(
      'shifts',
      updatedShift.toMap(),
      where: 'id = ?',
      whereArgs: [shiftId],
    );

    if (_currentShift?.id == shiftId) {
      _currentShift = null;
    }

    notifyListeners();
    return updatedShift;
  }

  Future<double> calculateShiftSales(String shiftId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(total) as total 
      FROM orders 
      WHERE shift_id = ? AND status = 'completed'
    ''',
      [shiftId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }
}
