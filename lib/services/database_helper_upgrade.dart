part of 'database_helper.dart';

extension DatabaseHelperUpgrade on DatabaseHelper {
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    for (final run in [
      () => _applyUpgrades_v2_v35(db, oldVersion),
      () => _applyUpgrades_v7_v30(db, oldVersion),
      () => _applyUpgrades_v31_v31(db, oldVersion),
    ]) {
      await run();
    }
  }
}
