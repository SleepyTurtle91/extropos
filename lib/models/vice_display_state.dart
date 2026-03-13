/// Data model representing what should be shown on the customer-facing
/// vice display.
enum ViceDisplayMode { idle, cart, payment, change, thankYou, message }

class ViceDisplayState {
  final ViceDisplayMode mode;
  final String businessName;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double total;
  final String currencySymbol;
  final String qrData;
  final String? reference;
  final DateTime updatedAt;

  const ViceDisplayState({
    required this.mode,
    required this.businessName,
    required this.title,
    required this.subtitle,
    required this.cartItems,
    required this.subtotal,
    required this.total,
    required this.currencySymbol,
    required this.qrData,
    required this.reference,
    required this.updatedAt,
  });

  factory ViceDisplayState.idle({
    String businessName = 'ExtroPOS',
    String currencySymbol = 'RM',
  }) {
    return ViceDisplayState(
      mode: ViceDisplayMode.idle,
      businessName: businessName,
      title: 'Welcome',
      subtitle: 'Ready for your next order',
      cartItems: const [],
      subtotal: 0.0,
      total: 0.0,
      currencySymbol: currencySymbol,
      qrData: '',
      reference: null,
      updatedAt: DateTime.now(),
    );
  }

  bool get hasQr => qrData.isNotEmpty;
  bool get hasAmount => total > 0;

  ViceDisplayState copyWith({
    ViceDisplayMode? mode,
    String? businessName,
    String? title,
    String? subtitle,
    List<Map<String, dynamic>>? cartItems,
    double? subtotal,
    double? total,
    String? currencySymbol,
    String? qrData,
    String? reference,
    DateTime? updatedAt,
  }) {
    return ViceDisplayState(
      mode: mode ?? this.mode,
      businessName: businessName ?? this.businessName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      cartItems: cartItems ?? this.cartItems,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      qrData: qrData ?? this.qrData,
      reference: reference ?? this.reference,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
