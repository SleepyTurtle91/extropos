part of '../database_service.dart';

/// Products domain: Modifiers and related helpers
extension DatabaseServiceProducts on DatabaseService {
  // ==================== MODIFIERS ====================

  Future<List<ModifierGroup>> getModifierGroups() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_groups',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierGroup.fromJson(maps[i]));
  }

  Future<List<ModifierGroup>> getModifierGroupsForCategory(
    String categoryId,
  ) async {
    final allGroups = await getModifierGroups();
    return allGroups
        .where((group) => group.appliesToCategory(categoryId))
        .toList();
  }

  Future<ModifierGroup?> getModifierGroupById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ModifierGroup.fromJson(maps[0]);
  }

  Future<void> insertModifierGroup(ModifierGroup group) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('modifier_groups', group.toJson());
  }

  Future<void> updateModifierGroup(ModifierGroup group) async {
    final db = await DatabaseHelper.instance.database;
    final updatedGroup = group.copyWith(updatedAt: DateTime.now());
    await db.update(
      'modifier_groups',
      updatedGroup.toJson(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteModifierGroup(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ModifierItem>> getModifierItems(String groupId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      where: 'modifier_group_id = ? AND is_available = ?',
      whereArgs: [groupId, 1],
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierItem.fromJson(maps[i]));
  }

  Future<List<ModifierItem>> getAllModifierItems() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      orderBy: 'modifier_group_id ASC, sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierItem.fromJson(maps[i]));
  }

  Future<ModifierItem?> getModifierItemById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ModifierItem.fromJson(maps[0]);
  }

  Future<void> insertModifierItem(ModifierItem item) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('modifier_items', item.toJson());
  }

  Future<void> updateModifierItem(ModifierItem item) async {
    final db = await DatabaseHelper.instance.database;
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    await db.update(
      'modifier_items',
      updatedItem.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteModifierItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_items', where: 'id = ?', whereArgs: [id]);
  }
}
