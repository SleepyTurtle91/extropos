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
