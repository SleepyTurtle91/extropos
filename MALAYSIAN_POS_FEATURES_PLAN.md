# FlutterPOS - Malaysian Business Features Plan

**Version**: 1.0  
**Date**: January 22, 2026  
**Target Markets**: Retail, Cafe, Restaurant, F&B Delivery, Salons

---

## Executive Summary

This plan outlines essential POS features for Malaysian businesses, incorporating local tax requirements, payment methods, compliance standards, and market-specific functionality. Features are organized by priority and implementation complexity.

---

## 1. COMPLIANCE & LEGAL (Critical - Phase 1)

### 1.1 e-Invoice (MyInvois) Integration

**Status**: Partially implemented  
**Priority**: CRITICAL  
**Components**:

- Real-time MyInvois API integration (`/einvoice-submission` route exists)

- Automatic invoice generation and submission

- Invoice number sequencing (INV-YYYYMMDD-XXXX format)

- QR code generation for customer receipts

- Fallback to manual submission if API fails

- Invoice history and resubmission capability

**Implementation Details**:

```dart
// Already exists in router, needs enhancement:
class MyInvoiceService {
  // Validate business SST registration
  Future<bool> validateSSTRegistration(String registrationNumber);
  
  // Generate and submit invoice to MyInvois
  Future<String> submitInvoice(Transaction transaction);
  
  // Get invoice status
  Future<InvoiceStatus> getInvoiceStatus(String documentUUID);
  
  // Handle rejected invoices
  Future<void> resubmitRejectedInvoice(String documentUUID);
}

```

### 1.2 GST/SST (Service & Sales Tax) Support

**Status**: Implemented (configurable)  
**Priority**: CRITICAL  
**Features**:

- ✅ Tax rate configuration (currently 6% or 10% standard)

- ✅ Conditional tax application (some items exempt)

- Tax breakdown on receipts

- Different tax rates by category (future enhancement)

- Quarterly/annual tax reporting

**Enhancement Needed**:

```dart
// Extend BusinessInfo to support:
class TaxCategory {
  String id;
  String name;
  double taxRate;        // Category-specific rate
  bool isTaxExempt;      // E.g., basic food items
  bool isServiceItem;    // Service tax vs sales tax
}

// In BusinessInfo:
final Map<String, TaxCategory> taxCategories = {};

```

### 1.3 Data Protection & PDPA Compliance

**Status**: Needs implementation  
**Priority**: HIGH  
**Requirements**:

- Customer data encryption at rest

- Secure password hashing (bcrypt/Argon2)

- Activity audit logs (who accessed what, when)

- Data retention policies

- Customer consent management

- Right to be forgotten (data deletion)

- Encrypted cloud backup

**Implementation**:

```dart
class PDPAComplianceService {
  // Encrypt sensitive customer data
  Future<String> encryptCustomerData(String data);
  
  // Log user actions for audit trail
  Future<void> logActivity(String userId, String action, String details);
  
  // Generate audit report
  Future<List<AuditLog>> getAuditLogs(DateTimeRange range);
  
  // Customer consent tracking
  Future<void> recordCustomerConsent(String customerId, String consentType);
}

```

### 1.4 Business Registration & Documentation

**Status**: Needs implementation  
**Priority**: HIGH  
**Fields**:

- Business Registration Number (BRN)

- SST Registration Number (if applicable)

- Business address and phone

- Owner/Manager details

- Operating license number

- Business type classification

---

## 2. PAYMENT METHODS (Critical - Phase 1)

### 2.1 Local E-Wallet Integration

**Status**: Not integrated  
**Priority**: CRITICAL  
**Supported Wallets** (Malaysian favorites):

#### **Touch 'n Go eWallet**

- Most popular in Malaysia

- Integration via API

- QR code-based and manual entry

- Balance verification

#### **Grab Pay**

- Second most popular

- Popular with delivery/ride-share users

- Integration with Grab ecosystem

#### **Boost**

- Bank Malaysia initiative

- Growing popularity

- NFC support

#### **GCash/GXRemit** (Filipino users)

- Growing in Malaysia

- Cross-border support

**Implementation Framework**:

```dart
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

class EWalletPaymentService {
  Future<PaymentResult> processPayment(
    double amount,
    PaymentMethod method,
    {String? referenceId}
  );
  
  Future<bool> verifyWalletBalance(String walletId);
  Future<void> initiateRefund(String transactionId, double amount);
}

```

### 2.2 Card Payment Integration

