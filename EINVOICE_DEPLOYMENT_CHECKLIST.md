# E-Invoice Module - Deployment Checklist

**Purpose**: Quick reference before sandbox testing deployment  
**Audience**: Developer, QA, DevOps  
**Status**: Ready to use

---

## Pre-Deployment Verification (15 min)

### Code Quality Check
- [ ] Run `flutter analyze` - no errors or warnings
- [ ] Run `flutter format lib/` - code properly formatted
- [ ] All files under 500 lines (check count with `wc -l`)
- [ ] No hardcoded API keys in code
- [ ] No debug `print()` statements left in production code
- [ ] All imports are organized (dart, package, relative)

### Testing
- [ ] Run `flutter test` - all existing tests pass
- [ ] No broken references to old code
- [ ] Model fromJson/toJson methods tested with sample API responses
- [ ] Validation methods tested with edge cases (0, 100, 101 documents)
- [ ] Currency formatting tested with various locales

### Documentation
- [ ] README updated with E-Invoice module description
- [ ] API credentials documented (where to get clientId, clientSecret)
- [ ] Tax calculation rules documented
- [ ] Batch limits clearly stated in code comments
- [ ] Error codes documented in comments

### File Organization
- [ ] All model files in `lib/models/einvoice/`
- [ ] All service files in `lib/services/`
- [ ] All screen files in `lib/screens/`
- [ ] Supporting documentation in workspace root

---

## MyInvois Sandbox Setup (20 min)

### Credentials Required
```
Before you can test, you need:
  [ ] MyInvois Sandbox Account (request from LHDN)
  [ ] Business TIN (number)
  [ ] Client ID (from MyInvois console)
  [ ] Client Secret (from MyInvois console)
  [ ] Admin Name & Email
```

### Sandbox Configuration
```
In App:
  1. Open Settings → E-Invoice Configuration
  2. Enter Business Profile:
     [ ] Business Name (e.g., "ABC Trading")
     [ ] TIN (e.g., "123456789012")
     [ ] Registration Number
  3. Enter API Credentials:
     [ ] Client ID
     [ ] Client Secret
  4. Click "Save Configuration"
```

### Environment Variables (if applicable)
```
If using environment-based config:
  [ ] MYINVOIS_API_URL=https://sandbox.myinvois.hasil.gov.my
  [ ] MYINVOIS_CLIENT_ID=[from sandbox console]
  [ ] MYINVOIS_CLIENT_SECRET=[from sandbox console]
```

---

## Functional Testing Checklist (45 min)

### Test 1: Submit Single Receipt
```
Steps:
  1. Open E-Invoice Module
  2. Click "Consolidate" tab
  3. Go to retail POS, create simple receipts (2-3 items)
  4. Receipt should auto-appear in Consolidate screen
  5. Click "Submit to MyInvois"
  6. Verify:
     ✓ Modal appears with submission summary
     ✓ Shows: document count, total amount, tax
     ✓ Validation passes (green checkmark)
  7. Click "Submit"
  8. Verify:
     ✓ Loading spinner appears
     ✓ After 2-5 seconds, success message shown
     ✓ Receipt now shows submissionUID
     ✓ Status shows "Awaiting Validation"
```

### Test 2: Submit Batch (50 Documents)
```
Steps:
  1. Create 50 receipts in POS
  2. Open Consolidate screen
  3. Verify:
     ✓ Orange warning banner appears
     ✓ Banner text shows: "You have 50 receipts"
     ✓ Recommendation to split batches shown
  4. Click submit
  5. Verify:
     ✓ Submission succeeds (API accepts 50 docs)
     ✓ No error about batch size
```

### Test 3: Batch Size Validation
```
Steps:
  1. Create 101 receipts
  2. Try to submit
  3. Verify:
     ✓ Validation error appears
     ✓ Error says: "Cannot submit more than 100 documents"
     ✓ Submit button is disabled
     ✓ Red error banner shown
  4. Remove 1 receipt
  5. Verify:
     ✓ Error clears
     ✓ Submit button enabled
     ✓ Submission succeeds
```

### Test 4: Field Mapping Verification
```
After successful submission, check database/API response:
  Verify these fields are captured correctly:
    ✓ submissionUID → stored as id
    ✓ dateTimeReceived → stored as date
    ✓ buyerName → stored as buyer (if applicable)
    ✓ status → shows as "Submitted" (official value)
    ✓ totalSales → preserved
    ✓ totalDiscount → preserved
    ✓ netAmount → preserved
```

### Test 5: Submission History Display
```
Steps:
  1. Go to "Submissions" tab
  2. Verify:
     ✓ All submitted receipts appear in list
     ✓ Status badge shows correct value
     ✓ Color coding correct (gold/orange for Submitted)
  3. Click on submission
  4. Verify:
     ✓ Details modal shows all fields
     ✓ Submission UID displayed
     ✓ Date formatted correctly
     ✓ Total amount shown with currency
```

