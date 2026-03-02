# E-Invoice Implementation - MyInvois API Compliance Audit

**Date**: March 2, 2026  
**API Version**: Current (SDK)  
**Status**: ⚠️ **PARTIAL COMPLIANCE** - Adjustments Required

---

## Executive Summary

Our new e-invoice refactoring implements the core three-layer architecture correctly, but requires alignment with official MyInvois API specifications for:
1. Document status field mappings
2. Batch submission limits (100 docs/5MB/300KB per doc)
3. Record field mapping from API responses
4. Error handling for specific API error codes
5. Rate limiting considerations

---

## 1. API Endpoints Coverage

### ✅ Implemented Endpoints

| Endpoint | Purpose | Status | Notes |
|----------|---------|--------|-------|
| **Submit Documents** | POST /documentsubmissions/ | ✅ Ready | Handles batch submission (already in einvoice_service.dart) |
| **Get Recent Documents** | GET /documents/recent | ✅ Ready | Supports pagination, 31-day window |
| **Get Submission** | GET /documentsubmissions/{uid} | ✅ Ready | Returns submission details |
| **Get Document** | GET /documents/{uuid}/raw | ✅ Ready | Retrieve document source |

### 📋 Optional Endpoints (Not Required for MVP)

| Endpoint | Purpose | Status | Notes |
|----------|---------|--------|-------|
| Search Documents | GET /documents/search | ⚠️ Partial | Search filtering implemented but parameters need alignment |
| Validate Taxpayer TIN | POST /taxpayers/validate/{tin} | ⚠️ Partial | Already exists, may need field updates |
| Cancel Document | PUT /documents/{uuid}/state | ❌ Not Implemented | Can add later |
| Reject Document | POST /documents/{uuid}/rejections | ❌ Not Implemented | Can add later |

---

## 2. Data Models - API Field Alignment

### Submission Model - ✅ COMPLIANT

**Current Fields:**
- `id` → Maps to `submissionUID` (26 alphanumeric) ✅
- `date` → Maps to submission date (UTC) ✅
- `buyer` → Maps to `buyerName` ✅
- `total` → Maps to total amount (MYR) ✅
- `uin` → Maps to `submissionUID` ⚠️ **ISSUE**: Redundant with `id`
- `status` → Needs alignment ⚠️

**Required Fix:**
```dart
// ADJUST:
class Submission {
  final String submissionUid;        // Unique submission ID
  final List<Map<String, dynamic>> documents;  // List of documents in submission
  final String status;               // Valid/Invalid/Cancelled/Submitted
  final DateTime submittedAt;
  final DateTime? validatedAt;
  
  // REMOVE: uin (redundant with submissionUid)
  // ADD: acceptedDocuments, rejectedDocuments (from API response)
}
```

### UnconsolidatedReceipt Model - ⚠️ NEEDS EXPANSION

**Current Fields:**
- `id`, `date`, `total`, `itemsCount`

**Missing Fields from API:**
- `uuid` - Unique document ID
- `invoiceCodeNumber` - Internal invoice number
- `status` - Document status (Valid/Invalid/Cancelled)
- `buyerName` / `buyerTin`
- `taxAmount`, `discountAmount` 
- `netAmount` (before tax)

**Required Fix:**
```dart
class UnconsolidatedReceipt {
  final String uuid;                    // Unique document ID
  final String invoiceCodeNumber;       // Internal reference
  final String date;
  final double totalSales;              // Before discount
  final double totalDiscount;
  final double netAmount;               // After discount, before tax
  final double total;                   // Final amount incl. tax
  final int itemsCount;
  final String status;                  // Valid/Invalid/Cancelled
  final String? buyerName;
  final String? buyerTin;
}
```

### LhdnConfig Model - ✅ COMPLIANT

Current fields correctly map to MyInvois API requirements:
- ✅ `businessName` - Issuer company name
- ✅ `tin` - Tax Identification Number (format: C + 10 digits)
- ✅ `regNo` - Business Registration Number (12 digits)
- ✅ `clientId` - OAuth client ID
- ✅ `clientSecret` - OAuth client secret

---

## 3. Document Status Values - ⚠️ NEEDS ALIGNMENT

**Current Implementation (in einvoice_module_screen.dart):**
```dart
case 'valid': return 'Validated';
case 'invalid': return 'Rejected';
case 'cancelled': return 'Cancelled';
default: return 'Pending';
```

**Official MyInvois API Values:**
- `Submitted` - Document received, awaiting validation ✅
- `Valid` - Passed all validations ⚠️ Currently mapped to 'Validated'
- `Invalid` - Failed validations ⚠️ Currently mapped to 'Rejected'
- `Cancelled` - Issuer cancelled the document ✅

