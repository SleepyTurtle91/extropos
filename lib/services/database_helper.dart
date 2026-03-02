import 'package:extropos/services/pin_store.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:universal_io/io.dart';

part 'database_helper_upgrade.dart';
part 'database_upgrades/upgrade_v2_v35.dart';
part 'database_upgrades/upgrade_v7_v30.dart';
part 'database_upgrades/upgrade_v31_v31.dart';
part 'database_helper_tables.dart';
part 'database_helper_backup.dart';
part 'database_helper_reset.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  // Optional override for database file path (used by tests to isolate DB files)
  static String? _overrideDatabaseFilePath;
  // Optional test database override
  static Database? _testDatabase;

  DatabaseHelper._init();

  // Test database override setter
  set testDatabase(Database? db) {
    _testDatabase = db;
  }

  Future<Database> get database async {
    // Return test database if set
    if (_testDatabase != null) return _testDatabase!;

    if (_database != null) return _database!;

    // Initialize FFI for Web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    // Initialize FFI for desktop platforms if not already initialized
    else if (Platform.isWindows || Platform.isLinux) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print(
          '✅ DatabaseHelper: SQLite FFI initialized for Desktop (Linux/Windows)',
        );
      } catch (e) {
        print('❌ DatabaseHelper: Failed to initialize SQLite FFI: $e');
      }
    }

    _database = await _initDB('extropos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      // On Web, just use the filename. sqflite_common_ffi_web handles it.
      path = filePath;
    } else {
      path =
          _overrideDatabaseFilePath ?? join(await getDatabasesPath(), filePath);
    }

    // Check database integrity before opening (skip on Web)
    if (!kIsWeb) {
      await _checkDatabaseIntegrity(path);
    }

    return await openDatabase(
      path,
      // Phase 1 features: MyInvois, E-Wallet, Loyalty, PDPA, Inventory
      // v34: Table Management System (restaurant mode)
      version: 35,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onDowngrade: _onDowngrade,
    );
  }






  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Helper method to reset database (for development/testing)

  /// Safely reset database with automatic backup (recommended for production)

  /// Create a timestamped backup copy of the on-disk database file and
  /// return the absolute path to the backup file. Throws on failure.

  /// Override the database file path. When non-null, the helper will open and
  /// reset the database at the given absolute file path. Intended for tests.
  static void overrideDatabaseFilePath(String? absoluteFilePath) {
    _overrideDatabaseFilePath = absoluteFilePath;
  }

  /// Check database file integrity before opening

  /// Handle database downgrades (should not happen in production)

  /// Create a backup before risky operations like migrations

  /// Try to restore from the most recent backup if database is corrupted

  /// Get list of available backup files
  Future<List<String>> getBackupFiles() async {
    if (kIsWeb) return []; // No file backups on Web

    final dbPath =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    final backupDir = dirname(dbPath);
    final dir = Directory(backupDir);

    if (!await dir.exists()) return [];

    final backupFiles = await dir
        .list()
        .where(
          (entity) =>
              entity is File &&
              basename(entity.path).startsWith('extropos_backup_') &&
              basename(entity.path).endsWith('.db'),
        )
        .map((entity) => entity.path)
        .toList();

    return backupFiles;
  }

  /// Restore database from a specific backup file

  /// Clean up old backup files (keep only the most recent N backups)

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    if (kIsWeb) {
      return {
        'database_path': 'IndexedDB/extropos.db',
        'exists': true,
        'size_bytes': 0,
        'size_mb': 0.0,
        'last_modified': null,
        'backup_count': 0,
      };
    }

    final dbPath =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    final file = File(dbPath);

    final stats = {
      'database_path': dbPath,
      'exists': await file.exists(),
      'size_bytes': 0,
      'size_mb': 0.0,
      'last_modified': null,
      'backup_count': 0,
    };

    if (await file.exists()) {
      final stat = await file.stat();
      stats['size_bytes'] = stat.size;
      stats['size_mb'] = stat.size / (1024 * 1024);
      stats['last_modified'] = stat.modified.toIso8601String();
    }

    stats['backup_count'] = (await getBackupFiles()).length;

    return stats;
  }

  /// Get the current database file path
  Future<String> getDatabasePath() async {
    if (kIsWeb) return 'extropos.db';

    return _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
  }
}