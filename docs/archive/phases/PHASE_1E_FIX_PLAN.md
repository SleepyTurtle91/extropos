# Phase 1e Service Fixes - Action Plan

## Overview

**Status**: 35% complete - Infrastructure ready, service compilation blocked by 40+ errors
**Next Goal**: Get all 48 tests compiling and passing
**Estimated Time**: 2-3 hours for core fixes, then integration testing

## Quick Priority Order

### 🔴 HIGHEST PRIORITY - logActivity Missing userName (17 instances)

**Symptom**: `Required named parameter 'userName' must be provided`
**Locations**:
- backend_user_service_appwrite.dart: 9 occurrences (lines 187, 202, 274, 289, 325, 338, 375, 416, 456)
- role_service_appwrite.dart: 5 occurrences (lines 241, 255, 311, 326, 381)
- phase1_inventory_service_appwrite.dart: 4 occurrences (lines 167, 181, 278, 300)
- audit_service_appwrite.dart: Already in test, will fix with service redesign

**Fix**: Add `userName: [user.displayName ?? 'system' | updatedBy ?? 'system' | createdBy ?? 'system']` to each call
**Time**: 15-20 minutes
**Impact**: Enables 20+ tests to compile

### 🟡 HIGH PRIORITY - Model Field Mismatches (phase1_inventory_service_appwrite.dart)

**Symptom**: Various "isn't defined" and "No named parameter" errors
**Issues**:
1. Line 105: `item.minStockLevel` → should be `item.minimumStockLevel`
2. Line 147: `userId` param → doesn't exist in StockMovementModel (check actual fields)
3. Line 136: `sku` param → doesn't exist in InventoryModel
4. Lines 474, 492, 494-495: Same field name errors

**Fix**: Review InventoryModel and StockMovementModel actual field names, update service accordingly
**Time**: 20-30 minutes
**Impact**: Enables 12 inventory tests to compile

### 🟡 MEDIUM PRIORITY - audit_service_appwrite.dart Redesign

**Symptom**: Model field mismatches (timestamp vs createdAt, missing userName)
**Root Cause**: Service was designed with wrong assumptions about ActivityLogModel
**Issues**:
1. Lines 58, 396: Missing `userName` parameter
2. Lines 67, 405: `timestamp` doesn't exist (use `createdAt`)
3. Lines 91, 260, 276: Accessing non-existent `timestamp` field

**Fix**: Audit ActivityLogModel actual implementation, redesign service to match
**Time**: 30-45 minutes
**Impact**: Enables 2+ audit tests to compile

### 🟢 MEDIUM PRIORITY - Type Issues & null Checks (role_service_appwrite.dart)

**Symptom**: "String? can't be assigned to String"
**Locations**:
1. Line 133: `_roleCache[role.id]` where role.id is optional
2. Line 265: `existing.id` is optional but passed as required

**Fix**: Use null coalescing or null checks: `role.id ?? ''` or `existing.id!`
**Time**: 5-10 minutes
**Impact**: Fixes caching logic edge cases

---

## Detailed Fix Sequence

### Step 1: Fix logActivity Missing userName (15 min)

**File**: backend_user_service_appwrite.dart
**Lines to fix**: 187, 202, 274, 289, 325, 338, 375, 416, 456

Example pattern - change from:
```dart
await _auditService.logActivity(
  userId: user.id,
  action: 'CREATE',
  // ...
);
```

To:
```dart
await _auditService.logActivity(
  userId: user.id,
  userName: user.displayName,  // ADD THIS LINE
  action: 'CREATE',
  // ...
);
```

---

### Step 2: Fix role_service_appwrite.dart logActivity (5 min)

**File**: role_service_appwrite.dart
**Lines to fix**: 241, 255, 311, 326, 381

Same pattern as Step 1 - add `userName: [user.displayName | createdBy | updatedBy] ?? 'system'`

---

### Step 3: Fix phase1_inventory_service_appwrite.dart logActivity (5 min)

**File**: phase1_inventory_service_appwrite.dart
**Lines to fix**: 167, 181, 278, 300

Same logActivity fix pattern

---

### Step 4: Review Model Fields (10 min)

