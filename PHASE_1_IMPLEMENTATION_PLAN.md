# FlutterPOS Phase 1 Implementation Plan

**Status**: Ready to Start  
**Timeline**: 1-2 months  
**Priority**: CRITICAL  
**Date Started**: January 22, 2026

---

## Phase 1 Overview

Phase 1 focuses on **government compliance**, **payment integration**, and **core business functionality** essential for Malaysian market launch.

### Priority Order

1. **MyInvois Enhancement** (Week 1-2) - Government requirement

2. **Local E-Wallet Integration** (Week 2-3) - Customer demand  

3. **Loyalty Program** (Week 3-4) - Competitive necessity

4. **PDPA Compliance** (Week 4-5) - Legal requirement

5. **Offline Sync Enhancement** (Week 5-6) - Operational stability

6. **Inventory Management UI** (Week 6-7) - Business essential

---

## 1. MyInvois Enhancement (Week 1-2)

### Current Status

- Route exists: `/einvoice-submission`

- Integration framework started

- Needs: Full API integration, QR code generation, submission flow

### Implementation Tasks

#### Task 1.1: Create MyInvois Service (`lib/services/my_invois_service.dart`)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyInvoiceService {
  static const String _apiUrl = 'https://api.myinvois.gov.my/api/v1';
  static const String _sandbox = 'https://sandbox.myinvois.gov.my/api/v1';
  
  bool useSandbox = true;  // Toggle for testing
  
  // Validate business SST registration
  Future<bool> validateSSTRegistration(String registrationNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/taxpayers/$registrationNumber'),
        headers: {'Authorization': 'Bearer $_getToken()'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ SST validation error: $e');
      return false;
    }
  }
  
  // Generate invoice and submit to MyInvois
  Future<String> submitInvoice(Transaction transaction) async {
    try {
      // Generate invoice number: INV-YYYYMMDD-XXXX
      final invoiceNumber = _generateInvoiceNumber();
      
      // Format transaction for MyInvois API
      final invoiceData = _formatInvoiceData(transaction, invoiceNumber);
      
      // Submit to MyInvois
      final response = await http.post(
        Uri.parse('$_apiUrl/documents'),
        headers: {
          'Authorization': 'Bearer $_getToken()',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(invoiceData),
      );
      
      if (response.statusCode != 200) {
        throw Exception('MyInvois submission failed: ${response.body}');
      }
      
      final result = jsonDecode(response.body);
      final documentUUID = result['uuid'] as String;
      
      // Save submission record
      await _saveInvoiceRecord(transaction.id, documentUUID, invoiceNumber);
      
      // Generate QR code for receipt
      final qrCode = await _generateQRCode(documentUUID);
      
      print('✅ Invoice submitted: $invoiceNumber (UUID: $documentUUID)');
      return documentUUID;
    } catch (e) {
      print('🔥 Error submitting invoice: $e');
      // Fallback: queue for manual submission
      await _queueForManualSubmission(transaction);
      rethrow;
    }
  }
  
  // Get invoice status
  Future<InvoiceStatus> getInvoiceStatus(String documentUUID) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/documents/$documentUUID'),
        headers: {'Authorization': 'Bearer $_getToken()'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get invoice status');
      }
      
      final data = jsonDecode(response.body);
      return InvoiceStatus.fromJson(data);
    } catch (e) {
      print('❌ Error getting invoice status: $e');
      rethrow;
    }
  }
  
  // Handle rejected invoices - allow resubmission
  Future<void> resubmitRejectedInvoice(String documentUUID) async {
    try {
      // Fetch original invoice
      final invoice = await _getStoredInvoice(documentUUID);
      
      // Resubmit with corrections
      final response = await http.put(
        Uri.parse('$_apiUrl/documents/$documentUUID'),
        headers: {'Authorization': 'Bearer $_getToken()'},
        body: jsonEncode(invoice),
      );
      
      if (response.statusCode == 200) {
        print('✅ Invoice resubmitted: $documentUUID');
      }
    } catch (e) {
      print('🔥 Error resubmitting invoice: $e');
      rethrow;
    }
  }
  
  // Helper methods
  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final sequence = _getSequenceNumber();
    return 'INV-$dateStr-${sequence.toString().padLeft(4, '0')}';
  }
  
  Map<String, dynamic> _formatInvoiceData(Transaction transaction, String invoiceNumber) {
    final info = BusinessInfo.instance;
    return {
      'invoiceNumber': invoiceNumber,
      'invoiceDate': DateTime.now().toIso8601String(),
      'seller': {
        'name': info.businessName,
        'taxId': info.sstRegistrationNumber,
        'address': info.businessAddress,
        'email': info.businessEmail,
        'phone': info.businessPhone,
      },
      'buyer': {
        'name': transaction.customerId ?? 'Walk-in Customer',
        'taxId': '', // Optional if not registered
      },
      'items': transaction.items.map((item) => {
        'description': item.product.name,
        'quantity': item.quantity,
        'unitPrice': item.product.price,
        'amount': item.product.price * item.quantity,
      }).toList(),
      'subtotal': transaction.subtotal,
      'tax': {
        'amount': transaction.taxAmount,
        'rate': (BusinessInfo.instance.taxRate * 100).toStringAsFixed(0) + '%',
      },
      'total': transaction.totalAmount,
      'paymentMethod': transaction.paymentMethod,
    };
  }
  
  Future<String> _generateQRCode(String documentUUID) async {
    // Generate QR code containing document UUID
    // Use qr_flutter package
    return 'data:image/png;base64,...'; // QR code image
  }
  
  String _getToken() {
    // Get stored API token (implement storage)
    // Should be refreshed periodically
    return '';
  }
  
  int _getSequenceNumber() {
    // Get sequence from database for today
    // Increment and return
    return 1;
  }
  
  Future<void> _saveInvoiceRecord(String transactionId, String documentUUID, String invoiceNumber) async {
    // Save to database for tracking
  }
  
  Future<void> _queueForManualSubmission(Transaction transaction) async {
    // Queue transaction for manual submission via web portal
  }
  
  Future<Map<String, dynamic>> _getStoredInvoice(String documentUUID) async {
    // Retrieve from database
    return {};
  }
}