**Status**: Stub methods exist  
**Priority**: HIGH  
**Support**:

- Visa/Mastercard (most common)

- American Express

- Local bank cards

- Chip & PIN support

- Contactless NFC payments

- Online/offline card processing

### 2.3 Split/Multiple Payment Support

**Status**: Framework exists  
**Priority**: HIGH  
**Use Cases**:

- Customer pays with card + cash

- Multiple customers splitting bill

- Partial payment + remaining amount later

- Employee discount + customer payment

**Current Implementation**:

- `paymentsJson` in Transaction model

- Multiple payment splits supported

- Needs UI enhancement

### 2.4 Bank Transfer (B2B)

**Status**: Not integrated  
**Priority**: MEDIUM  
**For**:

- Wholesale orders

- Catering services

- Online orders with advance payment

- Invoice payments

---

## 3. LOCAL BUSINESS MODES (Phase 1)

### 3.1 Restaurant Mode (Already Implemented)

**Features**:

- ✅ Table management with status tracking

- ✅ Order numbers for kitchen

- ✅ Customer display support

- Enhancement needed: Bill splitting, merging tables

**Enhancements**:

```dart
// Add to RestaurantTable:
class RestaurantTable {
  // ... existing fields ...
  
  // Bill splitting
  List<SplitBill> splitBills = [];
  
  // Table merging for large parties
  List<String> mergedFromTableIds = [];
  bool isMergedTable = false;
}

class SplitBill {
  String id;
  List<CartItem> items;
  double subtotal;
  double taxAmount;
  double totalAmount;
  List<Payment> payments;
  DateTime createdAt;
}

```

### 3.2 Cafe/Quick Service Mode (Already Implemented)

**Features**:

- ✅ Order number generation

- ✅ Active orders tracking

- ✅ Quick checkout

- Enhancement: Mobile ordering, queue management

### 3.3 Retail Mode (Already Implemented)

**Features**:

- ✅ Fast checkout

- ✅ Discount support

- ✅ Customer lookup

- Enhancement: Loyalty/rewards integration

### 3.4 Salon/Service Mode (New)

**Priority**: MEDIUM  
**Features**:

- Service-based pricing (not product quantity)

- Staff assignment

- Appointment booking integration

- Service package bundles

- Customer history and preferences

- Stylus for signature

**Model**:

```dart
class SalonService {
  String id;
  String name;
  double price;
  Duration duration;
  String? staffId;  // Assigned staff member
  String? packageId;  // Part of service package
  bool isAvailable;
}

class SalonAppointment {
  String id;
  String customerId;
  List<String> serviceIds;
  DateTime appointmentTime;
  Duration estimatedDuration;
  String? staffId;
  String status;  // scheduled, in-progress, completed, no-show
}

```

### 3.5 Delivery Mode (New)

**Priority**: HIGH  
**Integration With**:

- GrabFood

- FoodPanda/Deliveroo

- Shopee Food

- Self-managed delivery

**Features**:

- Order consolidation from multiple platforms

- Delivery address mapping

- Driver assignment

- Real-time order status

- Customer notifications

---

## 4. INVENTORY MANAGEMENT (Phase 1-2)

### 4.1 Stock Tracking

**Status**: Database schema exists, UI needs work  
**Priority**: HIGH  
**Features**:

- Real-time inventory levels

- Low stock alerts (configurable threshold)

- Stock movement history

- FIFO/LIFO tracking

- Expiry date tracking (critical for F&B)

### 4.2 Inventory Adjustments

**Priority**: MEDIUM  
**Scenarios**:

- Stock count/physical inventory

- Damage/wastage write-offs

- Stock transfers (multi-store)

- Supplier returns

- Inventory adjustments with photo evidence

### 4.3 Purchase Orders

**Priority**: MEDIUM  
**Features**:

- Supplier management

- PO generation and tracking

- Delivery confirmation

- Cost tracking (COGS calculation)

- Supplier performance metrics

### 4.4 Expiry Management

**Priority**: CRITICAL (F&B)**  
**For**: Cafes, restaurants, supermarkets
**Features**:

- Expiry date tracking

- Automatic low-expiry alerts

- First-expiry-out prompts

- Wastage reports

---

## 5. CUSTOMER RELATIONSHIP (Phase 1-2)

### 5.1 Customer Database

**Status**: Model exists, UI needs enhancement  
**Priority**: HIGH  
**Fields**:

- Name, phone, email

