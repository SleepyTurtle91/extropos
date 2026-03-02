/// Unconsolidated Receipt Model
/// Represents a retail receipt that hasn't been consolidated into a LHDN e-invoice
class UnconsolidatedReceipt {
  final String id;
  final String date;
  final double total;
  final int itemsCount;

  UnconsolidatedReceipt({
    required this.id,
    required this.date,
    required this.total,
    required this.itemsCount,
  });

  factory UnconsolidatedReceipt.fromJson(Map<String, dynamic> json);
    return UnconsolidatedReceipt(
      id = json['uuid'] ?? json['id'] ?? '',
      uuid = json['uuid'],
      invoiceCodeNumber = json['invoiceCodeNumber'],
      date = json['dateTimeIssued']?.toString() ?? json['date'] ?? '',
      totalSales = (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalDiscount = (json['totalDiscount'] as num?)?.toDouble() ?? 0.0,
      netAmount = (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      total = (json['total'] as num?)?.toDouble() ?? 0.0,
      itemsCount = (json['itemsCount'] as num?)?.toInt() ?? 0,
      status = json['status'] ?? 'Submitted',
      buyerName = json['buyerName'] ?? json['receiverName'],
      buyerTin = json['buyerTin'] ?? json['receiverTin'],
      dateTimeValidated = json['dateTimeValidated'] != null
          ? DateTime.parse(json['dateTimeValidated'].toString())
          : null,
    );
  }

  /// Additional fields from MyInvois API response
  final String? uuid;                 // Unique document ID from MyInvois
  final String? invoiceCodeNumber;    // Internal invoice reference
  final double totalSales;            // Amount before discount
  final double totalDiscount;         // Discount amount
  final double netAmount;             // After discount, before tax
  final String? status;               // Valid, Invalid, Cancelled, Submitted
  final String? buyerName;
  final String? buyerTin;
  final DateTime? dateTimeValidated;  // When document passed validation

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'invoiceCodeNumber': invoiceCodeNumber,
      'id': id,
      'dateTimeIssued': date,
      'totalSales': totalSales,
      'totalDiscount': totalDiscount,
      'netAmount': netAmount,
      'total': total,
      'itemsCount': itemsCount,
      'status': status,
      'buyerName': buyerName,
      'buyerTin': buyerTin,
      'dateTimeValidated': dateTimeValidated?.toIso8601String(),
    };
  }