class InvoiceStatus {
  String uuid;
  String status;  // submitted, accepted, rejected
  String? rejectionReason;
  DateTime submittedAt;
  DateTime? acceptedAt;
  
  InvoiceStatus({
    required this.uuid,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.acceptedAt,
  });
  
  factory InvoiceStatus.fromJson(Map<String, dynamic> json) {
    return InvoiceStatus(
      uuid: json['uuid'],
      status: json['status'],
      rejectionReason: json['rejectionReason'],
      submittedAt: DateTime.parse(json['submittedAt']),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
    );
  }
}

```

#### Task 1.2: Extend BusinessInfo Model

```dart
// In lib/models/business_info_model.dart, add:

class BusinessInfo {
  // ... existing fields ...
  
  // NEW: MyInvois fields
  String sstRegistrationNumber;      // e.g., "000123456789"
  String businessRegistrationNumber; // BRN
  String businessEmail;
  String businessPhone;
  String businessAddress;
  bool isMyInvoisEnabled;
  
  // Tax categories (future enhancement)
  Map<String, TaxCategory> taxCategories = {};
  
  // copyWith needs to include new fields
  BusinessInfo copyWith({
    // ... existing fields ...
    String? sstRegistrationNumber,
    String? businessRegistrationNumber,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    bool? isMyInvoisEnabled,
  }) {
    return BusinessInfo(
      // ... existing ...
      sstRegistrationNumber: sstRegistrationNumber ?? this.sstRegistrationNumber,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      isMyInvoisEnabled: isMyInvoisEnabled ?? this.isMyInvoisEnabled,
    );
  }
}

class TaxCategory {
  String id;
  String name;
  double taxRate;
  bool isTaxExempt;
  bool isServiceItem;
  