- Address (for delivery)

- Purchase history

- Loyalty points/status

- Birthday (for promotions)

- Dietary restrictions (F&B)

- VIP status

### 5.2 Loyalty & Rewards Program

**Status**: Not integrated  
**Priority**: HIGH  
**Types**:

- Points-based (accumulate & redeem)

- Tiered membership (Silver/Gold/Platinum)

- Birthday discounts

- Referral bonuses

- Spend milestones

**Implementation**:

```dart
class LoyaltyProgram {
  String id;
  String name;
  double pointsPerRMSpent;      // E.g., 1 point per RM 1
  double redemptionValue;       // E.g., 100 points = RM 10
  
  Map<String, LoyaltyTier> tiers = {
    'silver': LoyaltyTier(minSpend: 500, discountPercent: 2),
    'gold': LoyaltyTier(minSpend: 2000, discountPercent: 5),
    'platinum': LoyaltyTier(minSpend: 5000, discountPercent: 10),
  };
}

class CustomerLoyalty {
  String customerId;
  double accumulatedPoints;
  String currentTier;
  double totalSpent;
  DateTime joinDate;
  DateTime? nextBirthdayDate;
}

```

### 5.3 Customer Communication

**Priority**: MEDIUM  
**Channels**:

- SMS (for receipts, promotions, reminders)

- WhatsApp Business API (popular in Malaysia)

- Email newsletters

- Push notifications (app)

### 5.4 Customer Feedback & Reviews

**Priority**: MEDIUM  
**Features**:

- Post-transaction feedback

- Service quality rating

- Net Promoter Score (NPS) tracking

- Complaint management

---

## 6. REPORTING & ANALYTICS (Phase 2)

### 6.1 Sales Dashboard (Modern - Already Partially Implemented)

**Status**: Basic implementation exists  
**Enhancements Needed**:

```dart
class SalesDashboard {
  // KPIs
  double grossSales;
  double netSales;
  double taxCollected;
  int transactionCount;
  double averageTicket;
  
  // Trends
  List<SalesDataPoint> salesTrend;       // Daily/hourly
  Map<String, double> salesByCategory;
  Map<String, double> salesByPayment;
  
  // Performance
  List<TopProduct> topProducts;
  List<BottomProduct> bottomProducts;
  
  // Efficiency
  double peakHour;
  int busyTransactions;
  double avgTransactionTime;
  
  // Comparison
  double weekOnWeekGrowth;
  double monthOnMonthGrowth;
  double yearOnYearGrowth;
}

```

### 6.2 Inventory Reports

**Priority**: HIGH  
**Reports**:

- Stock summary (quantity, value)

- Low stock items

- Slow-moving items

- Expiry alerts

- Inventory aging report

- Wastage/damage report

### 6.3 Employee Performance (Already Exists)

**Priority**: MEDIUM  
**Metrics**:

- Sales by staff member

- Transactions per hour

- Average transaction value

- Customer feedback rating

- Attendance/shift summary

- Commissions calculation

### 6.4 Tax & Financial Reports

**Priority**: CRITICAL  
**Reports**:

- GST/SST collected (for government submission)

- Quarterly tax summary

- Cash flow statement

- Profit & loss

- Accounts receivable (for delivery/credit)

### 6.5 Customer Analytics

**Priority**: MEDIUM  
**Insights**:

- Customer acquisition cost

- Customer lifetime value

- Repeat purchase rate

- Churn analysis

- Segmentation (by spend, frequency)

### 6.6 Excel/PDF Export

**Status**: CSV export exists  
**Priority**: MEDIUM  
**Formats**:

- PDF (professional reports)

- Excel (.xlsx with formatting)

- CSV (data import/export)

- Scheduled email reports

---

## 7. HARDWARE INTEGRATION (Phase 1-2)

### 7.1 Thermal Printers

**Status**: Framework exists  
**Printers Supported**:

- 58mm (standard receipt width)

- 80mm (kitchen order tickets)

- Serial/USB/Network connection

- Models: Epson TM, Star Micronics, Sunmi, IMIN

**Features Needed**:

- Multiple printer queuing

- Automatic reprint on failure

- Print template customization

- Kitchen printer order formatting

### 7.2 Customer Display (Dual Display)

**Status**: Partially implemented  
**For**: IMIN devices with built-in second screen
**Shows**:

- Item being added

- Running total

- Payment method accepted

- Thank you message

### 7.3 Card Reader Integration

