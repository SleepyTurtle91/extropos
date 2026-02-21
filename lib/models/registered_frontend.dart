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