**File**: lib/models/inventory_model.dart
**Action**: Check actual field names for:
- `minStockLevel` vs `minimumStockLevel`
- `maxStockLevel` vs `maximumStockLevel`
- Any `sku` field?
- StockMovementModel fields (especially `userId`)

**File**: lib/models/role_model.dart
**Action**: Verify if any additional fields are needed

---

### Step 5: Fix phase1_inventory_service_appwrite.dart Field Names (15 min)

**File**: phase1_inventory_service_appwrite.dart
**Lines to update**:
- Replace all `minStockLevel` with correct actual field name
- Replace all `maxStockLevel` with correct actual field name
- Fix StockMovementModel instantiation parameters (lines 147, 249)
- Fix InventoryModel instantiation parameters (lines 136, 474)

---

### Step 6: Fix audit_service_appwrite.dart (20 min)

**File**: lib/services/audit_service_appwrite.dart
**Action**: Review ActivityLogModel and update service to match:
1. Check if ActivityLogModel has `timestamp` field (likely has `createdAt` instead)
2. Check if it requires `userName` (likely yes)
3. Update all ActivityLogModel instantiations
4. Fix field access patterns

---

### Step 7: Run Complete Test Suite

**Command**: 
```bash
cd e:\flutterpos
flutter test test/services/
```

**Expected Result**: 
- All 48+ tests should compile
- AppwritePhase1Service: 3 passing
- Phase1a Models: 14 passing  
- Other tests: Will show as pending/skipped or with runtime errors

---

## Critical Info from Models

### ActivityLogModel (lib/models/activity_log_model.dart)
- Has: `userId`, `userName` (required), `action`, `resourceType`, `resourceId`, `description`, `success`, `createdAt`
- May have: `changesBefore`, `changesAfter`, `ipAddress`, `userAgent`, `errorMessage`, `locationId`
- **Does NOT have**: `timestamp` field (use `createdAt` instead)

### InventoryModel (lib/models/inventory_model.dart)
- Has: `productId`, `productName`, `locationId`, `currentQuantity`, `minimumStockLevel`, `maximumStockLevel`, `reorderQuantity`, `movements`
- May have: `costPerUnit`, `lastCountedAt`, `notes`
- **Does NOT have**: `minStockLevel`, `maxStockLevel`, `sku` fields
- **movements field**: Type is `List<StockMovementModel>` (already a list, don't try to add individual movements)

### StockMovementModel
- **Check fields**: Likely has `type`, `quantity`, `reason`, `movedAt`, `movedBy` or similar
- **Does NOT have**: `userId` parameter (probably use different field name)

### RoleModel (lib/models/role_model.dart)
- Has: `id` (optional String?), `name`, `description`, `permissions` (Map<String, bool>), `isSystemRole`, `createdAt`, `updatedAt`
- **Remember**: `permissions` is `Map<String, bool>`, not `List<String>`

---

## Verification Checklist

After each fix, verify:
- [ ] No red squiggly lines in file
- [ ] `flutter analyze lib/services/[file].dart` returns no errors
- [ ] Run specific test file to check compilation

Example:
```bash
flutter analyze lib/services/backend_user_service_appwrite.dart
flutter test test/services/backend_user_service_appwrite_test.dart
```

---

## Success Criteria

✅ All 48+ tests compile without errors
✅ AppwritePhase1Service: 3/3 passing
✅ Phase1a Models: 14/14 passing
✅ Remaining tests either passing or with clear test-level failures (not compilation)
✅ No "Error when reading" or "missing required parameter" compilation errors

---

## Timeline

| Task | Duration | Status |
|------|----------|--------|
| Fix logActivity userName calls | 25 min | 🔄 Not started |
| Review model fields | 10 min | 🔄 Not started |
| Fix inventory service field names | 20 min | 🔄 Not started |
| Fix audit service redesign | 20 min | 🔄 Not started |
| Fix type issues & null checks | 10 min | 🔄 Not started |
| Run full test suite | 5 min | 🔄 Not started |
| **TOTAL** | **90 min** | **🔄 In progress** |

---

## If Stuck

1. Use `flutter analyze lib/services/[file].dart` to see all errors in a file
2. Read the full error message - it usually says what field/param is expected
3. Check the actual model definition in `lib/models/` directory
4. Look at working services (AuditService) for correct patterns
5. Check test files for how models are supposed to be used

Good luck! 🚀
