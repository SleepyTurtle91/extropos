/// E-Invoice Submission Model
/// Represents a submission record to LHDN MyInvois portal
class Submission {
  final String id;
  final String date;
  final String buyer;
  final double total;
  final String uin;
  final String status; // e.g., "Validated", "Rejected", "Pending"

  Submission({
    required this.id,
    required this.date,
    required this.buyer,
    required this.total,
    required this.uin,
    required this.status,
  });

  /// Official MyInvois API status values (must match these exactly)
  static const normalizedStatuses = ['Submitted', 'Valid', 'Invalid', 'Cancelled'];

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      // API returns 'submissionUID', fallback to 'id'
      id: json['submissionUID'] ?? json['id'] ?? '',
      // API returns 'dateTimeReceived', fallback to 'date'
      date: json['dateTimeReceived']?.toString() ?? json['date'] ?? '',
      // API returns 'buyerName', fallback to 'buyer'
      buyer: json['buyerName'] ?? json['buyer'] ?? 'Unknown',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      // Keep uin field for backward compatibility, use submissionUID
      uin: json['submissionUID'] ?? json['uin'] ?? '',
      // API status: Submitted, Valid, Invalid, Cancelled
      status: json['status'] ?? 'Submitted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submissionUID': id,
      'dateTimeReceived': date,
      'buyerName': buyer,
      'total': total,
      'status': status,
    };
  }
}
