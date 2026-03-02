# E-Invoice Module - Quick Start Guide

**Status**: ✅ Priority 1 Complete - Ready for Sandbox Testing  
**Last Updated**: January 2026  
**Version**: 1.0.27

---

## 🎯 In 30 Seconds

The E-Invoice module is **production-ready for sandbox testing**:

- ✅ **8 focused Dart files** organized in 3-layer architecture
- ✅ **All models API-compliant** with official MyInvois specification
- ✅ **Batch validation** enforces 100 docs / 5 MB / 300 KB limits
- ✅ **Status display** uses official API values
- ✅ **Rate limit warnings** for 50+ documents
- ✅ **Comprehensive documentation** for developers and testers

**Compliance Score**: 75/100 (was 65/100 before fixes)

---

## 📁 Where Are the Files?

```
lib/
├── models/einvoice/
│   ├── submission.dart              (48 lines) - Submission record model
│   ├── unconsolidated_receipt.dart  (70 lines) - Receipt batch model
│   └── lhdn_config.dart             (53 lines) - API credentials config
├── services/
│   ├── einvoice_business_logic_service.dart    (200+ lines) - Pure logic
│   └── [einvoice_service.dart]                 (existing - will enhance in Phase 2)
└── screens/
    ├── einvoice_module_screen.dart      (210 lines) - Main orchestrator
    ├── submissions_screen.dart          (180 lines) - History display
    ├── consolidate_screen.dart          (324 lines) - Batch submission
    └── lhdn_config_dialog.dart          (200 lines) - Config dialog

Documentation/
├── EINVOICE_REFACTORING_GUIDE.md              (500+ lines)
├── MYINVOIS_API_COMPLIANCE_AUDIT.md           (450 lines)
├── MYINVOIS_COMPLIANCE_FIXES_SUMMARY.md       (250 lines)
├── PRIORITY_2_IMPLEMENTATION_GUIDE.md         (300+ lines)
├── EINVOICE_IMPLEMENTATION_STATUS.md          (400+ lines)
├── EINVOICE_DEPLOYMENT_CHECKLIST.md           (300+ lines)
└── EINVOICE_QUICK_START_GUIDE.md              (this file)
```

---

## 🚀 Get Started in 3 Steps

### Step 1: Understand the Architecture (5 min)
Read the first 100 lines of `EINVOICE_REFACTORING_GUIDE.md` to understand:
- Layer A: Business logic (pure Dart, no UI dependencies)
- Layer B: Widgets (reusable components)
- Layer C: Screens (main orchestration)

### Step 2: Review What Changed (10 min)
Read `MYINVOIS_COMPLIANCE_FIXES_SUMMARY.md` to see:
- What was fixed in Phase 3
- Why each fix was needed
- How to test the changes

### Step 3: Deploy to Sandbox (follow checklist)
Use `EINVOICE_DEPLOYMENT_CHECKLIST.md`:
- 15 min pre-deployment verification
- 20 min sandbox setup
- 45 min functional testing
- Sign off and deploy

---

## 📋 What's Working? (Before You Test)

### ✅ Fully Implemented
```
✓ Submit receipts to MyInvois (with batch validation)
✓ Display submission history
✓ Search & filter submissions
✓ Configure MyInvois credentials in app
✓ Calculate tax amounts (6% default)
✓ Format currency (RM symbol)
✓ Warn users about large batches (50+ documents)
✓ Show official API status values
✓ All models parse API responses correctly
✓ Validation enforces 100 docs / 5 MB / 300 KB limits
```

### ⚠️ Partially Implemented (Priority 2)
```
⚠ Error handling (generic, not specific error codes)
⚠ Retry logic (not implemented yet)
⚠ Rate limiting (warnings only)
```

### ❌ Not Yet Implemented (Priority 3)
```
✗ Document cancellation
✗ Advanced search
✗ Webhook notifications
✗ Audit logging
```

---

## 🧪 Quick Testing Guide

### Test 1: Simple Submission (2 min)
```
1. Open E-Invoice Module → Consolidate tab
2. Create 2-3 receipts in POS
3. Click "Submit to MyInvois"
4. Verify success message and submission UID
```

### Test 2: Batch Validation (2 min)
```
1. Create 101 receipts
2. Try to submit
3. Verify: Error message "Cannot submit more than 100 documents"
4. Delete 1 receipt
5. Verify: Error clears, submit succeeds
```

### Test 3: Status Display (1 min)
```
1. Go to Submissions tab
2. Click on any submission
3. Verify: Status shows "Awaiting Validation" (not "Awaiting Validation")
```

### Test 4: Field Mapping (2 min)
```
1. Submit a receipt
2. Check database: SELECT * FROM submissions WHERE id = '<submissionUID>'
3. Verify: All fields match API response (id, date, buyer, total, status)
```

---

## 🔧 Most Important Files to Know

