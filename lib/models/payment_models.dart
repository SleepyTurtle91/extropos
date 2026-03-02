/// Payment-related Models
/// Payment methods, statuses, and split payment handling
enum PaymentMethodStatus { active, inactive }

class PaymentMethod {
  final String id;
  final String name;
  PaymentMethodStatus status;
  bool isDefault;
  DateTime? createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    this.status = PaymentMethodStatus.active,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get statusDisplayName {
    switch (status) {
      case PaymentMethodStatus.active:
        return 'Active';
      case PaymentMethodStatus.inactive:
        return 'Inactive';
    }
  }

  PaymentMethod copyWith({
    String? id,
    String? name,
    PaymentMethodStatus? status,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'isDefault': isDefault,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      status: PaymentMethodStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentMethodStatus.active,
      ),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Represents a single payment split in a transaction
class PaymentSplit {
  final PaymentMethod paymentMethod;
  final double amount;
  final String? reference; // Card number, transaction ID, etc.

  PaymentSplit({
    required this.paymentMethod,
    required this.amount,
    this.reference,
  });

  PaymentSplit copyWith({
    PaymentMethod? paymentMethod,
    double? amount,
    String? reference,
  }) {
    return PaymentSplit(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod.toJson(),
      'amount': amount,
      'reference': reference,
    };
  }

  factory PaymentSplit.fromJson(Map<String, dynamic> json) {
    return PaymentSplit(
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod']),
      amount: json['amount'] as double,
      reference: json['reference'] as String?,
    );
  }
}
