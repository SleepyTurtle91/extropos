import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:universal_io/io.dart' show Platform;

/// Centralized bootstrap for the latest SQLite3-backed configuration.
class SQLite3Bootstrap {
  SQLite3Bootstrap._();

  static bool _initialized = false;

  /// Initialize database factory once per process.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      developer.log('SQLite3 bootstrap: web FFI factory initialized');
      _initialized = true;
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      developer.log('SQLite3 bootstrap: desktop FFI factory initialized');
      _initialized = true;
      return;
    }

    if (Platform.isAndroid) {
      // Ensures bundled SQLite3 can be opened reliably on older Android builds.
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      developer.log(
        'SQLite3 bootstrap: Android sqlite3 compatibility workaround applied',
      );
    }

    _initialized = true;
  }

  /// Apply sqlite pragmas for data integrity and write performance.
  static Future<void> configureDatabase(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    // WAL/synchronous tuning is not required for web-backed storage.
    if (kIsWeb) return;

    await db.execute('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA busy_timeout = 5000');
  }
}