### 1. Models (Data Layer)
**What**: Define the data structures  
**Where**: `lib/models/einvoice/`  
**Key Changes in Phase 3**:
- `submission.dart`: Added API field mapping (submissionUID → id)
- `unconsolidated_receipt.dart`: Expanded from 4 → 13 fields

**You need to know**: How to parse API responses using fromJson()

---

### 2. Business Logic Service
**What**: Pure Dart calculations and validations (NO Flutter imports)  
**Where**: `lib/services/einvoice_business_logic_service.dart`  
**Key Methods**:
- `validateSubmissionBatch()`: Enforces 100/5MB/300KB limits
- `calculateTaxAmount()`: 6% tax calculation
- `isConfigValid()`: Validates API credentials
- `shouldWarnAboutRateLimit()`: Returns true if >50 documents

**You need to know**: These methods are 100% testable (no UI dependencies)

---

### 3. Main Orchestrator Screen
**What**: Routes between Submissions and Consolidate tabs  
**Where**: `lib/screens/einvoice_module_screen.dart`  
**Key Changes in Phase 3**:
- Uses `Submission.fromJson()` for API-compliant parsing
- Added `_getStatusDisplay()` for user-friendly status labels

**You need to know**: This screen connects everything together

---

### 4. Consolidate Screen
**What**: UI for submitting batch of receipts  
**Where**: `lib/screens/consolidate_screen.dart`  
**Key Changes in Phase 3**:
- Adds orange warning banner when >50 documents (proactive limit notification)

**You need to know**: Shows users why we recommend batch splitting

---

## 🐛 Common Issues You Might Hit

### Issue 1: "Field not found" error when parsing API response
**Cause**: Using old field names (e.g., `id` instead of `submissionUID`)  
**Solution**: Use `Submission.fromJson()` which handles field mapping  
**Code**:
```dart
// ✅ CORRECT
final submission = Submission.fromJson(apiResponse);

// ❌ WRONG
final id = apiResponse['id'];  // API has 'submissionUID'
```

---

### Issue 2: Status shows wrong value
**Cause**: API uses official values (Valid/Invalid/Submitted/Cancelled)  
**Solution**: Use `_getStatusDisplay()` to convert to user-friendly labels  
**Code**:
```dart
// ✅ CORRECT
String displayStatus = getStatusDisplay(submission.status);
// Returns: "Awaiting Validation", "Validated", "Failed Validation", "Cancelled"

// ❌ WRONG
String displayStatus = submission.status;
// Shows raw API value: "Submitted", "Valid", "Invalid", "Cancelled"
```

---

### Issue 3: Test fails because extra fields missing
**Cause**: Model was updated in Phase 3 to capture more fields  
**Solution**: Update test mocks to include all 13 fields  
**Fix**:
```dart
// Add these fields to your test mock:
'uuid': 'abc123...',
'invoiceCodeNumber': 'INV001',
'totalSales': 100.0,
'totalDiscount': 0.0,
'netAmount': 100.0,
'buyerName': 'Customer',
'buyerTin': '123456789012',
'dateTimeValidated': '2026-01-20T10:30:00Z',
```

---

### Issue 4: Validation error for >100 documents
**Cause**: MyInvois API hard limit - cannot accept >100 docs per submission  
**Solution**: Split into multiple submissions (recommended: <50 per batch)  
**What the UI Shows**:
```
❌ Error: "Cannot submit more than 100 documents in a single batch"
💡 Tip: "Consider splitting into multiple batches of 50 documents"
```

---

### Issue 5: "Submission exceeds maximum size" error  
**Cause**: Total JSON size >5 MB  
**Solution**: Reduce number of receipts or reduce data per receipt  
**What the UI Shows**:
```
❌ Error: "Submission exceeds 5 MB limit"
💡 Tip: "Please submit in smaller batches"
```

---

## 📚 Documentation Map

| Document | Purpose | Read If... |
|----------|---------|-----------|
| **EINVOICE_REFACTORING_GUIDE.md** | Architecture & design patterns | You're new to the project |
| **MYINVOIS_API_COMPLIANCE_AUDIT.md** | What was wrong, how it's fixed | You want details on Phase 3 changes |
| **MYINVOIS_COMPLIANCE_FIXES_SUMMARY.md** | Quick overview of 5 Priority 1 fixes | You want a 2-minute summary |
| **PRIORITY_2_IMPLEMENTATION_GUIDE.md** | How to implement error handling | You're starting Phase 2 work |
| **EINVOICE_IMPLEMENTATION_STATUS.md** | Full project status & roadmap | You're reporting to management |
| **EINVOICE_DEPLOYMENT_CHECKLIST.md** | Step-by-step deployment guide | You're deploying to sandbox/production |
| **EINVOICE_QUICK_START_GUIDE.md** | This file - quick reference | You're just getting started |

---

## 🎓 Key Concepts to Understand

