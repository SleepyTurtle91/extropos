import 'dart:convert';

class Shift {
  final String id;
  final String userId;
  final int? businessSessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? variance; // Cash variance (closing - expected)
  final bool?
  varianceAcknowledged; // Whether variance was acknowledged by manager
  final String? notes;
  final String status; // 'active', 'completed'

  Shift({
    required this.id,
    required this.userId,
    this.businessSessionId,
    required this.startTime,
    this.endTime,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.variance,
    this.varianceAcknowledged,
    this.notes,
    this.status = 'active',
  });

  bool get isActive => status == 'active';

  Shift copyWith({
    String? id,
    String? userId,
    int? businessSessionId,
    DateTime? startTime,
    DateTime? endTime,
    double? openingCash,
    double? closingCash,
    double? expectedCash,
    double? variance,
    bool? varianceAcknowledged,
    String? notes,
    String? status,
  }) {
    return Shift(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessSessionId: businessSessionId ?? this.businessSessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      openingCash: openingCash ?? this.openingCash,
      closingCash: closingCash ?? this.closingCash,
      expectedCash: expectedCash ?? this.expectedCash,
      variance: variance ?? this.variance,
      varianceAcknowledged: varianceAcknowledged ?? this.varianceAcknowledged,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'business_session_id': businessSessionId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'expected_cash': expectedCash,
      'variance': variance,
      'variance_acknowledged': varianceAcknowledged == true ? 1 : 0,
      'notes': notes,
      'status': status,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      userId: map['user_id'],
      businessSessionId: map['business_session_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      openingCash: map['opening_cash']?.toDouble() ?? 0.0,
      closingCash: map['closing_cash']?.toDouble(),
      expectedCash: map['expected_cash']?.toDouble(),
      variance: map['variance']?.toDouble(),
      varianceAcknowledged: map['variance_acknowledged'] == 1,
      notes: map['notes'],
      status: map['status'] ?? 'active',
    );
  }

  String toJson() => json.encode(toMap());

  factory Shift.fromJson(String source) => Shift.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Shift(id: $id, userId: $userId, startTime: $startTime, status: $status)';
  }
}
