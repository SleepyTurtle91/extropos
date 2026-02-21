# Malaysian e-Invoice Implementation for FlutterPOS

## Overview

FlutterPOS now includes full integration with **MyInvois** - the official e-Invoice system mandated by **LHDNM (Lembaga Hasil Dalam Negeri Malaysia)** for Malaysian taxpayers.

This implementation enables:

- ✅ Automatic e-Invoice submission to MyInvois

- ✅ OAuth 2.0 authentication with MyInvois API

- ✅ UBL 2.1 compliant invoice format (JSON)

- ✅ Tax compliance with Malaysian tax regulations

- ✅ Sandbox and Production mode support

- ✅ Document management and tracking

- ✅ TIN validation

---

## Features

### 1. **e-Invoice Configuration**

- Configure MyInvois Client ID and Client Secret

- Set Tax Identification Number (TIN)

- Business information management

- Sandbox/Production environment toggle

- Connection testing

### 2. **Automatic Submission**

- Seamless integration with POS checkout flow

- Automatic document generation from cart data

- Tax and service charge calculation

- Customer information capture

- Submission status tracking

### 3. **Document Management**

- View recent submitted documents (last 31 days)

- Document status tracking (Valid/Invalid/Cancelled)

- Validation URL and QR code access

- Document search and retrieval

### 4. **Compliance Features**

- UBL 2.1 standard compliance

- SHA-256 document hashing

- OAuth 2.0 secure authentication

- Rate limiting (100 RPM for submissions, 12 RPM for auth)

- Token caching (1 hour validity)

---

## Setup Guide

### Step 1: Register with MyInvois

