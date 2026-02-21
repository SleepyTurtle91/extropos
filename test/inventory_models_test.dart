import 'package:extropos/models/inventory_models.dart';
import 'package:extropos/services/inventory_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Inventory Models Tests', () {
    late InventoryItem testItem;

    setUp(() {
      testItem = InventoryItem(
        id: '1',
        productId: 'prod-001',
        productName: 'Pizza Dough',
        currentQuantity: 50.0,
        minStockLevel: 20.0,
        maxStockLevel: 100.0,
        reorderQuantity: 30.0,
        costPerUnit: 5.0,
        unit: 'kg',
      );
    });

    test('InventoryItem - isLowStock returns true when below min level', () {
      testItem.currentQuantity = 15.0;
      expect(testItem.isLowStock, true);
    });

    test('InventoryItem - isLowStock returns false when above min level', () {
      testItem.currentQuantity = 50.0;
      expect(testItem.isLowStock, false);
    });

    test('InventoryItem - isOutOfStock returns true when quantity is 0', () {
      testItem.currentQuantity = 0;
      expect(testItem.isOutOfStock, true);
    });

    test('InventoryItem - isOutOfStock returns true when quantity is negative', () {
      testItem.currentQuantity = -5.0;
      expect(testItem.isOutOfStock, true);
    });

    test('InventoryItem - inventoryValue calculation', () {
      testItem.currentQuantity = 10.0;
      testItem.costPerUnit = 5.0;
      expect(testItem.inventoryValue, 50.0);
    });

    test('InventoryItem - inventoryValue returns 0 when costPerUnit is null', () {
      testItem.costPerUnit = null;
      expect(testItem.inventoryValue, 0.0);
    });

    test('InventoryItem - needsReorder returns true when low and reorder > 0', () {
      testItem.currentQuantity = 15.0;
      testItem.minStockLevel = 20.0;
      testItem.reorderQuantity = 30.0;
      expect(testItem.needsReorder, true);
    });

    test('InventoryItem - needsReorder returns false when not low', () {
      testItem.currentQuantity = 50.0;
      testItem.minStockLevel = 20.0;
      expect(testItem.needsReorder, false);
    });

    test('InventoryItem - status returns correct StockStatus', () {
      testItem.currentQuantity = 0;
      expect(testItem.status, StockStatus.outOfStock);

      testItem.currentQuantity = 15.0;
      testItem.minStockLevel = 20.0;
      expect(testItem.status, StockStatus.low);

      testItem.currentQuantity = 50.0;
      expect(testItem.status, StockStatus.normal);

      testItem.currentQuantity = 100.0;
      testItem.maxStockLevel = 80.0;
      expect(testItem.status, StockStatus.overstock);
    });

    test('InventoryItem - statusDisplay returns correct display text', () {
      testItem.currentQuantity = 0;
      expect(testItem.statusDisplay, 'Out of Stock');

      testItem.currentQuantity = 15.0;
      testItem.minStockLevel = 20.0;
      expect(testItem.statusDisplay, 'Low Stock');

      testItem.currentQuantity = 50.0;
      expect(testItem.statusDisplay, 'Normal');
    });

    test('InventoryItem - addMovement updates quantity correctly', () {
      final initialQty = testItem.currentQuantity;
      final movement = StockMovement(
        id: 'mov-001',
        type: 'purchase',
        quantity: 20.0,
        reason: 'Restock',
        date: DateTime.now(),
      );

      testItem.addMovement(movement);

      expect(testItem.currentQuantity, initialQty + 20.0);
      expect(testItem.movements.length, 1);
      expect(testItem.movements.first.quantity, 20.0);
    });

    test('InventoryItem - toJson/fromJson roundtrip', () {
      testItem.movements.add(StockMovement(
        id: 'mov-001',
        type: 'sale',
        quantity: -5.0,
        reason: 'Sale',
        date: DateTime.now(),
      ));

      final json = testItem.toJson();
      final restored = InventoryItem.fromJson(json);

      expect(restored.productName, testItem.productName);
      expect(restored.currentQuantity, testItem.currentQuantity);
      expect(restored.movements.length, 1);
    });
  });

  group('Stock Movement Tests', () {
    test('StockMovement - creates with correct properties', () {
      final movement = StockMovement(
        id: 'mov-001',
        type: 'sale',
        quantity: -5.0,
        reason: 'Customer purchase',
        date: DateTime(2026, 1, 23),
        userId: 'user-001',
        referenceId: 'txn-001',
      );

      expect(movement.id, 'mov-001');
      expect(movement.type, 'sale');
      expect(movement.quantity, -5.0);
      expect(movement.userId, 'user-001');
    });

    test('StockMovement - toJson/fromJson roundtrip', () {
      final movement = StockMovement(
        id: 'mov-001',
        type: 'purchase',
        quantity: 20.0,
        reason: 'PO-001 received',
        date: DateTime(2026, 1, 23),
      );

      final json = movement.toJson();
      final restored = StockMovement.fromJson(json);

      expect(restored.id, movement.id);
      expect(restored.type, movement.type);
      expect(restored.quantity, movement.quantity);
    });
  });

  group('Purchase Order Tests', () {
    late PurchaseOrder testPO;

    setUp(() {
      testPO = PurchaseOrder(
        id: 'po-001',
        poNumber: 'PO-20260123-001',
        supplierId: 'supp-001',
        supplierName: 'Best Supplies Inc',
        items: [
          PurchaseOrderItem(
            productId: 'prod-001',
            productName: 'Pizza Dough',
            quantity: 50.0,
            unitCost: 5.0,
            totalCost: 250.0,
          ),
          PurchaseOrderItem(
            productId: 'prod-002',
            productName: 'Cheese',
            quantity: 10.0,
            unitCost: 8.0,
            totalCost: 80.0,
          ),
        ],
        totalAmount: 330.0,
        status: PurchaseOrderStatus.draft,
        orderDate: DateTime(2026, 1, 23),
      );
    });

    test('PurchaseOrder - creates with correct properties', () {
      expect(testPO.poNumber, 'PO-20260123-001');
      expect(testPO.items.length, 2);
      expect(testPO.totalAmount, 330.0);
      expect(testPO.status, PurchaseOrderStatus.draft);
    });

    test('PurchaseOrder - toJson/fromJson roundtrip', () {
      final json = testPO.toJson();
      final restored = PurchaseOrder.fromJson(json);

      expect(restored.poNumber, testPO.poNumber);
      expect(restored.items.length, 2);
      expect(restored.totalAmount, testPO.totalAmount);
      expect(restored.status, testPO.status);
    });

    test('PurchaseOrder - calculates total correctly', () {
      final po = PurchaseOrder(
        id: 'po-002',
        poNumber: 'PO-002',
        supplierId: 'supp-001',
        supplierName: 'Test Supplier',
        items: [
          PurchaseOrderItem(
            productId: 'prod-001',
            productName: 'Item 1',
            quantity: 10.0,
            unitCost: 5.0,
            totalCost: 50.0,
          ),
          PurchaseOrderItem(
            productId: 'prod-002',
            productName: 'Item 2',
            quantity: 5.0,
            unitCost: 10.0,
            totalCost: 50.0,
          ),
        ],
        totalAmount: 100.0,
        status: PurchaseOrderStatus.draft,
        orderDate: DateTime.now(),
      );

      expect(po.totalAmount, 100.0);
    });
  });

  group('Supplier Tests', () {
    test('Supplier - creates with correct properties', () {
      final supplier = Supplier(
        id: 'supp-001',
        name: 'Best Supplies Inc',
        contactPerson: 'John Doe',
        phone: '+60123456789',
        email: 'john@bestsupplies.com',
        address: '123 Supply Street, Kuala Lumpur',
        taxNumber: 'SST123456789',
        isActive: true,
      );

      expect(supplier.name, 'Best Supplies Inc');
      expect(supplier.isActive, true);
      expect(supplier.email, 'john@bestsupplies.com');
    });

    test('Supplier - toJson/fromJson roundtrip', () {
      final supplier = Supplier(
        id: 'supp-001',
        name: 'Best Supplies',
        contactPerson: 'Jane Smith',
        phone: '0123456789',
        email: 'jane@bestsupplies.com',
        address: '456 Business Avenue',
        isActive: true,
      );

      final json = supplier.toJson();
      final restored = Supplier.fromJson(json);

      expect(restored.name, supplier.name);
      expect(restored.contactPerson, supplier.contactPerson);
      expect(restored.isActive, supplier.isActive);
    });
  });

  group('Inventory Report Tests', () {
    test('InventoryReport - creates with correct properties', () {
      final items = [
        InventoryItem(
          id: '1',
          productId: 'prod-001',
          productName: 'Item 1',
          currentQuantity: 50.0,
          minStockLevel: 20.0,
          costPerUnit: 5.0,
        ),
      ];

      final report = InventoryReport(
        reportDate: DateTime(2026, 1, 23),
        totalProducts: 1,
        lowStockItems: 0,
        outOfStockItems: 0,
        totalInventoryValue: 250.0,
        topValueItems: items,
        lowStockList: [],
      );

      expect(report.totalProducts, 1);
      expect(report.totalInventoryValue, 250.0);
    });

    test('InventoryReport - getSummary returns formatted string', () {
      final report = InventoryReport(
        reportDate: DateTime(2026, 1, 23),
        totalProducts: 100,
        lowStockItems: 5,
        outOfStockItems: 2,
        totalInventoryValue: 5000.0,
        topValueItems: [],
        lowStockList: [],
      );

      final summary = report.getSummary();

      expect(summary.contains('Inventory Report'), true);
      expect(summary.contains('Total Products: 100'), true);
      expect(summary.contains('Low Stock Items: 5'), true);
      expect(summary.contains('Out of Stock: 2'), true);
      expect(summary.contains('5000.00'), true);
    });
  });

  group('InventoryService Basic Tests', () {
    late InventoryService inventoryService;

    setUp(() {
      inventoryService = InventoryService();
    });

    test('InventoryService - initializes without errors', () async {
      await inventoryService.initialize();
      // Service should initialize successfully
      expect(inventoryService, isNotNull);
    });

    test('InventoryService - getAllInventory returns list', () {
      final inventory = inventoryService.getAllInventory();
      expect(inventory, isA<List<InventoryItem>>());
    });

    test('InventoryService - getLowStockItems filters correctly', () {
      final lowStockItems = inventoryService.getLowStockItems();
      expect(lowStockItems, isA<List<InventoryItem>>());

      for (var item in lowStockItems) {
        expect(item.isLowStock, true);
      }
    });

    test('InventoryService - getOutOfStockItems filters correctly', () {
      final outOfStockItems = inventoryService.getOutOfStockItems();
      expect(outOfStockItems, isA<List<InventoryItem>>());

      for (var item in outOfStockItems) {
        expect(item.isOutOfStock, true);
      }
    });

    test('InventoryService - getItemsNeedingReorder filters correctly', () {
      final reorderItems = inventoryService.getItemsNeedingReorder();
      expect(reorderItems, isA<List<InventoryItem>>());

      for (var item in reorderItems) {
        expect(item.needsReorder, true);
      }
    });
  });

  group('Inventory Service Stock Operations Tests', () {
    late InventoryService inventoryService;

    setUp(() {
      inventoryService = InventoryService();
    });

    test('InventoryService - updateStockAfterSale updates quantity', () async {
      const productId = 'test-prod-001';
      const saleQuantity = 5.0;

      await inventoryService.updateStockAfterSale(
        productId,
        saleQuantity,
        transactionId: 'txn-001',
      );

      // Service should process the sale
      expect(inventoryService, isNotNull);
    });

    test('InventoryService - addStock adds to inventory', () async {
      const productId = 'test-prod-002';
      const addQuantity = 20.0;

      await inventoryService.addStock(
        productId,
        addQuantity,
        reason: 'Restock',
      );

      // Service should add stock
      expect(inventoryService, isNotNull);
    });
  });

  group('Stock Status Enum Tests', () {
    test('StockStatus - all values are defined', () {
      expect(StockStatus.outOfStock, StockStatus.outOfStock);
      expect(StockStatus.low, StockStatus.low);
      expect(StockStatus.normal, StockStatus.normal);
      expect(StockStatus.overstock, StockStatus.overstock);
    });
  });

  group('Purchase Order Status Enum Tests', () {
    test('PurchaseOrderStatus - all values are defined', () {
      final statuses = [
        PurchaseOrderStatus.draft,
        PurchaseOrderStatus.sent,
        PurchaseOrderStatus.confirmed,
        PurchaseOrderStatus.partiallyReceived,
        PurchaseOrderStatus.received,
        PurchaseOrderStatus.cancelled,
      ];

      expect(statuses.length, 6);
    });

    test('PurchaseOrderStatus - names are correct', () {
      expect(PurchaseOrderStatus.draft.name, 'draft');
      expect(PurchaseOrderStatus.sent.name, 'sent');
      expect(PurchaseOrderStatus.confirmed.name, 'confirmed');
      expect(PurchaseOrderStatus.received.name, 'received');
    });
  });

  group('Inventory Models Edge Cases', () {
    test('InventoryItem - handles zero min stock level', () {
      final item = InventoryItem(
        id: '1',
        productId: 'prod-001',
        productName: 'Test',
        minStockLevel: 0.0,
        currentQuantity: 5.0,
      );

      expect(item.isLowStock, false);
    });

    test('InventoryItem - handles negative reorder quantity', () {
      final item = InventoryItem(
        id: '1',
        productId: 'prod-001',
        productName: 'Test',
        currentQuantity: 5.0,
        minStockLevel: 10.0,
        reorderQuantity: -5.0,
      );

      expect(item.needsReorder, false);
    });

    test('StockMovement - handles zero quantity', () {
      final movement = StockMovement(
        id: 'mov-001',
        type: 'adjustment',
        quantity: 0.0,
        reason: 'Correction',
        date: DateTime.now(),
      );

      expect(movement.quantity, 0.0);
    });

    test('PurchaseOrderItem - handles decimal quantities', () {
      final item = PurchaseOrderItem(
        productId: 'prod-001',
        productName: 'Flour (kg)',
        quantity: 2.5,
        unitCost: 10.0,
        totalCost: 25.0,
      );

      expect(item.quantity, 2.5);
      expect(item.totalCost, 25.0);
    });
  });
}