### Test 6: API Credentials Update
```
Steps:
  1. Go to Settings → E-Invoice Config
  2. Update one field (e.g., TIN)
  3. Click "Save"
  4. Verify:
     ✓ Success message shown
     ✓ New value persisted in database
  4. Try submission with wrong credentials
  5. Verify:
     ✓ Appropriate error message shown
     ✓ User can update and retry
```

### Test 7: Tax Calculation
```
Steps:
  1. Create receipt with:
     Subtotal: RM 100
  2. Consolidate screen should show:
     ✓ Subtotal: RM 100.00
     ✓ Tax (6%): RM 6.00
     ✓ Total: RM 106.00
  3. Verify with various amounts and tax rates
```

### Test 8: Responsive Design
```
Test on multiple devices:
  [ ] Windows desktop (1920×1080)
    - All UI elements visible
    - Columns layout correct (4 columns)
    - No overflow or truncation
  
  [ ] Tablet (iPad/Android 10" device)
    - Layout adapts to tablet size
    - Columns layout correct (2-3 columns)
    - Touch targets are adequate size
  
  [ ] Mobile (Android phone)
    - Layout adapts to small screen
    - Columns layout correct (1 column)
    - Scrolling works smoothly
```

---

## Error Scenario Testing (30 min)

### Scenario 1: Invalid Credentials
```
Setup: Use wrong Client ID/Secret

Expected:
  ✓ Submission attempt fails
  ✓ Error message: "Authentication failed"
  ✓ User prompted to update credentials
  ✓ Settings link provided
```

### Scenario 2: Network Timeout
```
Setup: Simulate slow/unreliable connection (use proxy)

Expected:
  ✓ Loading spinner shows for extended time
  ✓ Timeout error after 60 seconds
  ✓ User option to retry
  ✓ No data corruption or duplicates
```

### Scenario 3: Large Submission (e.g., 5.5 MB)
```
Setup: Create receipts that total >5 MB

Expected:
  ✓ Validation error appears before submit
  ✓ Error clearly states: "Submission exceeds 5 MB limit"
  ✓ Recommendation to split batches
  ✓ Submit button disabled
```

### Scenario 4: Empty Submission
```
Setup: Try to submit with 0 receipts

Expected:
  ✓ Validation fails
  ✓ Error: "No documents to submit"
  ✓ Submit button disabled
```

---

## Mobile App Build (10 min)

### Building for Android
```bash
# Build APK (debug)
flutter build apk --debug --flavor posApp

# Build APK (release)
flutter build apk --release --flavor posApp

# Verify APK
flutter install
```

### Building for Windows
```bash
# Build executable
flutter build windows --release --flavor posApp

# Test on different Windows versions
  [ ] Windows 10
  [ ] Windows 11
```

### Pre-Deployment Build Test
```
[ ] Build completes without errors
[ ] No build warnings (resolve or suppress documented)
[ ] APK size reasonable (<100 MB)
[ ] App launches without crashes
[ ] E-Invoice module accessible from main menu
```

---

## Database Verification

### Check Database Schema
```sql
-- Verify these tables exist and have data
SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%invoice%';
```

### Verify Sample Data
```
[ ] Sample submission record in submissions table
[ ] Receipt data stored in consolidation table
[ ] Tax amounts calculated correctly
[ ] Timestamps in correct format
[ ] No orphaned records
```

### Backup Database
```bash
# Before testing, backup production database
adb shell pm backup com.extropos.pos
```

---

## Performance Baseline (5 min)

### Test with Production-Scale Data
```
Scenarios to test:
  [ ] Load screen with 1,000 submission records
  [ ] Search through 500+ submissions
  [ ] Sort by date/status on large dataset
  [ ] Submit batch of 100 documents
  
Acceptable Performance:
  ✓ List load: <2 seconds
  ✓ Search: <1 second
  ✓ Sort: <1 second
  ✓ Submit: <30 seconds (depends on network)
```

### Memory Usage
```
Verify during 1-hour continuous use:
  [ ] No memory leaks (use Android profiler)
  [ ] Memory stabilizes after initial load
  [ ] No sudden spikes during operations
```

---

## Localization Testing (if applicable)

### Test with Different Locales
```
[ ] English (en_US)
  - All text display correctly
  - Currency symbol correct (RM)
  - Date format correct (DD/MM/YYYY)

[ ] Malay (ms_MY)
  - All strings translated
  - UI layout adapts to RTL (if supported)
```

---

## Security Checklist

### Code Security
```
[ ] No hardcoded API keys
[ ] Credentials stored securely (not in code)
[ ] API calls use HTTPS only
[ ] Request/response logging doesn't expose secrets
[ ] No sensitive data in logs/crash reports
```

### Data Security
```
[ ] Database encryption enabled (if applicable)
[ ] API credentials encrypted in storage
[ ] Network traffic encrypted (HTTPS)
[ ] No cleartext transmission of TIN/business data
[ ] Proper access controls on data
```

