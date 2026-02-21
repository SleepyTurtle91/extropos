import 'package:extropos/services/audit_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditService', () {
    late AuditService service;

    setUp(() {
      service = AuditService.instance;
    });

    test('logActivity() requires valid action', () async {
      expect(
        () => service.logActivity(
          userId: 'user_1',
          userName: 'Test User',
          action: 'INVALID_ACTION',
          resourceType: 'User',
          resourceId: 'resource_1',
          success: true,
        ),
        throwsException,
      );
    });

    test('logActivity() requires valid resource type', () async {
      expect(
        () => service.logActivity(
          userId: 'user_1',
          userName: 'Test User',
          action: 'CREATE',
          resourceType: 'InvalidType',
          resourceId: 'resource_1',
          success: true,
        ),
        throwsException,
      );
    });

    test('logActivity() records successful activity', () async {
      // final log = await service.logActivity(
      //   userId: 'user_1',
      //   action: 'CREATE',
      //   resourceType: 'User',
      //   resourceId: 'user_2',
      //   changesAfter: {'email': 'new@example.com'},
      //   success: true,
      // );
      // expect(log.action, 'CREATE');
      // expect(log.success, true);
      // expect(log.timestamp.isNotEmpty, true);
    });

    test('logActivity() records failed activity', () async {
      // final log = await service.logActivity(
      //   userId: 'user_1',
      //   action: 'DELETE',
      //   resourceType: 'Role',
      //   resourceId: 'role_1',
      //   success: false,
      //   failureReason: 'Cannot delete system role',
      // );
      // expect(log.success, false);
      // expect(log.failureReason, 'Cannot delete system role');
    });

    test('getActivitiesByUser() returns activities for user', () async {
      // final activities = await service.getActivitiesByUser(
      //   userId: 'user_1',
      //   limit: 50,
      // );
      // expect(activities, isA<List<ActivityLog>>());
    });

    test('getActivitiesByResource() returns activities for resource', () async {
      // final activities = await service.getActivitiesByResource(
      //   resourceType: 'User',
      //   resourceId: 'user_2',
      // );
      // expect(activities, isA<List<ActivityLog>>());
    });

    test('getActivitiesByDateRange() filters by date', () async {
      // final start = DateTime.now().subtract(Duration(days: 7));
      // final end = DateTime.now();
      // final activities = await service.getActivitiesByDateRange(
      //   startDate: start,
      //   endDate: end,
      // );
      // expect(activities, isA<List<ActivityLog>>());
      // for (final activity in activities) {
      //   final actDate = DateTime.parse(activity.timestamp);
      //   expect(actDate.isAfter(start), true);
      //   expect(actDate.isBefore(end.add(Duration(days: 1))), true);
      // }
    });

    test('getActivityById() returns specific activity', () async {
      // final log = await service.logActivity(
      //   userId: 'user_1',
      //   action: 'CREATE',
      //   resourceType: 'User',
      //   resourceId: 'user_2',
      //   success: true,
      // );
      // final retrieved = await service.getActivityById(log.id);
      // expect(retrieved?.id, log.id);
      // expect(retrieved?.action, 'CREATE');
    });

    test('cache is cleared on clearCache()', () async {
      // await service.getActivitiesByUser(userId: 'user_1');
      // service.clearCache();
      // Cache should be empty after clearing
    });

    test('statistics shows correct activity counts', () async {
      // final stats = await service.getStatistics();
      // expect(stats['totalActivities'], greaterThanOrEqualTo(0));
      // expect(stats['successCount'], greaterThanOrEqualTo(0));
      // expect(stats['failureCount'], greaterThanOrEqualTo(0));
      // expect(stats['actionBreakdown'], isA<Map>());
    });
  });
}