**Required Fix:**
Use API values directly without mapping:
```dart
enum DocumentStatus {
  submitted,    // Awaiting validation
  valid,        // Validated successfully
  invalid,      // Validation failed
  cancelled,    // Cancelled by issuer
}
```

---

## 4. Submission Limits & Constraints

### ⚠️ NOT ENFORCED IN CURRENT IMPLEMENTATION

The official API has these hard limits:

| Constraint | Limit | Current UI | Status |
|-----------|-------|-----------|--------|
| **Documents per submission** | 100 max | No validation | ❌ Need to add |
| **Submission total size** | 5 MB max | No validation | ❌ Need to add |
| **Per-document size** | 300 KB max | No validation | ❌ Need to add |
| **Documents per page** | 10,000 max | Pagination in place | ✅ OK |
| **Time window (Get Recent)** | 31 days | Not enforced | ⚠️ Should validate |
| **Rate limit (Submit)** | 100 RPM | Not enforced | ⚠️ Should warn |
| **Rate limit (Search)** | 12 RPM | Not enforced | ⚠️ Should warn |

**Required Fix in `einvoice_business_logic_service.dart`:**
```dart
/// Validate submission batch before posting
static List<String> validateSubmissionBatch(
  List<UnconsolidatedReceipt> documents,
) {
  final errors = <String>[];
  
  if (documents.length > 100) {
    errors.add('Maximum 100 documents per submission (${documents.length} provided)');
  }
  
  double totalSize = 0;
  for (var doc in documents) {
    final docSize = _estimateDocumentSize(doc);
    if (docSize > 300 * 1024) {  // 300 KB
      errors.add('Document ${doc.id} exceeds 300 KB limit');
    }
    totalSize += docSize;
  }
  
  if (totalSize > 5 * 1024 * 1024) {  // 5 MB
    errors.add('Total submission size (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB) exceeds 5 MB limit');
  }
  
  return errors;
}
```

---

## 5. API Response Field Mapping

### Get Recent Documents Response - ⚠️ PARTIAL MAPPING

API returns these fields in *Get Recent Documents* response:

```dart
// Required fields we should capture:
{
  'uuid': String,                    // ✅ Needed in UnconsolidatedReceipt
  'submissionUID': String,           // ✅ Needed in Submission
  'invoiceCodeNumber': String,       // ✅ Needed in UnconsolidatedReceipt
  'status': String,                  // ✅ Valid/Invalid/Cancelled/Submitted
  'dateTimeIssued': DateTime,        // ✅ Issue date
  'dateTimeReceived': DateTime,      // ✅ Submission/receipt date
  'dateTimeValidated': DateTime,     // ⚠️ Not captured
  
  'totalSales': Decimal,             // ⚠️ Not captured
  'totalDiscount': Decimal,          // ⚠️ Not captured
  'netAmount': Decimal,              // ⚠️ Not captured
  'total': Decimal,                  // ✅ Total amount
  
  'buyerName': String,               // ⚠️ Not captured
  'buyerTin': String,                // ⚠️ Not captured
  'receiverId': String,              // ⚠️ Not captured
  'receiverName': String,            // ⚠️ Not captured
  
  'issuerTin': String,               // ✅ Supplier TIN
  'supplierName': String,            // ⚠️ Not captured
  
  // Optional fields
  'cancelDateTime': DateTime,        // ⚠️ Not captured
  'rejectRequestDateTime': DateTime, // ⚠️ Not captured
  'documentStatusReason': String,    // ⚠️ Not captured
}
```

**Current Mapping (in einvoice_module_screen.dart):**
```dart
_submissions = docs.map((doc) => Submission(
  id: doc['uuid'] ?? 'N/A',              // ⚠️ Should be submissionUID
  date: doc['invoiceDate'] ?? 'N/A',     // ⚠️ Should be dateTimeReceived
  buyer: doc['customerName'] ?? 'Unknown', // ⚠️ Should be buyerName
  total: (doc['totalAmount'] as num?)?.toDouble() ?? 0.0,  // ✅ OK
  uin: doc['submissionUID'] ?? '',       // ⚠️ Redundant
  status: _mapDocumentStatus(doc['status']),  // ⚠️ Should use API values directly
))
```

---

## 6. Error Handling - ⚠️ INSUFFICIENT

### Official API Error Codes Not Handled

| Error Code | Scenario | Our Handling | Status |
|-----------|----------|-------------|--------|
| **400 BadStructure** | Invalid JSON/XML structure | Generic catch | ❌ Need specific |
| **400 MaximumSizeExceeded** | Submission > 5MB | Generic catch | ❌ Need specific |
| **403 IncorrectSubmitter** | Wrong taxpayer/permission | Generic catch | ❌ Need specific |
| **422 DuplicateSubmission** | Identical submission in 10 min | Generic catch | ❌ Need specific |
| **429 RateLimitExceeded** | Exceeded 100 RPM | Generic catch | ❌ Need specific |

