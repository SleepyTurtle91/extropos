# MyInvois Dual API Quick Reference

## 🎯 Two APIs, One Integration

FlutterPOS integrates **BOTH** MyInvois APIs:

1. **e-Invoice API** - Core document submission

2. **Platform API** - Advanced features & ERP integration

---

## 📦 Import & Initialize

```dart
import 'package:extropos/services/myinvois_service.dart';

final myinvois = MyInvoisService.instance;
await myinvois.init();

```

---

## 🚀 Common Operations

### Submit Document (e-Invoice API)

```dart
final result = await myinvois.submitAndTrackDocument(document);
print('UID: ${result['submissionUID']}');

```

### Search Documents (Platform API)

```dart
final docs = await myinvois.searchDocumentsRobust(
  submissionDateFrom: '2026-01-01',
  submissionDateTo: '2026-01-23',
);

```

### Get Document (Both APIs)

```dart
// Consolidated (Platform API - preferred)

final doc = await myinvois.getCompleteDocumentInfo(uuid);

// Raw (e-Invoice API)
final raw = await myinvois.einvoice.getDocument(uuid);

```

### Validate TIN (Both APIs)

```dart
// Extended (Platform API - recommended)

final info = await myinvois.validateTin('C1234567890', extended: true);

// Basic (e-Invoice API)
final basic = await myinvois.validateTin('C1234567890', extended: false);

```

### Cancel Document (e-Invoice API)

```dart
await myinvois.einvoice.cancelDocument(uuid, 'Reason');

```

---

## 🔔 Notifications (Platform API Only)

```dart
// Get pending notifications
final notifs = await myinvois.getPendingNotifications();

// Get unread count (for badge)
final count = await myinvois.getUnreadCount();

// Mark as read
await myinvois.markNotificationRead(notifId);

```

---

## 🏥 System Health

```dart
// Comprehensive diagnostics
final health = await myinvois.getSystemHealth();
print('Status: ${health['overallStatus']}'); // HEALTHY/DEGRADED
print('e-Invoice API: ${health['einvoiceAPI']}');
print('Platform API: ${health['platformAPI']}');

// Quick test
final ok = await myinvois.testFullConnection();

```

---

## 📚 Reference Data (Platform API Only)

```dart
// Document types (01-Invoice, 02-Credit Note, etc.)
final docTypes = await myinvois.getDocumentTypes();

// Classification codes (units, categories, etc.)
final units = await myinvois.getClassificationCodes(codeType: 'UNIT');
final countries = await myinvois.getClassificationCodes(codeType: 'COUNTRY');
final states = await myinvois.getClassificationCodes(codeType: 'STATE');

```

---

## 🔑 Direct API Access

### e-Invoice API (Core)

```dart
myinvois.einvoice.authenticate()
myinvois.einvoice.submitDocuments([doc])
myinvois.einvoice.getDocument(uuid)
myinvois.einvoice.cancelDocument(uuid, reason)
myinvois.einvoice.getRecentDocuments()
myinvois.einvoice.validateTin(tin)
myinvois.einvoice.testConnection()

```

### Platform API (Advanced)

```dart
myinvois.platform.searchDocuments(...)
myinvois.platform.getNotifications()
myinvois.platform.markNotificationRead(id)
myinvois.platform.getDocumentTypes()
myinvois.platform.getClassificationCodes()
myinvois.platform.validateTinExtended(tin)
myinvois.platform.validateMsic(code)
myinvois.platform.rejectDocument(uuid, reason)
myinvois.platform.getConsolidatedDocument(uuid)
myinvois.platform.getSystemStatus()
myinvois.platform.getApiVersion()

```

---

## ⚙️ Configuration Check

```dart
if (!myinvois.isConfigured) {
  // Navigate to Settings → e-Invoice Configuration
}

if (!myinvois.isEnabled) {
  // e-Invoice is disabled
}

final info = myinvois.getServiceInfo();
print('Environment: ${info['environment']}');
print('TIN: ${info['tin']}');

```

---

## 🌐 Environment URLs

| Environment | Identity/API URL |
|-------------|-----------------|
| **Sandbox** | `https://preprod-api.myinvois.hasil.gov.my` |

| **Production** | `https://api.myinvois.hasil.gov.my` |

---

## 📄 Document Types

| Code | Type |
|------|------|
| `01` | Invoice |
| `02` | Credit Note |
| `03` | Debit Note |
| `04` | Refund Note |
| `11` | Self-billed Invoice |
| `12` | Self-billed Credit Note |
| `13` | Self-billed Debit Note |
| `14` | Self-billed Refund Note |

---

## 📊 Status Values

- `Valid` - Document accepted

- `Invalid` - Document rejected

- `Cancelled` - Document cancelled

- `Submitted` - Pending validation

---

## ⚠️ Error Handling

```dart
try {
  await myinvois.submitAndTrackDocument(doc);
} on Exception catch (e) {
  if (e.toString().contains('Authentication failed')) {
    // Invalid credentials
  } else if (e.toString().contains('Invalid submission')) {
    // Document validation error
  } else if (e.toString().contains('Duplicate submission')) {
    // Wait before retry
  } else {
    // Other errors
  }
}

```

---

## 🎨 UI Components

### Configuration Screen

**Path**: Settings → e-Invoice Configuration

**Features**:

- Overview card (environment, status)

- Environment selector (Sandbox/Production)

- Credentials (Client ID/Secret)

- Business profile (TIN, name, address)

- Test Connection button

- **System Diagnostics button** ✨ NEW

### System Diagnostics Dialog

Shows:

- Configuration status

- API health (e-Invoice + Platform)

- Endpoints

- API version

- Timestamp

---

## 🆚 API Comparison

| Feature | e-Invoice API | Platform API |
|---------|--------------|--------------|
| Document submission | ✅ | ❌ |
| Document cancellation | ✅ | ❌ |
| Document retrieval | ✅ Basic | ✅ Consolidated |
| Document search | ✅ Recent 31d | ✅ Advanced filters |
| TIN validation | ✅ Basic | ✅ Extended |
| Notifications | ❌ | ✅ |
| Document types | ❌ | ✅ |
| Classification codes | ❌ | ✅ |
| MSIC validation | ❌ | ✅ |
| Document rejection | ❌ | ✅ |
| System status | ❌ | ✅ |
| ERP integration | ❌ | ✅ |

---

## 💡 Best Practices

1. **Use unified service** for convenience

2. **Use `searchDocumentsRobust()`** for auto-fallback

3. **Use `validateTin()` with `extended: true`** for complete info

4. **Use `getCompleteDocumentInfo()`** for ERP integration

5. **Test in Sandbox** before Production

6. **Check `isConfigured`** before operations

7. **Use `getSystemHealth()`** for diagnostics

---

## 📖 Full Documentation

- **Integration Guide**: `MYINVOIS_INTEGRATION_GUIDE.md`

- **e-Invoice API**: <https://sdk.myinvois.hasil.gov.my/einvoicingapi/>

- **Platform API**: <https://sdk.myinvois.hasil.gov.my/api/>

- **Portal**: <https://myinvois.hasil.gov.my>

---

## 🛠️ Service Files

- `lib/services/myinvois_service.dart` - Unified facade

- `lib/services/einvoice_service.dart` - e-Invoice API

- `lib/services/myinvois_platform_service.dart` - Platform API

- `lib/screens/einvoice_config_screen.dart` - Configuration UI

---

*Last Updated: January 23, 2026*