**Priority**: HIGH  
**Support**:

- Chip & PIN readers

- NFC contactless

- Magnetic stripe (legacy)

- Integration with payment gateway

### 7.4 Cash Drawer

**Priority**: MEDIUM  
**Features**:

- Automatic open on payment

- Manual override

- Multiple cash drawers (for multi-cashier)

- Cash count reports

### 7.5 Barcode Scanner

**Status**: Partially supported  
**Features**:

- Product barcode scanning

- Quick add to cart

- Bulk scanning for inventory count

- Supplier barcode reading

### 7.6 Label Printer

**Priority**: MEDIUM  
**For**:

- Product labels with price

- Inventory barcode labels

- Shelf labels

- Promotional signage

### 7.7 QR Code Generation

**Status**: Implemented for MyInvois  
**Uses**:

- Payment QR codes (e-wallet)

- Invoice QR codes

- Table QR codes (for ordering)

- WiFi guest networks

---

## 8. MULTI-STORE MANAGEMENT (Phase 2)

### 8.1 Store Setup

**Priority**: HIGH (for chains)  
**Features**:

- Multiple store configuration

- Per-store product catalog

- Per-store pricing/promotions

- Per-store staff assignments

### 8.2 Centralized Dashboard

**Priority**: HIGH  
**Shows**:

- All stores' sales consolidated

- Per-store performance

- Comparative analysis

- Centralized reporting

### 8.3 Inventory Transfer

**Priority**: MEDIUM  
**Features**:

- Inter-store stock transfers

- Transfer tracking

- Cost allocation

### 8.4 Staff Management

**Priority**: MEDIUM  
**Features**:

- Store assignment

- Cross-store transfers

- Centralized payroll

- Performance comparison

---

## 9. OFFLINE & SYNC (Phase 1-2)

### 9.1 Offline POS Operations

**Status**: Core functionality ready  
**Priority**: CRITICAL  
**Features**:

- Full POS operation without internet

- Queue pending transactions

- Automatic sync on reconnection

- Conflict resolution (last-write-wins)

**Current**: SQLite local storage  
**Future**: Isar migration for better performance

### 9.2 Cloud Sync (Appwrite)

**Status**: Framework exists  
**Priority**: HIGH  
**Syncs**:

- Products & categories

- Transactions (after completion)

- Customer data

- Inventory levels

- Settings

**Enhancement**:

```dart
class CloudSyncService {
  // Intelligent sync strategy
  Future<void> smartSync({
    bool prioritizeTransactions = true,
    bool syncImages = false,  // Optional for bandwidth
    int maxRetries = 3,
  });
  
  // Bandwidth optimization
  Future<void> syncWithCompression();
  
  // Selective sync (choose what to sync)
  Future<void> selectiveSync(List<SyncEntity> entities);
}

```

---

## 10. SECURITY & AUTHENTICATION (Phase 1)

### 10.1 PIN-Based Authentication

**Status**: Implemented  
**Priority**: CRITICAL  
**Features**:

- ✅ Encrypted PIN storage

- ✅ Failed attempt lockout

- ✅ PIN reset capability

- Multi-level PINs (cashier vs manager)

### 10.2 Role-Based Access Control (RBAC)

**Status**: Model exists, UI needs work  
**Priority**: HIGH  
**Roles**:

- Admin (full access)

- Manager (reports, staff management, settings)

- Cashier (POS operations only)

- Inventory Staff (stock operations)

- Kitchen Staff (order fulfillment)

### 10.3 Activity Logging

**Status**: Needs implementation  
**Priority**: HIGH  
**Logs**:

- Login/logout events

- POS transactions

- Settings changes

- Data modifications

- Failed access attempts

### 10.4 Data Backup & Recovery

**Priority**: HIGH  
**Features**:

- Local backup on device

- Google Drive backup (already implemented)

- Scheduled auto-backup

- One-click restore

- Backup encryption

---

## 11. TRAINING & DEMO MODE (Phase 1)

### 11.1 Training Mode

**Status**: Implemented  
**Priority**: HIGH  
**Features**:

- ✅ Dedicated training environment

- ✅ Sample data generation

- ✅ Transactions marked as training

- ✅ Easy reset

### 11.2 Demo Videos

**Priority**: MEDIUM  
**Content**:

- Quick start guide

- Feature walkthroughs

- Best practices

- Troubleshooting

---

## 12. MALAYSIAN-SPECIFIC FEATURES (Phase 2)

