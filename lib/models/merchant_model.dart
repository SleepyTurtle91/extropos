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
