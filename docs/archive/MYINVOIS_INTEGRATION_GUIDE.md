# MyInvois Integration Guide

## Overview

FlutterPOS integrates with **two MyInvois APIs** for complete e-Invoice functionality:

1. **e-Invoice API** - Core document submission and management

2. **Platform API** - System integration, notifications, advanced features

## Architecture

```
MyInvoisService (Unified Facade)
├── EInvoiceService (e-Invoice API)
│   ├── Authentication (OAuth 2.0)
│   ├── Document submission
│   ├── Document retrieval
│   └── Basic search
│
└── MyInvoisPlatformService (Platform API)
    ├── Notifications
    ├── Advanced search
    ├── ERP integration
    ├── Document types
    ├── Classification codes
    └── System status

```

## API Endpoints Reference

### e-Invoice API Base URLs

- **Sandbox**: `https://preprod-api.myinvois.hasil.gov.my`

- **Production**: `https://api.myinvois.hasil.gov.my`

- **Documentation**: <https://sdk.myinvois.hasil.gov.my/einvoicingapi/>

### Platform API Base URLs

- **Sandbox**: `https://preprod-api.myinvois.hasil.gov.my`

- **Production**: `https://api.myinvois.hasil.gov.my`

- **Documentation**: <https://sdk.myinvois.hasil.gov.my/api/>

## Usage Examples

### 1. Basic Setup

```dart
import 'package:extropos/services/myinvois_service.dart';
import 'package:extropos/models/einvoice/einvoice_config.dart';

// Initialize service
final myinvois = MyInvoisService.instance;
await myinvois.init();

// Configure credentials
final config = EInvoiceConfig(
  clientId: 'your_client_id',
  clientSecret: 'your_client_secret',
  tin: 'C1234567890',
  businessName: 'Your Business Name',
  businessAddress: 'Your Address',
  identityServiceUrl: 'https://preprod-api.myinvois.hasil.gov.my',
  apiServiceUrl: 'https://preprod-api.myinvois.hasil.gov.my',
  isProduction: false,
  isEnabled: true,
);

await myinvois.einvoice.saveConfig(config);

```

### 2. Submit Document (e-Invoice API)

```dart
import 'package:extropos/models/einvoice/einvoice_document.dart';

// Create document
final document = EInvoiceDocument(
  invoiceCodeNumber: '01', // 01 = Invoice
  invoiceNumber: 'INV-2026-001',
  invoiceDate: DateTime.now(),
  supplierTin: 'C1234567890',
  supplierName: 'Your Business',
  supplierAddress: 'Your Address',
  buyerTin: 'C9876543210',
  buyerName: 'Customer Name',
  buyerAddress: 'Customer Address',
  lineItems: [
    EInvoiceLineItem(
      description: 'Product A',
      quantity: 2,
      unitPrice: 100.0,
      taxAmount: 12.0,
      totalAmount: 212.0,
    ),
  ],
  totalExcludingTax: 200.0,
  totalTax: 12.0,
  totalIncludingTax: 212.0,
);

// Submit via unified service
final result = await myinvois.submitAndTrackDocument(document);
print('Submission UID: ${result['submissionUID']}');
print('Status: ${result['status']}');

```

### 3. Search Documents (Platform API)

```dart
// Advanced search with filters
final results = await myinvois.platform.searchDocuments(
  submissionDateFrom: '2026-01-01',
  submissionDateTo: '2026-01-23',
  status: 'Valid',
  documentType: '01', // Invoice
  issuerTin: 'C1234567890',
  totalAmountFrom: 100.0,
  totalAmountTo: 10000.0,
  pageSize: 50,
);

print('Found ${results['totalPages']} pages');
for (var doc in results['result']) {
  print('Invoice: ${doc['invoiceNumber']} - RM ${doc['totalAmount']}');

}

// Or use unified robust search (auto-fallback)
final documents = await myinvois.searchDocumentsRobust(
  submissionDateFrom: '2026-01-01',
  submissionDateTo: '2026-01-23',
  status: 'Valid',
);

```