### API Security
```
[ ] Using official MyInvois/Appwrite endpoints
[ ] Rate limiting prevents brute force attacks
[ ] Authentication properly validates credentials
[ ] No CORS issues if web-based
[ ] Request validation prevents injection attacks
```

---

## Documentation Handoff

### Files to Review
```
[ ] EINVOICE_REFACTORING_GUIDE.md
    - Read: Architecture section
    - Review: Code examples
    - Understand: Three-layer pattern

[ ] MYINVOIS_API_COMPLIANCE_AUDIT.md
    - Understand: Why each change was made
    - Reference: Field mapping table
    - Learn: API limits

[ ] EINVOICE_IMPLEMENTATION_STATUS.md
    - Overview: What's done, what's pending
    - Reference: Compliance score details
    - Plan: Next phases
```

### Runbooks to Create (if applicable)
```
[ ] "How to configure MyInvois credentials"
[ ] "How to troubleshoot submission failures"
[ ] "How to handle duplicate submission errors"
[ ] "How to batch large submissions"
[ ] "How to check submission status"
```

---

## Sign-Off Checklist

### Development Sign-Off
```
Developer Name: ___________________
Date: ___________________

I confirm:
  [ ] Code reviewed and tested
  [ ] All Priority 1 items complete
  [ ] Documentation complete
  [ ] Ready for QA testing
  
Signature: ___________________
```

### QA Sign-Off
```
QA Name: ___________________
Date: ___________________

I confirm:
  [ ] Functional tests passed
  [ ] Error scenarios validated
  [ ] Performance acceptable
  [ ] No blockers found
  [ ] Ready for sandbox deployment
  
Signature: ___________________
```

### Project Manager Sign-Off
```
PM Name: ___________________
Date: ___________________

I confirm:
  [ ] All deliverables received
  [ ] Schedule on track
  [ ] Ready for MyInvois sandbox testing
  [ ] Budget within limits
  
Signature: ___________________
```

---

## Deployment Command Quick Reference

```bash
# Stop any running processes
flutter clean
flutter pub get

# Run static analysis
flutter analyze

# Format code
flutter format lib/ -r

# Run tests
flutter test

# Build for Android
./build_flavors.ps1 pos release

# Build for Windows
flutter build windows --release --flavor posApp

# Install on emulator/device
flutter install

# View logs
flutter logs

# Run with DevTools
flutter run --devtools
```

---

## Rollback Plan

### If Critical Issues Found
```
1. Revert changes:
   git revert HEAD~5    # Adjust number as needed

2. Rebuild and deploy:
   ./build_flavors.ps1 pos release

3. Notify stakeholders:
   - Explain issue
   - Provide timeline for fix
   - Deploy hotfix when ready

4. Document lessons learned:
   - What went wrong
   - How to prevent next time
   - Update test cases
```

---

## Post-Deployment Monitoring (First 24 Hours)

### Monitor These Metrics
```
[ ] App crash rate (should be 0%)
[ ] MyInvois API error rate (should be <1%)
[ ] Average submission time (<30 seconds)
[ ] User feedback in support channel
[ ] Database synchronization status
```

### Check These Logs
```
[ ] App crash reports (Crashlytics/Firebase)
[ ] API error logs (check submission response codes)
[ ] Database migration logs
[ ] Authentication failures
```

### Escalation Procedure
```
If issues found:
  1. Alert: Technical Lead
  2. If critical: Pause deployment to other users
  3. Debug: Review logs and reproduce issue
  4. Fix: Implement hotfix if possible
  5. Verify: Test fix in sandbox
  6. Deploy: Redeploy when ready
  7. Communicate: Update users on progress
```

---

## Final Checklist Before Go-Live

```
BEFORE MOVING TO PRODUCTION:

Sandbox Testing Complete:
 [ ] All functional tests pass
 [ ] All error scenarios handled
 [ ] Performance acceptable
 [ ] Security review complete
 [ ] Documentation complete
 [ ] Team trained on new module

Priority 2 Implementation:
 [ ] Error handling implemented
 [ ] Rate limiting enforced
 [ ] Retry logic tested
 [ ] Integration tests written

User Acceptance Testing:
 [ ] Real business TIN tested
 [ ] Real receipts submitted successfully
 [ ] Stakeholders signed off
 [ ] No critical issues found 
 [ ] Support team ready to handle issues

Production Deployment:
 [ ] Database backed up
 [ ] Rollback plan documented
 [ ] Monitoring configured
 [ ] Support team briefed
 [ ] Deployment window scheduled
 [ ] Communication plan ready
```

---

## Quick Reference Links

- **MyInvois SDK**: https://sdk.myinvois.hasil.gov.my/
- **API Documentation**: https://sdk.myinvois.hasil.gov.my/einvoicingapi/
- **Sandbox Portal**: https://sandbox.myinvois.hasil.gov.my/
- **LHDN Contact**: https://www.hasil.gov.my/

---

**Version**: 1.0  
**Last Updated**: January 2026  
**Next Review**: After sandbox testing completion

