import 'dart:async';

import 'package:extropos/models/business_session_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Service for managing business sessions (opening/closing business)
class BusinessSessionService extends ChangeNotifier {
  static final BusinessSessionService _instance =
      BusinessSessionService._internal();
  factory BusinessSessionService() => _instance;
  BusinessSessionService._internal();

  BusinessSession? _currentSession;
  bool _isInitialized = false;

  /// Get current business session
  BusinessSession? get currentSession => _currentSession;

  /// Check if business is currently open
  bool get isBusinessOpen => _currentSession?.isOpen ?? false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadCurrentSession();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize business session service: $e');
    }
  }

  /// Load current open session from database
  Future<void> _loadCurrentSession() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Ensure the business_sessions table exists
      await _ensureBusinessSessionsTableExists(db);

      final results = await db.query(
        'business_sessions',
        where: 'is_open = ?',
        whereArgs: [1],
        orderBy: 'open_date DESC',
        limit: 1,
      );

      if (results.isNotEmpty) {
        _currentSession = BusinessSession.fromMap(results.first);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load current session: $e');
    }
  }

  /// Ensure the business_sessions table exists
  Future<void> _ensureBusinessSessionsTableExists(Database db) async {
    try {
      // Check if table exists
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='business_sessions'",
      );

      if (result.isEmpty) {
        // Create the table if it doesn't exist
        await db.execute('''
          CREATE TABLE business_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            open_date TEXT NOT NULL,
            close_date TEXT,
            opening_cash REAL NOT NULL,
            closing_cash REAL,
            expected_cash REAL,
            notes TEXT,
            is_open INTEGER DEFAULT 1
          )
        ''');
        debugPrint('Created business_sessions table');
      }
    } catch (e) {
      debugPrint('Error ensuring business_sessions table exists: $e');
      // Try to create anyway
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS business_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            open_date TEXT NOT NULL,
            close_date TEXT,
            opening_cash REAL NOT NULL,
            closing_cash REAL,
            expected_cash REAL,
            notes TEXT,
            is_open INTEGER DEFAULT 1
          )
        ''');
        debugPrint('Created business_sessions table with IF NOT EXISTS');
      } catch (e2) {
        debugPrint('Failed to create business_sessions table: $e2');
      }
    }
  }

  /// Open business with starting cash amount
  Future<bool> openBusiness(double openingCash, {String? notes}) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Ensure the business_sessions table exists
      await _ensureBusinessSessionsTableExists(db);

      // If business is already open, force close the previous session
      if (isBusinessOpen && _currentSession != null) {
        await forceCloseSession();
      }

      final session = BusinessSession.open(openingCash, notes: notes);

      final id = await db.insert('business_sessions', session.toMap());
      _currentSession = session.copyWith(id: id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Failed to open business: $e');
      return false;
    }
  }

  /// Close business with closing cash amount
  Future<bool> closeBusiness(double closingCash, {String? notes}) async {
    if (!isBusinessOpen || _currentSession == null) {
      throw Exception('Business is not open');
    }

    try {
      final closedSession = _currentSession!.close(closingCash, notes: notes);
      final db = await DatabaseHelper.instance.database;

      await db.update(
        'business_sessions',
        closedSession.toMap(),
        where: 'id = ?',
        whereArgs: [closedSession.id],
      );

      _currentSession = closedSession;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Failed to close business: $e');
      return false;
    }
  }

  /// Get all business sessions
  Future<List<BusinessSession>> getAllSessions() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'business_sessions',
        orderBy: 'open_date DESC',
      );

      return results.map((map) => BusinessSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Failed to get business sessions: $e');
      return [];
    }
  }

  /// Get sessions for a specific date range
  Future<List<BusinessSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'business_sessions',
        where: 'open_date >= ? AND open_date <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'open_date DESC',
      );

      return results.map((map) => BusinessSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Failed to get sessions in range: $e');
      return [];
    }
  }

  /// Force close current session (emergency)
  Future<bool> forceCloseSession() async {
    if (_currentSession == null) return true;

    try {
      final db = await DatabaseHelper.instance.database;
      final closedSession = _currentSession!.copyWith(
        closeDate: DateTime.now(),
        isOpen: false,
      );

      await db.update(
        'business_sessions',
        closedSession.toMap(),
        where: 'id = ?',
        whereArgs: [closedSession.id],
      );

      _currentSession = closedSession;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Failed to force close session: $e');
      return false;
    }
  }

  /// Clear current session (for testing/reset)
  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }
}
