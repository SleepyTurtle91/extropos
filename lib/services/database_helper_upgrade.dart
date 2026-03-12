part of 'database_helper.dart';

extension DatabaseHelperUpgrade on DatabaseHelper {
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    for (final run in [
      () => _applyUpgradesV2V35(db, oldVersion),
      () => _applyUpgradesV7V30(db, oldVersion),
      () => _applyUpgradesV31V31(db, oldVersion),
    ]) {
      await run();
    }
  }
}
