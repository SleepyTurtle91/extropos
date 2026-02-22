# Phase 2 Action Plan - First 24 Hours

**Start Date**: February 1, 2026  
**Objective**: Setup Appwrite infrastructure and validate backend connectivity

---

## ✅ Action Checklist (Do These Immediately)

### Step 1: Install Appwrite CLI (10 minutes)

```powershell
# Check if installed
appwrite --version

# If not installed, install globally
npm install -g appwrite-cli

# Verify installation
appwrite --version
# Expected: appwrite-cli version 6.x.x
```

**Status**: ⏳ Pending

---

### Step 2: Verify Appwrite Endpoint (5 minutes)

```powershell
# Test connection to Appwrite
$response = Invoke-WebRequest -Uri "https://appwrite.extropos.org/v1/health" -Method GET -SkipCertificateCheck -ErrorAction SilentlyContinue

if ($response.StatusCode -eq 200) {
    Write-Host "✅ Appwrite endpoint reachable"
    Write-Host "Response: $($response.Content)"
} else {
    Write-Host "❌ Appwrite endpoint not reachable"
}
```

**Status**: ⏳ Pending

---

### Step 3: Create All 6 Collections (15 minutes)

```powershell
# Run automated setup
.\scripts\setup_appwrite_collections.ps1

# You should see output like:
# ✅ Created collection: Backend Users [backend_users]
# ✅ Created collection: Roles [roles]
# ✅ Created collection: Activity Logs [activity_logs]
# ✅ Created collection: Inventory Items [inventory_items]
# ✅ Created collection: Products [products]
# ✅ Created collection: Categories [categories]
```

**Expected Duration**: 15-30 seconds  
**Status**: ⏳ Pending

---

### Step 4: Verify Collections in Console (5 minutes)

```
Navigate to: https://appwrite.extropos.org/console/project-6940a64500383754a37f/databases/database-pos_db
```

**Verification Checklist**:
- [ ] Can see 6 collections listed
- [ ] backend_users collection exists
- [ ] roles collection exists
- [ ] activity_logs collection exists
- [ ] inventory_items collection exists
- [ ] products collection exists (NEW)
- [ ] categories collection exists (NEW)

**Status**: ⏳ Pending

---

### Step 5: Test Real Backend Connectivity (10 minutes)

```powershell
# Run integration tests with real Appwrite backend
flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true

# Expected output:
# ✅ Appwrite service initializes successfully
# ✅ Can connect to database
# ✅ All required collections exist
# ✅ RoleService can fetch predefined roles
# ✅ UserService can list users
# ✅ InventoryService can list inventory items
# ✅ ProductService can list products
# ✅ CategoryService can list categories
# ... (4 more tests)
# ✅ All 15 tests passed!
```

**Success Criteria**:
- [ ] All 15 integration tests pass
- [ ] No compilation errors
- [ ] Connection to Appwrite confirmed
- [ ] All 6 collections accessible

**Status**: ⏳ Pending

---

### Step 6: Run Full Phase 1 Test Suite (5 minutes)

```powershell
# Verify all Phase 1 tests still pass
flutter test --reporter compact 2>&1 | Select-String "test" -Pattern "528.*passed|failed"

# Expected output:
# ✅ 528 tests passing (includes 119 Phase 1 + all others)
# ⏱️  Total duration: ~90 seconds
```

**Status**: ⏳ Pending

---

## 📋 Quick Reference

### Appwrite Project Details
```
Endpoint:  https://appwrite.extropos.org/v1
Project:   6940a64500383754a37f
Database:  pos_db
Console:   https://appwrite.extropos.org/console
```

### Collection IDs
```
backend_users      → User accounts with roles
roles              → RBAC roles and permissions
activity_logs      → Audit trail
inventory_items    → Stock tracking
products           → Product catalog (NEW)
categories         → Product categories (NEW)
```

### Key Services
```
AccessControlService           (27 tests) ✅
BackendUserServiceAppwrite     (11 tests) ✅
AuditService                   (18 tests) ✅
Phase1InventoryServiceAppwrite (18 tests) ✅
BackendProductServiceAppwrite  (25 tests) ✅ NEW
BackendCategoryServiceAppwrite (28 tests) ✅ NEW
```