  TaxCategory({
    required this.id,
    required this.name,
    required this.taxRate,
    this.isTaxExempt = false,
    this.isServiceItem = false,
  });
}

```

#### Task 1.3: Create MyInvois Settings Screen

```dart
// lib/screens/my_invois_settings_screen.dart

class MyInvoiceSettingsScreen extends StatefulWidget {
  const MyInvoiceSettingsScreen({super.key});

  @override
  State<MyInvoiceSettingsScreen> createState() => _MyInvoiceSettingsScreenState();
}

class _MyInvoiceSettingsScreenState extends State<MyInvoiceSettingsScreen> {
  late BusinessInfo _businessInfo;
  
  @override
  void initState() {
    super.initState();
    _businessInfo = BusinessInfo.instance;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyInvois Configuration'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Business Registration'),
            _buildTextField('SST Registration Number', _businessInfo.sstRegistrationNumber, (value) {
              // Update and validate
            }),
            _buildTextField('Business Registration Number', _businessInfo.businessRegistrationNumber, (value) {
              // Update
            }),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Contact Information'),
            _buildTextField('Business Email', _businessInfo.businessEmail, (value) {
              // Update
            }),
            _buildTextField('Business Phone', _businessInfo.businessPhone, (value) {
              // Update
            }),
            _buildTextField('Business Address', _businessInfo.businessAddress, (value) {
              // Update
            }),
            const SizedBox(height: 24),
            
            _buildSectionHeader('MyInvois Status'),
            SwitchListTile(
              title: const Text('Enable MyInvois Integration'),
              subtitle: const Text('Automatically submit invoices to government'),
              value: _businessInfo.isMyInvoisEnabled,
              onChanged: (value) {
                setState(() {
                  _businessInfo = _businessInfo.copyWith(isMyInvoisEnabled: value);
                });
              },
            ),
            const SizedBox(height: 24),
            
            _buildTestButton(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildTextField(String label, String initialValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        controller: TextEditingController(text: initialValue),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildTestButton() {
    return ElevatedButton(
      onPressed: _testMyInvoisConnection,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      child: const Text('Test Connection'),
    );
  }
  
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
      child: const Text('Save Settings'),
    );
  }
  