### 4. Notifications (Platform API)

```dart
// Get pending notifications
final notifications = await myinvois.getPendingNotifications();
print('You have ${notifications.length} notifications');

for (var notif in notifications) {
  print('${notif['title']}: ${notif['message']}');
  
  // Mark as read
  await myinvois.markNotificationRead(notif['id']);
}

// Get unread count for badge
final unreadCount = await myinvois.getUnreadCount();
print('Unread: $unreadCount');

```

### 5. Validate TIN (Both APIs)

```dart
// Extended validation (Platform API - recommended)

final tinInfo = await myinvois.validateTin('C1234567890', extended: true);
print('Business: ${tinInfo['businessName']}');
print('Address: ${tinInfo['address']}');
print('Registration: ${tinInfo['registrationDate']}');

// Basic validation (e-Invoice API)
final basicInfo = await myinvois.validateTin('C1234567890', extended: false);
print('Valid: ${basicInfo['valid']}');

```

### 6. System Health Check

```dart
// Comprehensive diagnostics
final health = await myinvois.getSystemHealth();
print('Overall: ${health['overallStatus']}'); // HEALTHY or DEGRADED
print('e-Invoice API: ${health['einvoiceAPI']}');
print('Platform API: ${health['platformAPI']}');
print('API Version: ${health['apiVersion']}');

// Quick connection test
final isHealthy = await myinvois.testFullConnection();
if (isHealthy) {
  print('All systems operational');
} else {
  print('Some services unavailable');
}

```

### 7. Get Reference Data (Platform API)

```dart
// Document types
final docTypes = await myinvois.getDocumentTypes();
for (var type in docTypes) {
  print('${type['code']}: ${type['name']}');
  // 01: Invoice
  // 02: Credit Note
  // 03: Debit Note
  // etc.
}

// Classification codes (item categories, units, etc.)
final units = await myinvois.getClassificationCodes(codeType: 'UNIT');
for (var unit in units) {
  print('${unit['code']}: ${unit['description']}');
  // C62: Unit (piece)
  // KGM: Kilogram
  // MTR: Meter
  // etc.
}

// Country codes
final countries = await myinvois.getClassificationCodes(codeType: 'COUNTRY');

// State codes
final states = await myinvois.getClassificationCodes(codeType: 'STATE');

```

### 8. ERP Integration (Platform API)

```dart
// Get consolidated document for ERP sync
final consolidatedDoc = await myinvois.getCompleteDocumentInfo(documentUuid);
print('Document: ${consolidatedDoc['document']}');
print('Metadata: ${consolidatedDoc['metadata']}');
print('Validation: ${consolidatedDoc['validation']}');

// For received invoices, reject if invalid
await myinvois.platform.rejectDocument(
  documentUuid,
  'Incorrect amount or missing items',
);

```

### 9. Cancel Document (e-Invoice API)

```dart
final cancelResult = await myinvois.einvoice.cancelDocument(
  documentUuid,
  'Cancelled by customer request',
);
print('Cancelled at: ${cancelResult['cancelledDateTime']}');

```

### 10. Error Handling

```dart
try {
  final result = await myinvois.submitAndTrackDocument(document);
} on Exception catch (e) {
  if (e.toString().contains('Authentication failed')) {
    // Invalid credentials
    print('Check Client ID/Secret');
  } else if (e.toString().contains('Invalid submission')) {
    // Document validation error
    print('Check document format');
  } else if (e.toString().contains('Duplicate submission')) {
    // Duplicate detected
    print('Wait before retrying');
  } else {
    // Other errors
    print('Error: $e');
  }
}

```

## UI Integration

### Configuration Screen

The e-Invoice config screen now includes:

- **Overview Card**: Environment/enabled status, test results

- **Environment Card**: Sandbox/Production selector with endpoint display

- **Credentials Card**: Client ID/Secret with visibility toggle

- **Business Card**: TIN, name, address, contact info

- **Actions Card**: Test Connection, Save, **System Diagnostics**

- **Help Card**: Documentation links

