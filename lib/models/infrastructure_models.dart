/// Infrastructure Models
/// Multi-tenant, merchant, and frontend registration management
class Merchant {
  final String id;
  final String name;
  const Merchant({required this.id, required this.name});
}

/// Built-in merchant mapping for e-merchant IDs to friendly names
class MerchantHelper {
  static const Map<String, String> _displayNames = {
    'none': 'On-site',
    'takeaway': 'Takeaway',
    'grabfood': 'GrabFood',
    'shopeefood': 'ShopeeFood',
    'foodpanda': 'FoodPanda',
  };

  static String displayName(String? id) {
    if (id == null || id.isEmpty) return '';
    return _displayNames[id] ?? id;
  }
}

/// Registered Frontend (POS Counter) Model
/// Represents a POS terminal registered to this Backend
class RegisteredFrontend {
  final String licenseKey;
  final String
  counterName; // e.g., "Counter 1", "Main Branch", "Outlet Bangsar"
  final String? description; // Optional notes
  final DateTime registeredAt;
  final bool isActive; // Can disable without removing

  RegisteredFrontend({
    required this.licenseKey,
    required this.counterName,
    this.description,
    required this.registeredAt,
    this.isActive = true,
  });

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'licenseKey': licenseKey,
      'counterName': counterName,
      'description': description,
      'registeredAt': registeredAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory RegisteredFrontend.fromJson(Map<String, dynamic> json) {
    return RegisteredFrontend(
      licenseKey: json['licenseKey'],
      counterName: json['counterName'],
      description: json['description'],
      registeredAt: DateTime.parse(json['registeredAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  // Copy with method for updates
  RegisteredFrontend copyWith({
    String? licenseKey,
    String? counterName,
    String? description,
    DateTime? registeredAt,
    bool? isActive,
  }) {
    return RegisteredFrontend(
      licenseKey: licenseKey ?? this.licenseKey,
      counterName: counterName ?? this.counterName,
      description: description ?? this.description,
      registeredAt: registeredAt ?? this.registeredAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get license key masked for display (EXTRO-LIFE-****)
  String get maskedLicenseKey {
    if (licenseKey.length < 20) return licenseKey;
    return '${licenseKey.substring(0, 15)}****';
  }

  // Check if license is expired (for trial keys)
  bool get isExpired {
    // This would check expiry date from license key
    // For now, return false (implement based on your license logic)
    return false;
  }
}

/// Tenant Model
/// Represents a tenant (restaurant customer) with their database association
class Tenant {
  final String id; // Database ID (tenant_xxxxx)
  final String customerId; // Link to dealer_customers.id
  final String tenantName; // Business name
  final String ownerName;
  final String ownerEmail;
  final String? customDomain;
  final String? apiKey; // Tenant-specific API key
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tenant({
    required this.id,
    required this.customerId,
    required this.tenantName,
    required this.ownerName,
    required this.ownerEmail,
    this.customDomain,
    this.apiKey,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Copy with method for updates
  Tenant copyWith({
    String? id,
    String? customerId,
    String? tenantName,
    String? ownerName,
    String? ownerEmail,
    String? customDomain,
    String? apiKey,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      tenantName: tenantName ?? this.tenantName,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      customDomain: customDomain ?? this.customDomain,
      apiKey: apiKey ?? this.apiKey,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'tenant_name': tenantName,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'custom_domain': customDomain,
      'api_key': apiKey,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      tenantName: map['tenant_name'] as String,
      ownerName: map['owner_name'] as String,
      ownerEmail: map['owner_email'] as String,
      customDomain: map['custom_domain'] as String?,
      apiKey: map['api_key'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Tenant{id: $id, tenantName: $tenantName, ownerEmail: $ownerEmail}';
  }
}
