# MyInvois Dual API Integration Summary

## What's New

FlutterPOS now integrates **BOTH** MyInvois APIs for complete e-Invoice functionality:

### 1. e-Invoice API (Existing)

- ✅ Document submission

- ✅ Document retrieval

- ✅ Document cancellation

- ✅ Recent document search (31 days)

- ✅ TIN validation

- ✅ OAuth 2.0 authentication

### 2. Platform API (New) ✨

- ✅ **Notifications** - System alerts and updates

- ✅ **Advanced search** - Filters by amount, status, date range

- ✅ **Document types** - Reference data for dropdowns

- ✅ **Classification codes** - Units, categories, countries

- ✅ **Extended TIN validation** - With address details

- ✅ **MSIC validation** - Industry classification

- ✅ **Document rejection** - Reject received invoices

- ✅ **ERP integration** - Consolidated document format

- ✅ **System health** - API status monitoring

## New Files Created

```
lib/services/
├── myinvois_service.dart              ← Unified facade (both APIs)
├── myinvois_platform_service.dart     ← Platform API implementation
└── einvoice_service.dart              ← e-Invoice API (existing)

docs/
├── MYINVOIS_INTEGRATION_GUIDE.md      ← Complete integration guide
└── MYINVOIS_DUAL_API_REFERENCE.md     ← Quick reference card

```

## Updated Files

```
lib/screens/einvoice_config_screen.dart
├── Redesigned with responsive card layout
├── Added test status tracking
├── Added System Diagnostics button
└── Shows comprehensive API health checks

```

## Usage Examples

### Before (Single API)

```dart
final einvoice = EInvoiceService.instance;
await einvoice.submitDocuments([document]);

```

### After (Unified Service)

```dart
final myinvois = MyInvoisService.instance;

// Submit with tracking
final result = await myinvois.submitAndTrackDocument(document);

// Advanced search
final docs = await myinvois.searchDocumentsRobust(...);

// Get notifications
final notifs = await myinvois.getPendingNotifications();

// System health
final health = await myinvois.getSystemHealth();

```

## UI Enhancements

### e-Invoice Configuration Screen

**New Layout**:

1. **Overview Card** - Environment badges, enable toggle, test status

2. **Environment Card** - Sandbox/Production selector with endpoints

3. **Credentials Card** - Client ID/Secret with visibility toggle

4. **Business Card** - TIN, name, address, contact info

5. **Actions Card** - Test Connection, Save, **System Diagnostics** ✨

6. **Help Card** - Documentation links

### System Diagnostics Dialog (New)

Shows:

- Configuration status (TIN, business name, environment)

- API health (e-Invoice API: OK/ERROR, Platform API: OK/ERROR)

- Overall status (HEALTHY/DEGRADED)

- Endpoints (identity URL, API URL)

- API version information

- Timestamp

## API Coverage

### e-Invoice API Endpoints

```
✅ POST   /connect/token                        (Auth)
✅ POST   /api/v1.0/documentsubmissions/        (Submit)
✅ GET    /api/v1.0/documentsubmissions/{uid}   (Get submission)
✅ GET    /api/v1.0/documents/{uuid}/raw        (Get document)
✅ GET    /api/v1.0/documents/recent            (Search recent)
✅ GET    /api/v1.0/taxpayer/validate/{tin}     (Validate TIN)
✅ PUT    /api/v1.0/documents/state/{uuid}/state (Cancel)

```

### Platform API Endpoints

```
✅ GET    /api/v1.0/notifications                (Get notifications)
✅ GET    /api/v1.0/notifications/{id}           (Get notification)
✅ PUT    /api/v1.0/notifications/{id}/read      (Mark read)
✅ GET    /api/v1.0/documents/search             (Advanced search)
✅ GET    /api/v1.0/documents/{uuid}/details     (Document details)
✅ GET    /api/v1.0/documents/{uuid}/consolidated (ERP format)
✅ GET    /api/v1.0/documenttypes                (Document types)
✅ GET    /api/v1.0/codes/classifications        (Classification codes)
✅ GET    /api/v1.0/codes/msic/{code}            (MSIC validation)
✅ GET    /api/v1.0/taxpayer/validate/{tin}/extended (Extended TIN)
✅ GET    /api/v1.0/submissions/{uid}/status     (Submission status)
✅ PUT    /api/v1.0/documents/{uuid}/reject      (Reject document)
✅ GET    /api/v1.0/status                       (System status)
✅ GET    /api/v1.0/version                      (API version)

```