### Concept 1: Three-Layer Architecture
```
Layer A (Logic)      → Pure Dart services
                       No Flutter imports
                       100% testable
                       Examples: EInvoiceBusinessLogicService

Layer B (Widgets)    → Reusable UI components
                       Accept data via parameters
                       No business logic in build()
                       Examples: LoyaltyPointsCard

Layer C (Screens)    → Screen orchestration
                       Imports Layer A and Layer B
                       Manages navigation
                       Examples: EInvoiceModuleScreen
```

**Why It Matters**: Makes code testable, reusable, and maintainable

---

### Concept 2: API Field Mapping
```
MyInvois API Returns    →    Our Model Stores As
submissionUID           →    id
dateTimeReceived        →    date
buyerName               →    buyer
status (Valid,Invalid)  →    status (official values)
totalSales              →    total
totalDiscount           →    (new field in Phase 3)
netAmount               →    (new field in Phase 3)
```

**Why It Matters**: Ensures our data matches what the government API actually returns

---

### Concept 3: Batch Limits (Hard Constraints)
```
✓ Maximum 100 documents per submission
✓ Maximum 5 MB total size per submission
✓ Maximum 300 KB per individual document
✓ Recommended: <50 documents per batch (for rate limiting)
```

**Why It Matters**: The API will reject submissions exceeding these limits

---

### Concept 4: Status Values (Official Only)
```
From API        →  Display to User       →  User Sees
Submitted       →  "Awaiting Validation" →  ⏳ Pending
Valid           →  "Validated"           →  ✓ Approved
Invalid         →  "Failed Validation"   →  ✗ Rejected
Cancelled       →  "Cancelled"           →  ✗ Cancelled
```

**Why It Matters**: Government system uses these exact values - no custom names allowed

---

## ⚡ Quick Commands Reference

```bash
# Check code quality
flutter analyze

# Format all code
flutter format lib/ -r

# Run all tests
flutter test

# Build for Android
./build_flavors.ps1 pos release

# Check database
adb shell sqlite3 /data/data/com.extropos.pos/databases/pos.db

# View app logs
flutter logs

# Clean build cache
flutter clean && flutter pub get
```

---

## 🔐 Security Considerations

### Never Commit
```
✗ API credentials (Client ID, Client Secret)
✗ Business TIN or tax numbers
✗ Customer data
✗ Test API keys
```

### Always Use
```
✓ HTTPS for all API calls
✓ Environment variables for secrets
✓ Encrypted storage for credentials (if available)
✓ Validate all API responses
✓ Don't log sensitive data
```

---

## 📞 Getting Help

### If You Find a Bug
1. Describe steps to reproduce
2. Include error message or screenshot
3. Check `MYINVOIS_API_COMPLIANCE_AUDIT.md` if it's a known issue
4. File issue with tag `[e-invoice]`

### If You Have Questions
1. Check the relevant documentation (see Documentation Map above)
2. Search previous issues/discussions
3. Ask on team Slack #e-invoice channel
4. Reference this Quick Start Guide if applicable

### If You're Adding New Code
1. Follow the three-layer architecture
2. Keep files under 500 lines
3. Add unit tests (for Layer A)
4. Document public methods
5. Update relevant documentation

---

## ✅ Pre-Deployment Checklist (5 min)

Before you start sandbox testing:

```
Code Quality:
  [ ] flutter analyze (no errors)
  [ ] flutter format lib/ (code formatted)
  [ ] flutter test (tests pass)
  
Files in Place:
  [ ] lib/models/einvoice/*.dart (3 files)
  [ ] lib/services/*einvoice*.dart (2 files)
  [ ] lib/screens/*einvoice*.dart (4 files)
  
Documentation:
  [ ] All .md files in workspace root (6 files)
  [ ] EINVOICE_DEPLOYMENT_CHECKLIST.md accessible
  
Credentials Ready:
  [ ] MyInvois Sandbox account
  [ ] Client ID and Client Secret
  [ ] Business TIN
  
Ready to Test:
  [ ] Read EINVOICE_DEPLOYMENT_CHECKLIST.md
  [ ] Understand test scenarios
  [ ] Have sandbox environment setup
```

---

## 🎉 You're Ready!

**Next Steps**:
1. Read the [Deployment Checklist](EINVOICE_DEPLOYMENT_CHECKLIST.md)
2. Set up MyInvois sandbox account
3. Run the functional tests (follow the checklist)
4. Document any issues found
5. Implement Priority 2 fixes if needed

**Expected Outcome**: 
- ✅ All functional tests pass
- ✅ No critical issues found
- ✅ Ready to move to UAT/production
- ✅ Team trained on new module

---

**Questions?** Check the [Documentation Map](#-documentation-map) above or search in MYINVOIS_API_COMPLIANCE_AUDIT.md for specific topics.

**Version**: 1.0 (Quick Start)  
**Last Updated**: January 2026  
**Status**: Ready for Sandbox Deployment ✅

