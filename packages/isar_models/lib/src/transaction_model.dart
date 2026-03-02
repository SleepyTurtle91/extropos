import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

/// Isar Transaction model (Order) with sync support
/// Represents a completed sale/transaction with line items
@collection
class IsarTransaction {
  /// Local Isar ID (auto-generated)
  Id id = Isar.autoIncrement;

  /// Backend document ID (from Appwrite/MongoDB) for sync matching
  late String backendId;

  /// Order/Transaction number (e.g., "ORD-20251230-001")
  late String transactionNumber;

  /// Transaction/Order date timestamp (milliseconds)
  late int transactionDate;

  /// User/Cashier ID who created the transaction
  late String userId;

  /// User/Cashier name (cached)
  String? userName;

  /// Subtotal before tax and service charge
  late double subtotal;

  /// Tax amount applied
  double taxAmount = 0.0;

  /// Service charge amount
  double serviceChargeAmount = 0.0;

  /// Total amount (subtotal + tax + service charge - discount)
  late double totalAmount;

  /// Discount amount applied
  double discountAmount = 0.0;

  /// Discount reason/description
  String? discountReason;

  /// Payment method (cash, card, e-wallet, etc.)
  late String paymentMethod;

  /// Payment reference (e.g., card transaction ID)
  String? paymentReference;

  /// Business mode used (retail, cafe, restaurant)
  late String businessMode;

  /// Table ID (for restaurant mode)
  String? tableId;

  /// Table name (for restaurant mode, cached)
  String? tableName;

  /// Order number (for cafe mode)
  int? orderNumber;

  /// Customer ID (if linked to customer)
  String? customerId;

  /// Customer name (cached)
  String? customerName;

  /// Notes/memo for the transaction
  String? notes;

  /// Transaction items as JSON (line items array)
  /// Each item: {productId, productName, quantity, unitPrice, lineTotal, ...}
  late String itemsJson;

  /// Payment details as JSON (for multi-payment transactions)
  /// Array of {method, amount, reference}
  String? paymentsJson;

  /// Refund status (none, partial, full)
  String refundStatus = 'none'; // 'none', 'partial', 'full'

  /// Refund amount (if refunded)
  double refundAmount = 0.0;

  /// Refund reason
  String? refundReason;

  /// Sync status: true = synced to backend, false = needs sync
  bool isSynced = false;

  /// Timestamp of last sync
  int? lastSyncedAt;

  /// Timestamp of local creation
  late int createdAt;

  /// Timestamp of last local update
  late int updatedAt;

  /// Constructor with named parameters
  IsarTransaction({
    required this.backendId,
    required this.transactionNumber,
    required this.transactionDate,
    required this.userId,
    this.userName,
    required this.subtotal,
    this.taxAmount = 0.0,
    this.serviceChargeAmount = 0.0,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.discountReason,
    required this.paymentMethod,
    this.paymentReference,
    required this.businessMode,
    this.tableId,
    this.tableName,
    this.orderNumber,
    this.customerId,
    this.customerName,
    this.notes,
    required this.itemsJson,
    this.paymentsJson,
    this.refundStatus = 'none',
    this.refundAmount = 0.0,
    this.refundReason,
    this.isSynced = false,
    this.lastSyncedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    createdAt = now;
    updatedAt = now;
  }

  /// Create IsarTransaction from backend JSON
  factory IsarTransaction.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return IsarTransaction(
      backendId: json['\$id'] as String? ?? json['id'] as String? ?? '',
      transactionNumber: json['transactionNumber'] as String? ?? '',
      transactionDate: _parseTimestamp(json['transactionDate']),
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      serviceChargeAmount:
          (json['serviceChargeAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      discountReason: json['discountReason'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      paymentReference: json['paymentReference'] as String?,
      businessMode: json['businessMode'] as String? ?? 'retail',
      tableId: json['tableId'] as String?,
      tableName: json['tableName'] as String?,
      orderNumber: json['orderNumber'] as int?,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      notes: json['notes'] as String?,
      itemsJson: json['items'] != null
          ? (json['items'] is String
              ? json['items'] as String
              : _jsonEncode(json['items']))
          : '[]',
      paymentsJson: json['payments'] != null
          ? (json['payments'] is String
              ? json['payments'] as String
              : _jsonEncode(json['payments']))
          : null,
      refundStatus: json['refundStatus'] as String? ?? 'none',
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0.0,
      refundReason: json['refundReason'] as String?,
      isSynced: true,
      lastSyncedAt: now,
    )..createdAt = json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : now
     ..updatedAt = json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : now;
  }

  /// Convert IsarTransaction to JSON for backend sync
  Map<String, dynamic> toJson() {
    return {
      '\$id': backendId,
      'id': backendId,
      'transactionNumber': transactionNumber,
      'transactionDate': transactionDate,
      'userId': userId,
      'userName': userName,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'serviceChargeAmount': serviceChargeAmount,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'discountReason': discountReason,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'businessMode': businessMode,
      'tableId': tableId,
      'tableName': tableName,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'notes': notes,
      'items': _jsonDecode(itemsJson) ?? [],
      'payments': paymentsJson != null ? _jsonDecode(paymentsJson!) : null,
      'refundStatus': refundStatus,
      'refundAmount': refundAmount,
      'refundReason': refundReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Helper: JSON string encode
  static String _jsonEncode(dynamic value) {
    return value.toString();
  }

  /// Helper: JSON string decode
  static dynamic _jsonDecode(String json) {
    try {
      if (json.startsWith('[') || json.startsWith('{')) {
        return json;
      }
      return json;
    } catch (e) {
      return null;
    }
  }

  /// Helper: Parse timestamp from Appwrite/ISO format
  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) return timestamp;
    if (timestamp is String) {
      try {
        final dt = DateTime.parse(timestamp);
        return dt.millisecondsSinceEpoch;
      } catch (e) {
        return DateTime.now().millisecondsSinceEpoch;
      }
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
  String toString() =>
      'IsarTransaction(id: $id, backendId: $backendId, transactionNumber: $transactionNumber, totalAmount: $totalAmount, isSynced: $isSynced)';
}