### 12.1 Bumiputera Business Support

**Priority**: MEDIUM  
**Features**:

- Bumiputera certification field

- Potential future integration with government portals

### 12.2 Islamic Finance Compliance

**Priority**: MEDIUM (if applicable)  
**Features**:

- Halal certification tracking

- Shariah-compliant payment methods

- Zakat calculation assistance

### 12.3 BizMulai/SME Support Integration

**Priority**: MEDIUM  
**Features**:

- Government SME program reporting

- Business development resources

### 12.4 Language Support

**Status**: English only  
**Priority**: MEDIUM  
**Add**:

- Malay (Bahasa Malaysia) localization

- Chinese (for some demographics)

- Receipt printing in multiple languages

---

## 13. FUTURE ENHANCEMENTS (Phase 3+)

### 13.1 AI & Analytics

- Demand forecasting

- Dynamic pricing

- Customer behavior analysis

- Churn prediction

### 13.2 Mobile Customer App

- Order placement

- Loyalty tracking

- Delivery tracking

- Reviews/feedback

### 13.3 Omnichannel

- Unified online/offline inventory

- Click & collect

- Buy online pickup in store

### 13.4 API for Third Parties

- Menu integration with delivery platforms

- Accounting software sync (QuickBooks, Xero)

- CRM integration

### 13.5 Advanced Inventory

- RFID tracking

- Automated reordering

- Supplier dashboard

- Inventory forecasting

---

## Implementation Priority Matrix

### Phase 1 (Immediate - Next 1-2 months)

1. **MyInvois Enhancement** - Government requirement

2. **Local E-Wallet Integration** - Customer demand

3. **Loyalty Program** - Competitive necessity

4. **Data Protection/PDPA** - Legal compliance

5. **Offline Sync Reliability** - Operational necessity

6. **Inventory Management UI** - Business essential

7. **Staff Management** - Already partially done

8. **Multi-payment Methods** - Already partially done

### Phase 2 (Medium-term - 2-4 months)

1. Advanced Analytics Dashboard
2. Multi-store Management
3. Salon/Service Mode
4. Delivery Integration
5. Customer Communication (SMS/WhatsApp)
6. Expiry Management
7. Purchase Order System
8. Hardware Integrations (complete)

### Phase 3 (Long-term - 4+ months)

1. Mobile customer app
2. AI-powered features
3. Omnichannel integration
4. Third-party API integrations
5. Advanced reporting

---

## Success Metrics

### Business Impact

- Reduce checkout time by 30%

- Increase customer repeat rate by 25%

- Improve inventory accuracy to 99%

- Reduce food wastage by 15% (with expiry tracking)

- Increase loyalty program adoption to 60% of customers

### Technical Impact

- 99.9% uptime

- < 100ms transaction processing

- < 5MB database size (on-device)

- Offline operation for 24+ hours without internet

### Market Position

- Leading Malaysian POS for SMEs

- Highest customer satisfaction in segment

- Fastest implementation time in market

- Most affordable all-inclusive solution

---

## Competitive Advantages

1. **Locally Compliant**: MyInvois, GST/SST built-in from start
2. **Offline-First**: Works everywhere, even in areas with poor connectivity
3. **Multi-Mode**: One system for retail, cafe, restaurant, salon
4. **Affordable**: Lower cost than Pos Laju, Omnipos, Square
5. **No Monthly Fees**: One-time purchase model
6. **Local Support**: Malaysian team, timezone-aligned support
7. **Customizable**: Open for integration and extensions

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Government changes MyInvois API | Maintain direct relationships with SQL, prepare fallback manual submission |
| E-wallet API changes | Build adapter pattern for payment gateways |
| Device compatibility issues | Extensive testing on popular local devices (IMIN, Sunmi) |
| Data loss/corruption | Regular automated backups, encrypted storage |
| Competitive pressure | Continuous feature updates, community-driven roadmap |

---

## Conclusion

This comprehensive feature plan positions FlutterPOS as the leading POS solution for Malaysian SMEs by:

- Meeting all local regulatory requirements

- Supporting all popular local payment methods

- Providing flexible business modes for different industries

- Offering enterprise features at SME pricing

- Maintaining simplicity for first-time users

**Next Steps**:

1. Validate feature prioritization with beta users (3-5 businesses)
2. Create detailed technical specifications for Phase 1 features
3. Establish development timeline and resource allocation
4. Begin Phase 1 implementation with MyInvois enhancement