## Key Features

### 1. Unified Service Facade

Single entry point for both APIs with intelligent fallback:

```dart
final myinvois = MyInvoisService.instance;

// Access e-Invoice API
myinvois.einvoice.submitDocuments([doc]);

// Access Platform API
myinvois.platform.getNotifications();

// Unified workflows (auto-fallback)
myinvois.searchDocumentsRobust(...);
myinvois.validateTin(tin, extended: true);

```

### 2. Automatic Fallback

Methods like `searchDocumentsRobust()` try Platform API first, then fall back to e-Invoice API if unavailable.

### 3. System Health Monitoring

```dart
final health = await myinvois.getSystemHealth();
// Returns:
// - einvoiceAPI: 'OK' | 'ERROR'

// - platformAPI: 'OK' | 'ERROR'

// - overallStatus: 'HEALTHY' | 'DEGRADED'

// - apiVersion: {...}

// - timestamp: '2026-01-23T...'

```

### 4. Comprehensive Error Handling

Both services have detailed error handling with specific error types for authentication, validation, and submission failures.

## Configuration

No changes to existing configuration. Same `EInvoiceConfig` model supports both APIs:

```dart
EInvoiceConfig(
  clientId: 'client_id',
  clientSecret: 'client_secret',
  tin: 'C1234567890',
  businessName: 'Business Name',
  identityServiceUrl: 'https://preprod-api.myinvois.hasil.gov.my',
  apiServiceUrl: 'https://preprod-api.myinvois.hasil.gov.my',
  isProduction: false,
  isEnabled: true,
)

```

## Testing

### Sandbox Testing

1. Configure with Sandbox credentials
2. Set `isProduction: false`
3. Test all features:

   - Document submission

   - Document search

   - TIN validation

   - Notifications

   - System health

### Production Testing

1. Test connection via config screen
2. Verify system diagnostics shows "HEALTHY"
3. Switch to Production
4. Re-test connection
5. Submit test document

## Documentation

| Document | Purpose |
|----------|---------|
| `MYINVOIS_INTEGRATION_GUIDE.md` | Complete integration guide with examples |
| `MYINVOIS_DUAL_API_REFERENCE.md` | Quick reference card for developers |
| `EINVOICE_MALAYSIA.md` | Original e-Invoice documentation (existing) |

## API References

- **e-Invoice API**: <https://sdk.myinvois.hasil.gov.my/einvoicingapi/>

- **Platform API**: <https://sdk.myinvois.hasil.gov.my/api/>

- **MyInvois Portal**: <https://myinvois.hasil.gov.my>

## Next Steps

### For Developers

1. Read `MYINVOIS_INTEGRATION_GUIDE.md`
2. Use `MyInvoisService` as single entry point
3. Test in Sandbox environment
4. Use System Diagnostics for troubleshooting

### For Users

1. Configure credentials in Settings → e-Invoice Configuration
2. Test connection via "Test Connection" button
3. Use "System Diagnostics" to verify both APIs are working
4. Switch to Production when ready

## Benefits

1. **Complete Feature Set** - Access all MyInvois capabilities

2. **Automatic Failover** - Robust methods fall back if one API unavailable

3. **Better Monitoring** - System health checks for both APIs

4. **Future-Proof** - Platform API provides notifications and ERP integration

5. **Single Interface** - Unified service facade simplifies usage

6. **No Breaking Changes** - Existing code continues to work

## Support

For technical support:

- **MyInvois Email**: <myinvois@hasil.gov.my>

- **MyInvois Portal**: <https://myinvois.hasil.gov.my/support>

- **FlutterPOS Docs**: `MYINVOIS_INTEGRATION_GUIDE.md`

---

*Integration completed: January 23, 2026*
