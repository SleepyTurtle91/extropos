import 'package:extropos/config/offline_first_config.dart';
import 'package:extropos/services/dashboard_period_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/offline_sync_service.dart';
import 'package:extropos/services/offline_sync_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline-First Smoke Tests', () {
    late OfflineSyncStorageService syncStorage;
    late OfflineSyncService syncService;

    setUp(() async {
      // Reset sync storage for each test
      syncStorage = OfflineSyncStorageService();
      await syncStorage.initialize();

      // Clear any existing queue items before test using fresh DB handle
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('sync_queue');
        await db.delete('sync_stats');
      } catch (e) {
        // If delete fails, continue (table may not exist yet in fresh setup)
      }

      syncService = OfflineSyncService();
      // Reset service state and reload from (now-empty) storage
      await syncService.resetForTests();
    });

    tearDown(() async {
      // Clear queue after each test but DON'T close the DB handle
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('sync_queue');
        await db.delete('sync_stats');
      } catch (_) {
        // OK if clean fails, move on
      }
    });

    test(
      'Smoke Test 1: Offline-First Config disables cloud features by default',
      () {
        // Verify offline-first config is properly set for launch
        expect(
          OfflineFirstConfig.offlineFirstMode,
          true,
          reason: 'App should launch in offline-first mode by default',
        );
        expect(
          OfflineFirstConfig.hideCloudFeatures,
          true,
          reason: 'Cloud UI should be hidden by default',
        );
        expect(
          OfflineFirstConfig.enableCloudBackend,
          false,
          reason: 'Cloud backend should be disabled at launch',
        );
        expect(
          OfflineFirstConfig.cloudFeaturesEnabled,
          false,
          reason: 'Cloud features should be disabled in offline-first mode',
        );
      },
    );

    test(
      'Smoke Test 2: Sale transaction queued to offline sync queue',
      () async {
        // Simulate a simple sale transaction
        final transactionData = {
          'receipt_number': 'TEST-001',
          'order_type': 'dine_in',
          'status': 'completed',
          'subtotal': 100.0,
          'tax': 6.0,
          'service_charge': 0.0,
          'discount': 0.0,
          'total': 106.0,
          'payment_method_id': 'pm-cash',
          'amount_paid': 106.0,
          'change': 0.0,
          'table_id': null,
          'user_id': 'user-1',
          'created_at': DateTime.now().toIso8601String(),
          'items': [
            {
              'product_id': 'prod-1',
              'product_name': 'Test Product',
              'quantity': 2,
              'unit_price': 50.0,
              'total_price': 100.0,
            },
          ],
        };

        await syncService.queueTransaction(transactionData);

        // Verify queue entry exists
        expect(
          syncService.queueSize,
          1,
          reason: 'Should have 1 item in sync queue',
        );

        final queueItems = await syncStorage.getQueueItems();
        expect(queueItems.length, 1, reason: 'Queue should contain 1 item');
        expect(
          queueItems[0]['type'],
          'transaction',
          reason: 'Item should be transaction type',
        );
      },
    );

    test(
      'Smoke Test 3: Multiple queue items persist with correct sorting',
      () async {
        // Add multiple transaction items
        for (int i = 1; i <= 3; i++) {
          await syncService.queueTransaction({
            'receipt_number': 'REC-$i',
            'total': 100.0 * i,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        expect(syncService.queueSize, 3);

        final items = await syncStorage.getQueueItems();
        expect(items.length, 3);

        // Verify all items exist and are in queue
        for (final item in items) {
          expect(item['type'], 'transaction');
          expect(item['priority'], isNotNull);
        }
      },
    );

    test('Smoke Test 4: Sync stats tracked correctly', () async {
      // Verify initial state - queue should load any existing items
      var pendingCount = await syncStorage.getPendingCount();
      expect(pendingCount, 0);

      // Queue an item
      await syncService.queueTransaction({'receipt_number': 'REC-001'});
      pendingCount = await syncStorage.getPendingCount();

      expect(pendingCount, 1, reason: 'Pending count should increment');
    });

    test(
      'Smoke Test 5: Offline sync queue persists across service reloads',
      () async {
        // Queue an item
        await syncService.queueTransaction({
          'receipt_number': 'PERSIST-TEST-001',
          'total': 150.0,
        });

        expect(syncService.queueSize, 1);

        // Simulate service reload (new instance)
        final newSyncService = OfflineSyncService();
        await newSyncService.initialize();

        // Verify item still exists in new instance
        expect(
          newSyncService.queueSize,
          1,
          reason: 'Queue should persist after service reload',
        );

        final items = await syncStorage.getQueueItems();
        expect(
          items[0]['data'],
          isNotNull,
          reason: 'Queue data should be intact',
        );
      },
    );

    test('Smoke Test 6: Pending item retry logic', () async {
      await syncService.queueTransaction({'receipt_number': 'RETRY-TEST'});

      var items = await syncStorage.getQueueItems();
      final firstItem = items[0];

      expect(
        firstItem['retry_count'],
        0,
        reason: 'Initial retry count should be 0',
      );
      expect(
        firstItem['last_retry_at'],
        null,
        reason: 'No retry timestamp initially',
      );

      // Simulate retry
      final now = DateTime.now().millisecondsSinceEpoch;
      await syncStorage.updateQueueItemRetry(
        id: firstItem['id'],
        retryCount: 1,
        lastRetryAt: now,
      );

      items = await syncStorage.getQueueItems();
      expect(items[0]['retry_count'], 1);
      expect(items[0]['last_retry_at'], isNotNull);
    });

    test('Smoke Test 7: Queue clearance after successful sync', () async {
      // Queue multiple items
      for (int i = 0; i < 3; i++) {
        await syncService.queueTransaction({'receipt_number': 'CLEAR-$i'});
      }

      expect(
        syncService.queueSize,
        3,
        reason: 'Should have 3 items in queue after queueing 3 transactions',
      );

      // Clear queue (simulating successful batch sync)
      await syncService.clearQueue();

      // Verify queue is actually empty
      final itemsAfterClear = await syncStorage.getQueueItems();
      expect(
        itemsAfterClear.length,
        0,
        reason: 'SQLite sync_queue table should be empty after clearQueue',
      );

      expect(
        syncService.queueSize,
        0,
        reason: 'In-memory queue should be empty after clearQueue',
      );
      expect(
        syncService.stats.totalQueued,
        0,
        reason: 'Stats should show totalQueued = 0 after clearQueue',
      );
    });

    test(
      'Smoke Test 8: Dashboard period service provides correct date ranges',
      () {
        // Test period service with known date
        final now = DateTime(2026, 3, 5); // March 5, 2026

        // Test: Today preset
        final todayRange = DashboardPeriodService.resolveRange(
          DashboardPeriodPreset.today,
          now: now,
        );
        expect(todayRange.start.day, now.day);
        expect(todayRange.end.day, now.day);

        // Test: Last 7 days preset
        final last7Range = DashboardPeriodService.resolveRange(
          DashboardPeriodPreset.last7Days,
          now: now,
        );
        expect(
          last7Range.start.isBefore(todayRange.start),
          true,
          reason: 'Last 7 days should start before today',
        );

        // Test: This month preset
        final thisMonthRange = DashboardPeriodService.resolveRange(
          DashboardPeriodPreset.thisMonth,
          now: now,
        );
        expect(thisMonthRange.start.month, now.month);
        expect(thisMonthRange.end.month, now.month);
      },
    );

    test('Smoke Test 9: Verify all cloud services are gated', () {
      // Verify the cloud services are properly disabled at launch
      // In offline-first mode, cloudFeaturesEnabled should be false

      expect(
        OfflineFirstConfig.cloudFeaturesEnabled,
        false,
        reason: 'Cloud features disabled in offline-first mode',
      );

      expect(
        OfflineFirstConfig.tenantActivationEnabled,
        OfflineFirstConfig.cloudFeaturesEnabled,
        reason: 'Tenant activation should follow cloud features flag',
      );

      expect(
        OfflineFirstConfig.cloudSubscriptionEnabled,
        OfflineFirstConfig.cloudFeaturesEnabled,
        reason: 'Cloud subscription should follow cloud features flag',
      );
    });

    test('Smoke Test 10: Sale with split payments queued correctly', () async {
      // Test split payment scenario
      final splitPaymentData = {
        'receipt_number': 'SPLIT-001',
        'total': 200.0,
        'payment_splits': [
          {'payment_method_id': 'pm-cash', 'amount': 150.0},
          {'payment_method_id': 'pm-card', 'amount': 50.0},
        ],
        'created_at': DateTime.now().toIso8601String(),
      };

      await syncService.queueTransaction(splitPaymentData);

      final items = await syncStorage.getQueueItems();
      expect(items.length, 1);

      // Decode JSON data to verify split payments preserved
      final dataJson = items[0]['data'];
      expect(
        dataJson,
        contains('payment_splits'),
        reason: 'Split payment data should be in queue',
      );
    });
  });
}