  Future<void> _testMyInvoisConnection() async {
    try {
      final service = MyInvoiceService();
      final isValid = await service.validateSSTRegistration(_businessInfo.sstRegistrationNumber);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isValid ? '✅ Connection successful' : '❌ Invalid registration number')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      BusinessInfo.updateInstance(_businessInfo);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Settings saved')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }
}

```

#### Task 1.4: Database Schema Update

```sql
-- Add to database initialization

CREATE TABLE IF NOT EXISTS invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id TEXT NOT NULL UNIQUE,
  invoice_number TEXT NOT NULL UNIQUE,
  document_uuid TEXT UNIQUE,
  status TEXT NOT NULL,  -- submitted, accepted, rejected, pending_manual
  submission_date INTEGER,
  acceptance_date INTEGER,
  rejection_reason TEXT,
  qr_code BLOB,
  is_synced INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS invoice_sequences (
  id INTEGER PRIMARY KEY,
  date TEXT NOT NULL UNIQUE,  -- YYYYMMDD
  sequence_number INTEGER DEFAULT 0
);

```

#### Task 1.5: Update Receipt Template

```dart
// In receipt_printer_service.dart, add QR code to receipt

String _generateReceiptContent(Transaction transaction, String? qrCode) {
  final info = BusinessInfo.instance;
  
  final buffer = StringBuffer();
  
  buffer.writeln('═' * 32);
  buffer.writeln(info.businessName.padCenter(32));
  buffer.writeln(info.businessAddress.padCenter(32));
  buffer.writeln('═' * 32);
  
  buffer.writeln('\nINVOICE');
  buffer.writeln('Invoice #: ${transaction.invoiceNumber ?? 'N/A'}');
  buffer.writeln('Date: ${_formatDate(transaction.transactionDate)}');
  
  // If MyInvois accepted, show QR code and verification info
  if (qrCode != null) {
    buffer.writeln('\n[QR CODE AREA]');
    buffer.writeln('MyInvois Verified');
  }
  
  buffer.writeln('\n' + '─' * 32);
  buffer.writeln('Items:');
  
  for (final item in transaction.items) {
    buffer.writeln('${item.product.name}');
    buffer.writeln('  ${item.quantity} × RM ${item.product.price.toStringAsFixed(2)}');
    buffer.writeln('  ${(item.quantity * item.product.price).toStringAsFixed(2)}');
  }
  
  buffer.writeln('─' * 32);
  buffer.writeln('Subtotal: RM ${transaction.subtotal.toStringAsFixed(2)}');
  
  if (info.isTaxEnabled && transaction.taxAmount > 0) {
    buffer.writeln('Tax (${(info.taxRate * 100).toStringAsFixed(0)}%): RM ${transaction.taxAmount.toStringAsFixed(2)}');
  }
  
  buffer.writeln('Total: RM ${transaction.totalAmount.toStringAsFixed(2)}');
  buffer.writeln('═' * 32);
  
  return buffer.toString();
}

```

### Success Criteria for Task 1

- [ ] MyInvoiceService created and tested

- [ ] BusinessInfo model extended with MyInvois fields

- [ ] Settings screen implemented

- [ ] Database schema updated

- [ ] Receipt template updated with QR code

- [ ] Integration tested with MyInvois sandbox

- [ ] Error handling for failed submissions

- [ ] Manual submission fallback works

- [ ] flutter analyze passes with 0 errors

- [ ] Unit tests written for calculations

---

## 2. Local E-Wallet Integration (Week 2-3)

### Supported E-Wallets (Priority Order)

1. Touch 'n Go (RM1.2B annual transaction volume)
2. Grab Pay (RM300M+ annual)

3. Boost (RM200M+ annual)

4. Alipay/WeChat Pay (tourists)

### Implementation Structure

```dart
// lib/services/payment/payment_gateway.dart

abstract class PaymentGateway {
  Future<PaymentResult> processPayment(PaymentRequest request);
  Future<void> refundPayment(String transactionId, double amount);
  Future<PaymentStatus> getPaymentStatus(String transactionId);
}

// lib/services/payment/touch_n_go_gateway.dart
class TouchNGoGateway extends PaymentGateway {
  // Implementation
}

// lib/services/payment/grab_pay_gateway.dart
class GrabPayGateway extends PaymentGateway {
  // Implementation
}

// lib/services/payment/boost_gateway.dart
class BoostGateway extends PaymentGateway {
  // Implementation
}

enum PaymentMethod {
  cash,
  card,
  touchNGo,
  grabPay,
  boost,
  alipay,
  wechatPay,
  bankTransfer,
}

class PaymentRequest {
  final double amount;
  final PaymentMethod method;
  final String orderId;
  final String? customerId;
  final String? metadata;
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? reference;
  final String? errorMessage;
  final DateTime timestamp;
}

```

### Database Schema

```sql
CREATE TABLE IF NOT EXISTS e_wallet_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id TEXT NOT NULL UNIQUE,
  payment_method TEXT NOT NULL,  -- touchngo, grabpay, boost, etc.
  amount REAL NOT NULL,
  reference_id TEXT,
  status TEXT NOT NULL,  -- pending, completed, failed, refunded
  gateway_response TEXT,  -- JSON response from gateway
  refund_amount REAL DEFAULT 0.0,
  refund_reference TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

```

---

## 3. Loyalty Program (Week 3-4)

### Data Models

```dart
// lib/models/loyalty_program.dart

class LoyaltyProgram {
  String id;
  String name;
  bool isEnabled;
  
  // Points system
  double pointsPerRMSpent;      // e.g., 1.0
  double redemptionValue;       // e.g., 100 points = RM 10
  
