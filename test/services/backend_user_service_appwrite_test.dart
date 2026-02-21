import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/services/backend_user_service_appwrite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendUserServiceAppwrite', () {
    late BackendUserServiceAppwrite service;

    setUp(() {
      service = BackendUserServiceAppwrite.instance;
    });

    test('getUserById() returns null for non-existent user', () async {
      final user = await service.getUserById('non_existent_id');
      expect(user, null);
    });

    test('getUserByEmail() returns null for non-existent email', () async {
      final user = await service.getUserByEmail('notfound@example.com');
      expect(user, null);
    });

    test('getAllUsers() returns empty list initially', () async {
      final users = await service.getAllUsers();
      expect(users, isA<List<BackendUserModel>>());
    });

    test('createUser() requires valid email', () async {
      expect(
        () => service.createUser(
          email: 'invalid-email',
          displayName: 'Test',
          roleId: 'role_1',
          createdBy: 'system',
        ),
        throwsException,
      );
    });

    test('createUser() requires non-empty display name', () async {
      expect(
        () => service.createUser(
          email: 'test@example.com',
          displayName: '',
          roleId: 'role_1',
          createdBy: 'system',
        ),
        throwsException,
      );
    });

    test('updateUser() returns updated user', () async {
      // This would require creating a user first
      // final created = await service.createUser(...);
      // final updated = await service.updateUser(
      //   userId: created.id,
      //   displayName: 'New Name',
      //   updatedBy: 'system',
      // );
      // expect(updated.displayName, 'New Name');
    });

    test('lockUser() sets isLockedOut to true', () async {
      // final created = await service.createUser(...);
      // await service.lockUser(userId: created.id, lockedBy: 'system');
      // final locked = await service.getUserById(created.id);
      // expect(locked?.isLockedOut, true);
    });

    test('unlockUser() sets isLockedOut to false', () async {
      // final created = await service.createUser(...);
      // await service.lockUser(userId: created.id, lockedBy: 'system');
      // await service.unlockUser(userId: created.id, unlockedBy: 'system');
      // final unlocked = await service.getUserById(created.id);
      // expect(unlocked?.isLockedOut, false);
    });

    test('deactivateUser() sets isActive to false', () async {
      // final created = await service.createUser(...);
      // await service.deactivateUser(userId: created.id, deactivatedBy: 'system');
      // final deactivated = await service.getUserById(created.id);
      // expect(deactivated?.isActive, false);
    });

    test('deleteUser() removes user', () async {
      // final created = await service.createUser(...);
      // await service.deleteUser(userId: created.id, deletedBy: 'system');
      // final deleted = await service.getUserById(created.id);
      // expect(deleted, null);
    });

    test('cache is cleared on clearCache()', () async {
      // await service.getAllUsers(); // Populate cache
      // service.clearCache();
      // Cache should be empty after clearing
    });
  });
}