1. Visit [MyInvois Portal](https://myinvois.hasil.gov.my)
2. Register your business
3. Complete onboarding process
4. Generate API credentials (Client ID & Secret)

### Step 2: Configure in FlutterPOS

1. Open FlutterPOS
2. Navigate to **Settings → e-Invoice (Malaysia)**
3. Tap **Configure e-Invoice** (gear icon)

4. Fill in configuration:

   - **Client ID**: Your MyInvois Client ID

   - **Client Secret**: Your MyInvois Client Secret

   - **TIN**: Your Tax Identification Number (format: C + 10 digits)

   - **Business Name**: Registered business name

   - **Business Address**: Full registered address

   - **Business Phone/Email**: Contact information

5. Select **Environment**:

   - **Sandbox**: For testing (preprod-api.myinvois.hasil.gov.my)

   - **Production**: For live submissions (api.myinvois.hasil.gov.my)

6. Click **Test Connection** to verify credentials

7. Click **Save Configuration**

### Step 3: Enable e-Invoice

1. Toggle **Enable e-Invoice** switch to ON

2. Invoices will now be automatically submitted after checkout

---

## Usage

### Automatic Submission (Recommended)

When e-Invoice is enabled, invoices are automatically submitted after checkout:

```dart
// In your checkout flow:
final result = await EInvoiceHelper.submitAfterCheckout(
  invoiceNumber: 'INV-12345',
  cartItems: cartItems,
  subtotal: subtotal,
  taxAmount: taxAmount,
  serviceChargeAmount: serviceChargeAmount,
  grandTotal: grandTotal,
  customerName: customerName, // Optional
  customerPhone: customerPhone, // Optional
  customerTin: customerTin, // Optional if customer is registered
);

if (result != null) {
  print('e-Invoice submitted: ${result['submissionUID']}');
}

```

### Manual Submission

1. Navigate to **Settings → e-Invoice (Malaysia)**
2. Click **Test Submit** to send a test invoice

3. View submitted documents in the list
4. Tap any document to view details

### View Document Status

```dart
// Get recent documents
final docs = await EInvoiceService.instance.getRecentDocuments(
  pageSize: 50,
  pageNo: 1,
);

// Get specific document
final doc = await EInvoiceService.instance.getDocument(uuid);

// Get submission details
final submission = await EInvoiceService.instance.getSubmission(submissionUid);

```

---

## API Integration Details

### Authentication

MyInvois uses **OAuth 2.0 Client Credentials** flow:

```dart
final token = await EInvoiceService.instance.authenticate();
// Token valid for 1 hour, automatically cached

```

### Document Structure (UBL 2.1 JSON)

```json
{
  "_D": "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
  "Invoice": [{
    "ID": [{"_": "INV-12345"}],
    "IssueDate": [{"_": "2025-12-12"}],
    "IssueTime": [{"_": "14:30:00Z"}],
    "InvoiceTypeCode": [{"_": "01", "listVersionID": "1.0"}],
    "DocumentCurrencyCode": [{"_": "MYR"}],
    "AccountingSupplierParty": [...],
    "AccountingCustomerParty": [...],
    "InvoiceLine": [...],
    "TaxTotal": [...],
    "LegalMonetaryTotal": [...]
  }]
}

```

### Submit Documents

```dart
final result = await EInvoiceService.instance.submitDocuments([document]);
// Returns:
// - submissionUID: Unique submission ID

// - acceptedDocuments: List of accepted documents with UUIDs

// - rejectedDocuments: List of rejected documents with errors

```

### Rate Limits

- **Authentication**: 12 requests/minute per Client ID

- **Submit Documents**: 100 requests/minute per Client ID

- **Other APIs**: Varies by endpoint

### Document Limits

- Maximum submission size: **5 MB**

- Maximum documents per submission: **100**

- Maximum per document: **300 KB**

---

## Tax Categories

MyInvois supports the following tax categories:

| Code | Description |
|------|-------------|
| S | Standard rated (6% SST) |
| Z | Zero rated (0%) |
| E | Exempt from tax |
| O | Out of scope |

FlutterPOS automatically determines the tax category based on your tax settings.

---

## Malaysian State Codes

| Code | State/Territory |
|------|-----------------|
| 01 | Johor |
| 02 | Kedah |
| 03 | Kelantan |
| 04 | Melaka |
| 05 | Negeri Sembilan |
| 06 | Pahang |
| 07 | Pulau Pinang |
| 08 | Perak |
| 09 | Perlis |
| 10 | Selangor |
| 11 | Terengganu |
| 12 | Sabah |
| 13 | Sarawak |
| 14 | Wilayah Persekutuan KL |
| 15 | Wilayah Persekutuan Labuan |
| 16 | Wilayah Persekutuan Putrajaya |

---

## Troubleshooting

### Common Issues

#### 1. Authentication Failed

- **Error**: `Authentication failed: invalid_client`

- **Solution**: Verify Client ID and Secret are correct

#### 2. TIN Validation Failed

- **Error**: `TIN not found`

- **Solution**: Ensure TIN format is correct (C + 10 digits)

  - Example: `C1234567890`

#### 3. Duplicate Submission

- **Error**: `Duplicate submission detected`

- **Solution**: Wait 10 minutes before resubmitting the same payload

#### 4. Connection Timeout

- **Error**: `Authentication timeout`

- **Solution**: Check internet connection and firewall settings

#### 5. Document Rejected

- **Error**: Varies by validation rule

- **Solution**: Check document structure matches UBL 2.1 schema

### Debug Mode

Enable debug mode in settings to view detailed API logs:

```dart
import 'dart:developer' as developer;
developer.log('e-Invoice submission: $result');

```

---

## Best Practices

### 1. **Use Sandbox First**

Always test with Sandbox environment before switching to Production.

### 2. **Cache Tokens**

EInvoiceService automatically caches tokens for 1 hour. Don't request new tokens for every operation.

### 3. **Batch Submissions**

Submit multiple documents in one request when possible (up to 100 documents).

### 4. **Error Handling**

Always handle errors gracefully. Failed submissions should not block checkout.

### 5. **Customer Information**

Collect customer TIN for B2B transactions to ensure compliance.

### 6. **Document Storage**

Store submission UIDs and UUIDs for future reference and auditing.

---

## API Reference

### EInvoiceService Methods

```dart
// Initialize service
await EInvoiceService.instance.init();

// Authenticate
final token = await EInvoiceService.instance.authenticate();

// Validate TIN
final result = await EInvoiceService.instance.validateTin('C1234567890');

// Submit documents
final result = await EInvoiceService.instance.submitDocuments([doc]);

// Get document
final doc = await EInvoiceService.instance.getDocument(uuid);

// Get submission
final submission = await EInvoiceService.instance.getSubmission(uid);

// Cancel document
final result = await EInvoiceService.instance.cancelDocument(uuid, reason);

// Get recent documents
final docs = await EInvoiceService.instance.getRecentDocuments();

// Test connection
final success = await EInvoiceService.instance.testConnection();

```

### EInvoiceHelper Methods

```dart
// Convert checkout to e-Invoice
final doc = EInvoiceHelper.convertToEInvoice(
  invoiceNumber: 'INV-123',
  cartItems: items,
  subtotal: 100.00,
  taxAmount: 6.00,
  serviceChargeAmount: 10.00,
  grandTotal: 116.00,
);

// Submit after checkout
final result = await EInvoiceHelper.submitAfterCheckout(...);

// Validate TIN format
final isValid = EInvoiceHelper.isValidTin('C1234567890');

// Get state codes
final states = EInvoiceHelper.malaysianStateCodes;

// Get tax categories
final categories = EInvoiceHelper.taxCategoryCodes;

```

---

## File Structure

```text
lib/
├── models/einvoice/
│   ├── einvoice_config.dart          # Configuration model

│   └── einvoice_document.dart        # UBL 2.1 document models

├── services/
│   └── einvoice_service.dart         # API service

├── helpers/
│   └── einvoice_helper.dart          # Conversion utilities

└── screens/
    ├── einvoice_config_screen.dart   # Configuration UI

    └── einvoice_submission_screen.dart # Submission UI

```

---

## Compliance & Security

### Data Security

- Client credentials stored in SharedPreferences (consider secure storage for production)

- Access tokens cached for 1 hour

- HTTPS for all API communication

- SHA-256 document hashing

### Regulatory Compliance

- UBL 2.1 standard

- LHDNM e-Invoice guidelines

- Malaysian tax regulations

- Data retention requirements

### Privacy

- Customer data encrypted in transit

- No PII stored in e-Invoice service

- Compliance with PDPA (Personal Data Protection Act)

---

## Support & Resources

### Official Resources

- **MyInvois Portal**: [https://myinvois.hasil.gov.my](https://myinvois.hasil.gov.my)

- **API Documentation**: [https://sdk.myinvois.hasil.gov.my](https://sdk.myinvois.hasil.gov.my)

- **LHDNM**: [https://www.hasil.gov.my](https://www.hasil.gov.my)

### FlutterPOS Support

- GitHub Issues: Report bugs and feature requests

- Documentation: Check project documentation for updates

- Community: Join FlutterPOS community forums

---

## Changelog

### v1.0.14 (2025-12-12)

- ✅ Initial e-Invoice implementation

- ✅ MyInvois API integration

- ✅ UBL 2.1 JSON format support

- ✅ Configuration and submission screens

- ✅ Automatic checkout integration

- ✅ Document management

- ✅ Sandbox and Production support

---

## License

FlutterPOS e-Invoice module is part of the FlutterPOS system.
MyInvois API usage subject to LHDNM terms and conditions.

---

## Contributing

Contributions welcome! Please ensure:

- UBL 2.1 compliance

- API rate limit handling

- Error handling

- Unit tests

- Documentation updates

---

**Note**: This implementation is designed for Malaysian businesses. For other countries, please refer to local e-Invoice regulations and APIs.