  // Tiers
  Map<String, LoyaltyTier> tiers = {};
  
  // Rules
  bool awardOnTax;              // Award points on tax amount
  List<String> exemptCategories;
}

class LoyaltyTier {
  String name;
  double minSpend;
  double discountPercentage;
  List<String> benefits;
}

// lib/models/customer_loyalty.dart

class CustomerLoyalty {
  String customerId;
  double accumulatedPoints;
  String currentTier;
  double totalSpent;
  DateTime joinDate;
  DateTime? lastPurchaseDate;
  List<LoyaltyTransaction> transactions;
}

class LoyaltyTransaction {
  String id;
  String type;        // earn, redeem, adjust
  double points;
  String description;
  DateTime date;
}

```

### Database Schema

```sql
CREATE TABLE IF NOT EXISTS loyalty_programs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  is_enabled INTEGER DEFAULT 1,
  points_per_rm_spent REAL DEFAULT 1.0,
  redemption_value REAL DEFAULT 0.1,
  award_on_tax INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS loyalty_tiers (
  id TEXT PRIMARY KEY,
  program_id TEXT NOT NULL,
  name TEXT NOT NULL,
  min_spend REAL NOT NULL,
  discount_percentage REAL,
  benefits TEXT,  -- JSON array
  FOREIGN KEY (program_id) REFERENCES loyalty_programs(id)
);

CREATE TABLE IF NOT EXISTS customer_loyalty (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL UNIQUE,
  accumulated_points REAL DEFAULT 0.0,
  current_tier TEXT,
  total_spent REAL DEFAULT 0.0,
  join_date INTEGER NOT NULL,
  last_purchase_date INTEGER,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  type TEXT NOT NULL,  -- earn, redeem, adjust
  points REAL NOT NULL,
  description TEXT,
  transaction_id TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

```

---

## 4. PDPA Compliance (Week 4-5)

### Services Needed

```dart
// lib/services/pdpa_compliance_service.dart

class PDPAComplianceService {
  // Encryption
  Future<String> encryptCustomerData(String plainText) async {
    // Use encrypt package with AES-256
  }
  
  Future<String> decryptCustomerData(String cipherText) async {
    // Decrypt
  }
  
  // Activity logging
  Future<void> logActivity(String userId, String action, Map<String, dynamic> details) async {
    // Log who accessed what data
  }
  
  // Consent management
  Future<void> recordConsent(String customerId, String consentType, bool granted) async {
    // Track customer consent for marketing, data usage, etc.
  }
  
  // Data deletion (right to be forgotten)
  Future<void> deleteCustomerData(String customerId) async {
    // Anonymize or delete all customer data
  }
  
  // Audit reports
  Future<List<AuditLog>> getAuditLogs(DateTimeRange range, {String? userId}) async {
    // Generate audit trail
  }
}

class AuditLog {
  String userId;
  String action;
  Map<String, dynamic> details;
  DateTime timestamp;
  String ipAddress;
}

```

---

## 5. Offline Sync Reliability (Week 5-6)

### Enhanced Sync Service

```dart
// lib/services/offline_sync_service.dart

class OfflineSyncService {
  // Intelligent queuing
  Future<void> queueTransaction(Transaction tx) async {
    // Save transaction locally with "pending_sync" status
  }
  
  // Smart sync when reconnected
  Future<SyncResult> smartSync() async {
    // Sync in priority order: transactions > inventory > settings
    // Handle conflicts
    // Retry failed items
  }
  
  // Conflict resolution
  Future<void> resolveConflict(String documentId, ConflictResolution strategy) async {
    // last-write-wins, server-wins, manual-review
  }
  
  // Bandwidth-aware syncing
  Future<void> syncWithBandwidthControl({
    required bool syncImages,
    int maxRetries = 3,
  }) async {
    // Skip images if bandwidth limited
    // Progressive sync
  }
}

enum ConflictResolution { lastWriteWins, serverWins, manualReview }

```

---

## 6. Inventory Management UI (Week 6-7)

### Screens to Create

```dart
// lib/screens/inventory_management_screen.dart
// lib/screens/stock_adjustment_screen.dart
// lib/screens/expiry_management_screen.dart
// lib/screens/purchase_order_screen.dart

```

---

## Implementation Timeline

```
Week 1-2: MyInvois
  Day 1-2:   Service creation, API integration
  Day 3-4:   Settings screen
  Day 5:     Testing, error handling

Week 2-3: E-Wallets  
  Day 1-2:   Gateway abstraction
  Day 3-4:   Touch 'n Go integration
  Day 5:     Grab Pay, Boost integration

Week 3-4: Loyalty Program
  Day 1-2:   Models, database
  Day 3-4:   Loyalty service
  Day 5:     UI screens

Week 4-5: PDPA
  Day 1-2:   Encryption service
  Day 3-4:   Audit logging
  Day 5:     Consent management

Week 5-6: Offline Sync
  Day 1-2:   Queue service
  Day 3-4:   Smart sync logic
  Day 5:     Conflict resolution

Week 6-7: Inventory UI
  Day 1-2:   List screens
  Day 3-4:   Add/edit dialogs
  Day 5:     Stock adjustment flow

```

---

## Testing Checklist

### MyInvois Testing

- [ ] Test with MyInvois sandbox API

- [ ] Verify invoice number generation (unique per day)

- [ ] Test QR code generation and scanning

- [ ] Verify tax calculation matches MyInvois rules

- [ ] Test rejection handling and resubmission

- [ ] Test manual submission fallback

- [ ] Receipt printing includes QR code

### E-Wallet Testing

- [ ] Test with each provider's sandbox

- [ ] Verify amount formatting (2 decimal places)

- [ ] Test failed payment handling

- [ ] Verify refund capability

- [ ] Test split payments (cash + e-wallet)

- [ ] Transaction history tracking

### Loyalty Testing

- [ ] Points calculation accuracy

- [ ] Tier classification based on spend

- [ ] Point redemption

- [ ] Multiple customer scenarios (no loyalty, silver, gold, etc.)

### PDPA Testing

- [ ] Encryption/decryption working

- [ ] Audit logs recording all actions

- [ ] Consent forms displaying

- [ ] Data deletion (anonymization) working

### Offline Testing

- [ ] Full POS operation without internet

- [ ] Transaction queueing

- [ ] Auto-sync when reconnected

- [ ] Conflict resolution

- [ ] No data loss

---

## Success Criteria for Phase 1

- [ ] All 6 feature areas implemented

- [ ] flutter analyze: 0 errors

- [ ] 100% test coverage for business logic

- [ ] Integration tested on physical devices

- [ ] Performance benchmarks met (< 100ms transactions)

- [ ] Error messages user-friendly

- [ ] Documentation updated

- [ ] Ready for Malaysian market launch

---

## Resources

**Dependencies to add**:

```yaml
dependencies:
  http: ^1.0.0          # API calls

  qr_flutter: ^10.0     # QR code generation

  encrypt: ^5.0.0       # Encryption

  intl: ^0.18.0         # Date formatting

```

**Reference Documents**:

- AGENT_CODING_REFERENCE.md - Code patterns

- MALAYSIAN_POS_FEATURES_PLAN.md - Full feature specs

- copilot-instructions.md - Architecture patterns

---

## Next Steps

1. **Start with MyInvois** (Week 1-2)

   - Create service class

   - Integrate with API

   - Test with sandbox

2. **Add E-Wallet Support** (Week 2-3)

   - Abstract payment gateway

   - Integrate each provider

   - Test split payments

3. **Implement Loyalty** (Week 3-4)

   - Create models and database

   - Build loyalty service

   - Create UI for admin and POS

Continue systematically through each feature in priority order.

---

**Phase 1 Status**: Ready to Start  
**Estimated Completion**: 6-8 weeks  
**Target Launch**: March 2026