### System Diagnostics Button

Access via **Settings → e-Invoice Configuration → System Diagnostics**

Shows:

- Configuration status (environment, TIN, business name)

- API health (e-Invoice API, Platform API, overall status)

- Endpoints (identity URL, API URL)

- API version info

- Timestamp

## Best Practices

### 1. Always Check Configuration First

```dart
if (!myinvois.isConfigured) {
  showDialog(context: context, builder: (_) => AlertDialog(
    title: Text('e-Invoice Not Configured'),
    content: Text('Please configure MyInvois credentials in Settings.'),
  ));
  return;
}

if (!myinvois.isEnabled) {
  print('e-Invoice is disabled');
  return;
}

```

### 2. Use Unified Service for Convenience

```dart
// Prefer unified service
final myinvois = MyInvoisService.instance;

// Access specific APIs when needed
final eInvoiceApi = myinvois.einvoice;
final platformApi = myinvois.platform;

```

### 3. Handle Sandbox vs Production

```dart
final env = myinvois.config?.isProduction == true ? 'Production' : 'Sandbox';
print('Running in $env mode');

// Sandbox credentials are different from production
// Test thoroughly in Sandbox before switching to Production

```

### 4. Token Management

```dart
// Tokens are cached and auto-refreshed
// Manually clear on logout:
await myinvois.logout();

```

### 5. Robust Search with Fallback

```dart
// Use searchDocumentsRobust for automatic fallback
final docs = await myinvois.searchDocumentsRobust(
  submissionDateFrom: startDate,
  submissionDateTo: endDate,
);
// Tries Platform API first, falls back to e-Invoice API

```

## Service Comparison

| Feature | e-Invoice API | Platform API |
|---------|--------------|--------------|
| Document submission | ✅ | ❌ |
| Document cancellation | ✅ | ❌ |
| Document retrieval | ✅ (basic) | ✅ (consolidated) |
| Document search | ✅ (recent 31 days) | ✅ (advanced filters) |
| TIN validation | ✅ (basic) | ✅ (extended) |
| Notifications | ❌ | ✅ |
| Document types | ❌ | ✅ |
| Classification codes | ❌ | ✅ |
| MSIC validation | ❌ | ✅ |
| Document rejection | ❌ | ✅ |
| System status | ❌ | ✅ |
| ERP integration | ❌ | ✅ |

## Troubleshooting

### Authentication Errors

```dart
// Test connection
final success = await myinvois.einvoice.testConnection();
if (!success) {
  // Check credentials in Settings
  // Verify environment (Sandbox vs Production)
  // Ensure Client ID/Secret are correct
}

```

### Submission Errors

```dart
// Check validation
final tinValid = await myinvois.validateTin(buyerTin);
if (!tinValid['valid']) {
  print('Invalid buyer TIN');
}

// Check document format
// Ensure all required fields are present
// Verify line item calculations

```

### Platform API Unavailable

```dart
final available = await myinvois.platform.isPlatformAvailable();
if (!available) {
  print('Platform API unavailable, using e-Invoice API only');
  // Fallback to basic features
}

```

## Security Notes

1. **Never hardcode credentials** - Always use config storage

2. **Use Sandbox for testing** - Switch to Production only when ready

3. **Secure Client Secret** - Use obscured text fields in UI

4. **Token expiry** - Tokens expire after 1 hour (auto-refreshed)

5. **HTTPS only** - All API calls use secure connections

## References

- **MyInvois Portal**: <https://myinvois.hasil.gov.my>

- **e-Invoice API Docs**: <https://sdk.myinvois.hasil.gov.my/einvoicingapi/>

- **Platform API Docs**: <https://sdk.myinvois.hasil.gov.my/api/>

- **LHDNM Guidelines**: <https://www.hasil.gov.my>

## Support

For MyInvois technical support:

- **Email**: <myinvois@hasil.gov.my>

- **Portal**: <https://myinvois.hasil.gov.my/support>

- **Hotline**: 03-XXXX-XXXX (check portal for current number)