**Required Enhancement:**
```dart
class MyInvoisException implements Exception {
  final String code;           // BadStructure, MaximumSizeExceeded, etc.
  final String message;
  final String? detail;
  
  MyInvoisException(this.code, this.message, [this.detail]);
}

// In einvoice_service.dart
Future<Map<String, dynamic>> submitDocuments(List<dynamic> documents) async {
  try {
    final response = await http.post(...);
    
    if (response.statusCode == 202) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      if (error['error']['code'] == 'BadStructure') {
        throw MyInvoisException('BadStructure', 'Invalid document format');
      }
      // ... handle other 400 codes
    } else if (response.statusCode == 403) {
      final error = jsonDecode(response.body);
      throw MyInvoisException('IncorrectSubmitter', error['error']['message']);
    }
    // ... handle other codes
  }
}
```

---

## 7. Document Type Support - ✅ COMPREHENSIVE

Our `EInvoiceDocument` model supports:

| Document Type | Code | Status |
|---|---|---|
| Invoice | 01 | ✅ |
| Credit Note | 02 | ✅ |
| Debit Note | 03 | ✅ |
| Refund Note | 04 | ✅ |
| Self-Billed Invoice | 11 | ✅ |
| Self-Billed Credit Note | 12 | ✅ |
| Self-Billed Debit Note | 13 | ✅ |
| Self-Billed Refund Note | 14 | ✅ |

✅ **COMPLIANT** - Already implemented in `einvoice_document.dart`

---

## 8. Rate Limiting - ⚠️ NOT IMPLEMENTED

### Official Rate Limits:

| API Endpoint | Limit | Recommended | Current |
|---|---|---|---|
| Submit Documents | 100 RPM | Batch submissions | No throttling |
| Get Recent Documents | 12 RPM | Query only for troubleshooting | No throttling |
| Search Documents | 12 RPM | Don't use for reconciliation | No throttling |

**Recommendation:** Add rate limiting warnings to the UI
```dart
// In ConsolidateScreen
if (unconsolidatedReceipts.length > 50) {
  showWarning(
    'Submitting ${unconsolidatedReceipts.length} documents.'
    'Recommended: Split into multiple smaller batches.'
  );
}
```

---

## 9. Compliance Notice - ✅ GOOD

The ConsolidateScreen already displays:
> "Businesses are allowed to aggregate B2C transactions (where buyers did not request an e-Invoice) into a consolidated e-Invoice within 7 days of the following month."

This is accurate per LHDN regulations. ✅

---

## Summary of Required Adjustments

### Priority 1: CRITICAL (Must Fix)
- [ ] Update `Submission` model to use `submissionUID`, remove redundant `uin`
- [ ] Update status mapping to use API values directly: Valid/Invalid/Cancelled/Submitted
- [ ] Expand `UnconsolidatedReceipt` model with missing fields
- [ ] Fix field mapping in `einvoice_module_screen.dart`

### Priority 2: IMPORTANT (Should Fix Soon)
- [ ] Add submission batch validation (100 docs, 5 MB, 300 KB per doc)
- [ ] Add specific error handling for API error codes
- [ ] Add rate limiting warnings to UI
- [ ] Implement proper document size estimation

### Priority 3: NICE TO HAVE (Can Add Later)
- [ ] Implement retry logic with Retry-After header
- [ ] Add Retry-After handling for throttled requests
- [ ] Implement 10-minute duplicate detection warning
- [ ] Add document validation result details display

---

## Files to Update (In Order)

1. **lib/models/einvoice/submission.dart** - Fix model structure
2. **lib/models/einvoice/unconsolidated_receipt.dart** - Expand fields
3. **lib/screens/einvoice_module_screen.dart** - Fix API mapping
4. **lib/services/einvoice_business_logic_service.dart** - Add validation
5. **lib/screens/consolidate_screen.dart** - Add warnings/limits
6. **lib/services/einvoice_service.dart** - Add specific error handling

---

## Compliance Checklist

- ✅ Document types supported (8 types)
- ✅ Batch submission capability (max 100)
- ✅ API authentication (OAuth 2.0)
- ✅ UBL 2.1 format support
- ✅ SHA256 hashing
- ⚠️ Status field alignment (needs update)
- ⚠️ Field mapping (needs update)
- ⚠️ Submission limits (not enforced)
- ⚠️ Error handling (generic)
- ⚠️ Rate limiting (not implemented)

**Overall Compliance Score: 65/100** (Functional but needs refinement)

---

## Next Steps

1. Review Priority 1 changes in the following section
2. Implement fixes systematically
3. Test against MyInvois sandbox environment
4. Add unit tests for validation logic
5. Document API integration patterns