---

## 🔧 Troubleshooting

### Issue: Appwrite CLI Not Found

```powershell
# Install globally
npm install -g appwrite-cli

# Or use npx (temporary)
npx appwrite --version
```

### Issue: Cannot Connect to Appwrite

```powershell
# Check firewall/network
Test-NetConnection -ComputerName appwrite.extropos.org -Port 443

# Check DNS
Resolve-DnsName appwrite.extropos.org

# Verify endpoint is correct
$uri = "https://appwrite.extropos.org/v1/health"
Invoke-WebRequest -Uri $uri -SkipCertificateCheck
```

### Issue: Collections Already Exist

```powershell
# Collections may already exist from previous setup
# This is OK - script will skip or update them
.\scripts\setup_appwrite_collections.ps1

# Or manually delete and recreate
# (See Appwrite console - Database > collections > delete > recreate)
```

### Issue: Integration Tests Fail

```powershell
# Check test mode vs real mode
flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true

# If still failing, check:
# 1. Appwrite endpoint is reachable
# 2. Database ID is correct (pos_db)
# 3. Project ID is correct (6940a64500383754a37f)
# 4. Collections exist in Appwrite console
```

---

## 📊 Expected Outcomes

### After Completing All Steps

✅ **Infrastructure**:
- Appwrite CLI installed and working
- 6 collections created in Appwrite
- Network connectivity verified
- All integration tests passing with real backend

✅ **Code Status**:
- Phase 1: 119/119 tests passing
- Integration: 15/15 tests passing
- No compilation errors
- Ready for Phase 2 development

✅ **Documentation**:
- Phase 1 complete with full documentation
- Phase 2 roadmap established
- Setup automation scripts working

---

## 🎯 Next Phase (After This Completes)

Once all above steps are complete, proceed with Phase 2:

1. **Sprint 1** (Days 1-5): Appwrite Attributes & Sample Data
2. **Sprint 2** (Days 6-15): Backend UI Development
3. **Sprint 3** (Days 16-20): POS Integration
4. **Sprint 4** (Days 21-28): Testing & Documentation

See [PHASE_2_ROADMAP.md](PHASE_2_ROADMAP.md) for detailed plan.

---

## 📞 Support

**Documentation**:
- [PHASE_1_DELIVERABLES.md](PHASE_1_DELIVERABLES.md) - Complete Phase 1 summary
- [PRODUCT_CATEGORY_APPWRITE_SETUP.md](PRODUCT_CATEGORY_APPWRITE_SETUP.md) - Detailed setup guide
- [PHASE_2_ROADMAP.md](PHASE_2_ROADMAP.md) - Complete Phase 2 plan
- [PHASE_2_QUICKSTART.md](PHASE_2_QUICKSTART.md) - Quick reference

**Test Files**:
- `test/integration/appwrite_connectivity_test.dart` - Real backend validation
- `test/services/backend_product_service_appwrite_test.dart` - Product service tests
- `test/services/backend_category_service_appwrite_test.dart` - Category service tests

---

## ⏰ Time Estimates

| Step | Time | Status |
|------|------|--------|
| 1. Install CLI | 10 min | ⏳ |
| 2. Verify Endpoint | 5 min | ⏳ |
| 3. Create Collections | 15 min | ⏳ |
| 4. Verify in Console | 5 min | ⏳ |
| 5. Test Connectivity | 10 min | ⏳ |
| 6. Run Full Tests | 5 min | ⏳ |
| **Total** | **50 minutes** | **⏳** |

---

## 🚀 Ready?

**When you're ready to start, execute in order:**

```powershell
# 1. Verify CLI
appwrite --version

# 2. Create collections
.\scripts\setup_appwrite_collections.ps1

# 3. Test real backend
flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true

# 4. Verify all tests
flutter test --reporter compact

# 5. Check status
Write-Host "✅ Phase 2 Infrastructure Ready!" -ForegroundColor Green
```

---

*Start Date: February 1, 2026*  
*Estimated Completion: February 1, 2026 (same day)*  
*Phase 1 Status: ✅ Complete (119/119 tests)*  
*Phase 2 Status: 🚀 Ready to Begin*
