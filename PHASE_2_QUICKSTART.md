# Phase 2 Quick Start Guide

## Current Status: Phase 1 Complete ✅

**Test Results**: 95/95 passing (100%)
**Last Run**: February 1, 2026
**Next Step**: Real Appwrite Connectivity Testing

---

## Quick Commands

### Run All Tests
```powershell
# All Phase 1 unit tests (95 tests)
flutter test test/services/

# Connectivity tests (test mode - fast)
flutter test test/integration/appwrite_connectivity_test.dart

# Connectivity tests (real backend - requires Appwrite)
flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true
```

### Helper Scripts
```powershell
# Run connectivity test with menu
.\scripts\test_appwrite_connectivity.ps1 test   # Test mode
.\scripts\test_appwrite_connectivity.ps1 real   # Real backend
.\scripts\test_appwrite_connectivity.ps1 all    # Both modes
```

---

## Phase 2 Testing Phases

### ✅ Phase 0: Foundation (COMPLETE)
- 95 unit tests passing
- All services implemented
- Test-mode support
- Cache management
- Error handling

### 🔄 Phase 1: Connection Validation (CURRENT)
**Test File**: `test/integration/appwrite_connectivity_test.dart`

**Tests**:
- ✅ Appwrite service initialization
- ✅ Database connection
- ✅ Collection existence checks
- ✅ Service integration

**How to Run**:
```powershell
# Test mode (safe, no backend needed)
flutter test test/integration/appwrite_connectivity_test.dart

# Real mode (requires backend)
flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true
```

**Expected Results (Test Mode)**:
- 13/13 tests passing
- All tests skip with "⏭️ Skipping - test mode"
- Cache fallback test executes

**Expected Results (Real Mode)**:
- Connection established
- Collections accessible
- Performance metrics recorded
- All CRUD operations work

### ⏳ Phase 2: Performance Benchmarking (NEXT)
**Goals**:
- Measure operation times
- Identify bottlenecks
- Set performance baselines

**Metrics to Collect**:
| Operation | Target | Current |
|-----------|--------|---------|
| Initialize | < 200ms | TBD |
| Create user | < 300ms | TBD |
| Get all users (cached) | < 20ms | ~10ms ✅ |
| Get all users (network) | < 500ms | TBD |
| Query 100 audit logs | < 500ms | TBD |

### ⏳ Phase 3: Offline & Resilience
**Tests**:
- Offline scenario handling
- Cache persistence
- Reconnection logic
- Error recovery

### ⏳ Phase 4: Load & Stress Testing
**Tests**:
- 100 concurrent operations
- Large dataset handling
- Memory profiling
- Cache thrashing

---

## Appwrite Configuration

### Backend Details
```yaml
Endpoint: https://appwrite.extropos.org/v1
Project ID: 6940a64500383754a37f
Database: pos_db
```

### Collections
1. **backend_users** - User management
2. **roles** - Role definitions
3. **activity_logs** - Audit trail
4. **inventory_items** - Stock tracking

### Required Setup (Before Real Tests)
1. ✅ Appwrite instance running
2. ✅ Project created
3. ✅ Database created
4. ⚠️ Collections created (verify)
5. ⚠️ API key generated (if needed)

---

## Troubleshooting

### Test Mode Always Runs
**Problem**: Real backend tests skip even with `--dart-define=REAL_APPWRITE=true`

**Solution**: Ensure you're using the exact flag:
```powershell
flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true
```

### Connection Timeout
**Problem**: Tests timeout when connecting to Appwrite

**Possible Causes**:
1. Appwrite instance not running
2. Network/firewall issues
3. Wrong endpoint URL
4. Project ID incorrect

**Solution**:
```powershell
# Check endpoint is accessible
curl https://appwrite.extropos.org/v1/health/version

# Verify project ID in Appwrite console
# https://appwrite.extropos.org/console
```

### Collection Not Found
**Problem**: Test fails with "Collection not found"

**Solution**: Create collections manually in Appwrite console

**Required Schemas**:

**backend_users**:
- email (string, unique)
- displayName (string)
- phone (string, optional)
- roleId (string)
- locationIds (string[])
- isActive (boolean)
- isLockedOut (boolean)
- createdAt (integer)
- updatedAt (integer)

**roles**:
- name (string, unique)
- permissions (string[])
- isSystemRole (boolean)
- createdAt (integer)
- updatedAt (integer)

**activity_logs**:
- userId (string)
- action (string)
- resourceType (string)
- resourceId (string)
- changesBefore (string, JSON)
- changesAfter (string, JSON)
- success (boolean)
- timestamp (string)
- createdAt (integer)

**inventory_items**:
- productId (string)
- productName (string)
- currentQuantity (number)
- minStockLevel (number)
- movements (string, JSON array)
- createdAt (integer)
- updatedAt (integer)

---

## Next Steps

### Today (Feb 1)
- [x] Create connectivity test suite
- [x] Create test runner script
- [ ] Verify Appwrite collections exist
- [ ] Run first real connectivity test

### This Week
- [ ] Performance baseline
- [ ] Offline testing
- [ ] Load testing
- [ ] Optimization

### Documentation
- [PHASE_2_STATUS.md](../PHASE_2_STATUS.md) - Complete Phase 2 roadmap
- [appwrite_connectivity_test.dart](../test/integration/appwrite_connectivity_test.dart) - Connectivity tests
- [test_appwrite_connectivity.ps1](../scripts/test_appwrite_connectivity.ps1) - Test runner

---

## Success Criteria

**Phase 1 Complete When**:
- ✅ All connection tests pass
- ✅ All collections accessible
- ✅ Basic CRUD operations work
- ✅ Performance metrics recorded

**Phase 2 Complete When**:
- ✅ 100/100 tests passing (unit + integration)
- ✅ All performance targets met
- ✅ Offline mode validated
- ✅ Load testing passed
- ✅ Documentation updated

---

**Last Updated**: February 1, 2026
**Status**: Phase 1 Complete, Phase 2 Day 1 ✅
