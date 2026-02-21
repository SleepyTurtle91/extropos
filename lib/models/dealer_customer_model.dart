class DealerCustomer {
  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String? registrationNumber;
  final String? taxNumber;
  final String? website;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DealerCustomer({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'Malaysia',
    this.registrationNumber,
    this.taxNumber,
    this.website,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Display name combining business and owner name
  String get displayName => '$businessName ($ownerName)';

  /// Formatted full address
  String get fullAddress {
    final parts = [address, city, '$postcode $state', country];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  /// Validate email format
  bool get isEmailValid {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Check if all required fields are filled
  bool get isValid {
    return businessName.isNotEmpty &&
        ownerName.isNotEmpty &&
        email.isNotEmpty &&
        isEmailValid &&
        phone.isNotEmpty &&
        address.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        postcode.isNotEmpty;
  }

  /// Copy with method for updates
  DealerCustomer copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? postcode,
    String? country,
    String? registrationNumber,
    String? taxNumber,
    String? website,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DealerCustomer(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      taxNumber: taxNumber ?? this.taxNumber,
      website: website ?? this.website,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_name': businessName,
      'owner_name': ownerName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'registration_number': registrationNumber,
      'tax_number': taxNumber,
      'website': website,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory DealerCustomer.fromMap(Map<String, dynamic> map) {
    return DealerCustomer(
      id: map['id'] as String,
      businessName: map['business_name'] as String,
      ownerName: map['owner_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      postcode: map['postcode'] as String,
      country: (map['country'] as String?) ?? 'Malaysia',
      registrationNumber: map['registration_number'] as String?,
      taxNumber: map['tax_number'] as String?,
      website: map['website'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'DealerCustomer{id: $id, businessName: $businessName, ownerName: $ownerName, email: $email}';
  }
}
