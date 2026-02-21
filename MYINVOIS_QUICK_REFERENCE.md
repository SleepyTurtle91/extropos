# MyInvois Quick Reference Card

## 🚀 Quick Start (3 Steps)

```
1. Settings → e-Invoice (Malaysia) → Toggle ON
2. Enter SST Number → Test Connection
3. Switch to Production (after successful test)

```

---

## 📍 Access Points

| Feature | Path |
|---------|------|
| **Settings** | Settings → e-Invoice (Malaysia) |

| **Queue** | Settings → MyInvois Queue |

| **Environment Badge** | POS AppBar (top-right) |

---

## 🎯 Key Concepts

### Environment Modes

```
OFF       → MyInvois disabled (no submissions)
SANDBOX   → Testing environment (safe)
PRODUCTION → Live submissions (requires test)

```

### Production Guard

```
Purpose: Prevent accidental production use
Default: 24 hours
Options: 6, 12, 24, 48, 72 hours
Rule: Must test within guard period to use production

```

### Sequence Numbers

```
Format: INV-YYYYMMDD-XXXX
Example: INV-20260123-0001
Reset: Daily at midnight
Storage: SharedPreferences

```

---

## ⚙️ Settings Screen

```
┌─────────────────────────────────────┐
│ MyInvois Settings                   │
├─────────────────────────────────────┤
│ [x] Enable MyInvois                 │
│                                      │
│ SST Number:                          │
│ [B12-1234-56789012]                 │
│                                      │
│ Environment:                         │
│ (●) Sandbox  ( ) Production         │
│                                      │
│ Production Guard:                    │
│ [24 hours ▼]                        │
│                                      │
│ Last Test:                           │
│ ✅ 2 hours ago                       │
│                                      │
│ [Test Connection] [Reset Defaults]  │
└─────────────────────────────────────┘

```

---

## 📋 Queue Screen

```
┌─────────────────────────────────────┐
│ MyInvois Queue (2 items)            │
├─────────────────────────────────────┤
│ Transaction: ORD-20260123-001       │
│ Queued: Jan 23, 10:30 AM            │
│ Retry: 1/3  Status: [Pending]      │
├─────────────────────────────────────┤
│ Transaction: ORD-20260123-005       │
│ Queued: Jan 23, 11:45 AM            │
│ Retry: 0/3  Status: [Pending]      │
├─────────────────────────────────────┤
│ [Retry All]  [Clear Queue]          │
└─────────────────────────────────────┘

```

---

## 🔄 Workflows

### Initial Setup

```
1. Open Settings → e-Invoice
2. Toggle Enable ON
3. Enter SST: B12-1234-56789012
4. Select Sandbox
5. Configure guard hours: 24
6. Test Connection → ✅ Success
7. Switch to Production (confirm dialog)
8. Check AppBar: [MyInvois: Production ●]

```

### Daily Operations

```
Checkout Flow:
Customer pays → Auto-submit invoice → Done
                       ↓
                   (if fails)
                       ↓
               Queue for retry

Check Queue:
Settings → MyInvois Queue → Retry All

```

### Switching Environments

```
Sandbox → Production:

- Must test within guard hours

- Confirmation dialog required

Production → Sandbox:

- Allowed anytime

- No confirmation needed

```

---

## 🚨 Production Guard Rules

| Scenario | Action | Result |
|----------|--------|--------|
| No test run | Switch to Production | ❌ BLOCKED |
| Test < guard hours | Switch to Production | ✅ ALLOWED |
| Test > guard hours | Switch to Production | ❌ BLOCKED |
| Any time | Switch to Sandbox | ✅ ALLOWED |

---

## 💡 Status Indicators

### AppBar Badge

```
[MyInvois: Off]       → Grey   → Disabled
[MyInvois: Sandbox]   → Orange → Testing
[MyInvois: Production]→ Green  → Live

```

### Guard Status

```
✅ Guard active    → Test within guard period
⏳ Guard expired   → Need to re-test

```

### Queue Status

```
[Pending]  → Orange chip → Waiting for retry
[Failed]   → Red chip    → Max retries reached

```

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't switch to Production | Test in Sandbox first |
| Submissions failing | Check internet, verify SST number |
| Queue growing | Retry All, check MyInvois status |
| Badge not updating | Reopen POS screen |
| Test button disabled | Enter SST number first |

---

## 📊 Developer API

```dart
// Service singleton
import 'package:flutterpos/services/my_invois_service.dart';

// Submit invoice
final uuid = await MyInvoiceService.submitInvoice(data);

// Check production guard
final canUse = await MyInvoiceService.canUseProduction();

// Queue management
final queue = await MyInvoiceService.getQueuedTransactions();
final success = await MyInvoiceService.retryQueuedSubmissions();
await MyInvoiceService.clearQueue();

// Sequence numbers
final invoiceNum = await MyInvoiceService._getNextSequenceNumber();
// Returns: INV-20260123-0001

```

---

## 📝 Data Storage

```dart
// SharedPreferences keys:
myinvois_environment         // 'sandbox' | 'production'
myinvois_sst_number         // 'B12-1234-56789012'
myinvois_guard_hours        // 6, 12, 24, 48, 72
myinvois_last_test          // ISO 8601 timestamp
myinvois_last_sequence_date // 'YYYYMMDD'
myinvois_sequence_number    // integer
myinvois_queue              // JSON string array

```

---

## ✅ Deployment Checklist

```
[ ] Enable MyInvois in Settings
[ ] Enter correct SST number
[ ] Test in Sandbox
[ ] Verify test success
[ ] Configure guard hours (24h recommended)
[ ] Switch to Production
[ ] Verify AppBar badge: Production
[ ] Process test sale
[ ] Confirm submission success
[ ] Check queue is empty

```

---

## 🎯 Key Features

✅ Sandbox/Production toggle  
✅ Production guard (6-72 hours)  
✅ Automatic submission on payment  
✅ Failed submission queue  
✅ Daily sequence numbers  
✅ Retry mechanism (max 3)  
✅ Visual environment indicators  
✅ Confirmation dialogs  
✅ Test connection tracking  

---

## 📞 Quick Support

**Common Commands:**

- Check queue: Settings → MyInvois Queue

- Retry failed: Queue → Retry All

- Clear queue: Queue → Clear Queue

- Reset settings: Settings → Reset Defaults

- Test connection: Settings → Test Connection

**Console Logs:**

- ✅ = Success

- ❌ = Error

- ⚠️ = Warning

- 🔄 = Retry

- 🗑️ = Cleanup

---

**Phase 1 Complete | Version 1.0.27+ | Production Ready**
